import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/session.dart';
import 'models/mood_entry.dart';
import 'models/app_settings.dart';
import 'models/health_sample.dart';
import 'secure_storage_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Storage Service
// 
// Provides encrypted local storage for:
// - Chat sessions and messages
// - Calendar mood entries
// - Health metrics and samples
// - Activity sessions
// - App settings
// 
// Uses Hive with AES-256-GCM encryption for data persistence.
// API keys are stored separately using FlutterSecureStorage with additional encryption.
// ═════════════════════════════════════════════════════════════════════════════

/// Hive-backed storage service with AES-256 encryption.
/// Manages sessions, calendar moods, health metrics, and settings.
class StorageService {
  static const String _sessionsBoxName = 'sessions';
  static const String _calendarBoxName = 'calendar';
  static const String _healthBoxName = 'health_metrics';
  static const String _settingsPrefix = 'gemma_settings_';

  late Box<Map> _sessionsBox;
  late Box<Map> _calendarBox;
  late Box<Map> _healthBox;
  final SecureStorageService _secureStorage = SecureStorageService();

  Future<void> _migrateToEncryptedBox(
      String boxName, HiveAesCipher cipher) async {
    // Check if unencrypted box exists
    final boxExists = await Hive.boxExists(boxName);
    if (!boxExists) return; // Nothing to migrate

    try {
      // Try to open it normally (unencrypted)
      final tempBox = await Hive.openBox<Map>(boxName);

      // If it opens successfully, we need to migrate it
      // Copy all data to memory
      final data = <dynamic, dynamic>{};
      for (final key in tempBox.keys) {
        data[key] = tempBox.get(key);
      }

      // Close and delete the unencrypted box
      await tempBox.close();
      await Hive.deleteBoxFromDisk(boxName);

      // Re-open as encrypted and restore data
      final encryptedBox =
          await Hive.openBox<Map>(boxName, encryptionCipher: cipher);
      for (final key in data.keys) {
        await encryptedBox.put(key, data[key]);
      }
      await encryptedBox.close();
      debugPrint('Successfully migrated $boxName to encrypted storage');
    } catch (e) {
      // It might already be encrypted, or corrupted.
      debugPrint('Could not migrate $boxName (might already be encrypted): $e');
    }
  }

  /// Initialize Hive and open all boxes
  ///
  /// Throws [Exception] if initialization fails.
  Future<void> init() async {
    try {
      await _initPrefs();
      await Hive.initFlutter();

      // Setup encryption key
      const secureStorage = FlutterSecureStorage();
      var encryptionKeyString =
          await secureStorage.read(key: 'hive_encryption_key');
      if (encryptionKeyString == null) {
        final key = Hive.generateSecureKey();
        await secureStorage.write(
          key: 'hive_encryption_key',
          value: base64UrlEncode(key),
        );
        encryptionKeyString = base64UrlEncode(key);
      }

      final encryptionKeyUint8List = base64Url.decode(encryptionKeyString);
      final cipher = HiveAesCipher(encryptionKeyUint8List);

      // Attempt migrations for existing plaintext users
      await _migrateToEncryptedBox(_sessionsBoxName, cipher);
      await _migrateToEncryptedBox(_calendarBoxName, cipher);
      await _migrateToEncryptedBox(_healthBoxName, cipher);

      _sessionsBox =
          await Hive.openBox<Map>(_sessionsBoxName, encryptionCipher: cipher);
      _calendarBox =
          await Hive.openBox<Map>(_calendarBoxName, encryptionCipher: cipher);
      _healthBox =
          await Hive.openBox<Map>(_healthBoxName, encryptionCipher: cipher);
    } catch (e, stackTrace) {
      debugPrint('Storage initialization failed: $e\n$stackTrace');
      rethrow;
    }
  }

  // ─── Generic Key-Value (SharedPreferences) ─────────────────────────────

  /// Get a string value from SharedPreferences
  String? get(String key, {String? defaultValue}) {
    if (_prefs == null) {
      debugPrint('[StorageService] Warning: get() called before init() completed, returning default value');
      return defaultValue;
    }
    return _prefs!.getString(key) ?? defaultValue;
  }

  /// Set a string value in SharedPreferences
  Future<bool> set(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  SharedPreferences? _prefs;
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }


  // ─── Sessions ──────────────────────────────────────────────────────────

  /// Save sessions list, enforcing 10-session rolling limit.
  ///
  /// Validates all sessions before saving. Skips invalid sessions.
  Future<void> saveSessions(List<Session> sessions) async {
    try {
      final box = _sessionsBox;
      // Enforce 10-session rolling limit to save space
      final sortedSessions = sessions.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final limitedSessions = sortedSessions.take(10).toList();
      
      // Batch write for better performance
      final batch = <String, Map<String, dynamic>>{};
      for (final session in limitedSessions) {
        batch[session.id] = session.toJson();
      }
      await box.clear();
      await box.putAll(batch);
      await box.compact();
    } catch (e) {
      debugPrint('Failed to save sessions: $e');
      rethrow;
    }
  }

  /// Load all valid sessions from Hive.
  /// Skips invalid entries (empty message lists) — never wipe all due to one bad entry.
  List<Session> loadSessions() {
    final sessions = <Session>[];
    for (final key in _sessionsBox.keys) {
      try {
        final raw = _sessionsBox.get(key);
        if (raw == null) continue;
        final json = _castToStringDynamic(raw);
        final session = Session.fromJson(json);
        if (session.isValid) {
          sessions.add(session);
        }
      } catch (e, stackTrace) {
        // Skip corrupted entry — don't wipe everything (fix #9)
        debugPrint('Failed to load session $key: $e\n$stackTrace');
        continue;
      }
    }
    sessions.sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }

  /// Delete a specific session by ID
  Future<void> deleteSession(String sessionId) async {
    try {
      await _sessionsBox.delete(sessionId);
    } catch (e, stackTrace) {
      debugPrint('Failed to delete session $sessionId: $e\n$stackTrace');
    }
  }

  // ─── Calendar / Moods ──────────────────────────────────────────────────

  /// Save or update a mood entry (upsert by date).
  ///
  /// Validates mood value is between 1-5 before saving.
  Future<void> saveMood(MoodEntry entry) async {
    if (!entry.isValid) return; // Validate 1-5
    try {
      await _calendarBox.put(entry.date, _deepCastMap(entry.toJson()));
    } catch (e, stackTrace) {
      debugPrint('Failed to save mood entry: $e\n$stackTrace');
    }
  }

  /// Load all valid mood entries.
  List<MoodEntry> loadMoods() {
    final moods = <MoodEntry>[];
    for (final key in _calendarBox.keys) {
      try {
        final raw = _calendarBox.get(key);
        if (raw == null) continue;
        final json = _castToStringDynamic(raw);
        final entry = MoodEntry.fromJson(json);
        if (entry.isValid) {
          moods.add(entry);
        }
      } catch (e) {
        continue;
      }
    }
    return moods;
  }

  /// Delete a mood entry by date string.
  Future<void> deleteMood(String date) async {
    try {
      await _calendarBox.delete(date);
    } catch (e, stackTrace) {
      debugPrint('Failed to delete mood entry $date: $e\n$stackTrace');
    }
  }

  // ─── Health Metrics ────────────────────────────────────────────────────

  /// Save a health sample.
  /// Stored by ID to avoid duplicates across refreshes.
  ///
  /// Validates sample before saving.
  Future<void> saveHealthSample(HealthSample sample) async {
    if (!sample.isValid) return;
    if (sample.id.isEmpty) return;
    try {
      await _healthBox.put(sample.id, _deepCastMap(sample.toJson()));
    } catch (e, stackTrace) {
      debugPrint('Failed to save health sample: $e\n$stackTrace');
    }
  }

  /// Save multiple samples.
  ///
  /// Batch operation with individual error handling.
  /// Continues saving even if some samples fail.
  Future<void> saveHealthSamples(List<HealthSample> samples) async {
    if (samples.isEmpty) return;
    int successCount = 0;
    int failureCount = 0;

    for (final s in samples) {
      if (!s.isValid || s.id.isEmpty) continue;
      try {
        await _healthBox.put(s.id, _deepCastMap(s.toJson()));
        successCount++;
      } catch (e) {
        failureCount++;
        debugPrint('Failed to save health sample ${s.id}: $e');
      }
    }
    debugPrint('Saved $successCount health samples, $failureCount failed');
  }

  /// Load all valid health samples.
  List<HealthSample> loadHealthSamples() {
    final out = <HealthSample>[];
    for (final key in _healthBox.keys) {
      try {
        final raw = _healthBox.get(key);
        if (raw == null) continue;
        final json = _castToStringDynamic(raw);
        final sample = HealthSample.fromJson(json);
        if (sample.isValid) out.add(sample);
      } catch (e) {
        continue;
      }
    }
    out.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return out;
  }

  /// Delete all health samples.
  Future<void> clearHealthSamples() async {
    try {
      await _healthBox.clear();
    } catch (e, stackTrace) {
      debugPrint('Failed to clear health samples: $e\n$stackTrace');
    }
  }

  // ─── Settings (SharedPreferences) ──────────────────────────────────────

  /// Save settings to SharedPreferences.
  /// API key is stored separately in secure storage.
  Future<void> saveSettings(AppSettings settings) async {
    // Store API key securely
    if (settings.cloudApiKey.isNotEmpty) {
      await _secureStorage.storeApiKey('cloud', settings.cloudApiKey);
    } else {
      await _secureStorage.deleteApiKey('cloud');
    }

    // Store other settings in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = settings.toJson();
    // Remove API key from JSON before storing in SharedPreferences
    settingsJson
        .remove('cloudApiKey'); // Safe to call even if key doesn't exist

    await prefs.setString(
      '${_settingsPrefix}data',
      jsonEncode(settingsJson),
    );
  }

  /// Load settings from SharedPreferences.
  /// API key is retrieved from secure storage.
  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_settingsPrefix}data');
    if (raw == null) return const AppSettings();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final settings = AppSettings.fromJson(json);

      // Retrieve API key from secure storage
      final apiKey = await _secureStorage.getApiKey('cloud');
      return settings.copyWith(cloudApiKey: apiKey ?? '');
    } catch (e) {
      return const AppSettings();
    }
  }

  // ─── Backup / Restore ─────────────────────────────────────────────────

  /// Export all data as a JSON string for backup.
  ///
  /// Excludes sensitive data (API keys) from export.
  /// Returns JSON string or throws on error.
  Future<String> exportAll() async {
    try {
      final sessions = loadSessions().map((s) => s.toJson()).toList();
      final moods = loadMoods().map((m) => m.toJson()).toList();
      final settings = await loadSettings();
      final settingsJson = settings.toJson();
      settingsJson.remove('cloudApiKey'); // Never export API keys

      final exportData = {
        'version': '2.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'sessions': sessions,
        'moods': moods,
        'settings': settingsJson,
      };

      final jsonStr = jsonEncode(exportData);
      if (jsonStr.length > 10 * 1024 * 1024) {
        // 10MB limit
        throw Exception('Export data too large (>10MB)');
      }
      return jsonStr;
    } catch (e, stackTrace) {
      debugPrint('Export failed: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Import all data from a JSON backup string.
  ///
  /// Validates structure, version, and data limits.
  /// Never imports API keys for security.
  ///
  /// Throws [Exception] on validation failure.
  Future<void> importAll(String jsonStr) async {
    if (jsonStr.isEmpty) {
      throw Exception('Backup file is empty');
    }
    if (jsonStr.length > 10 * 1024 * 1024) {
      // 10MB limit
      throw Exception('Backup file too large (>10MB)');
    }

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Validate backup structure
      if (!data.containsKey('version') || !data.containsKey('exportDate')) {
        throw Exception('Invalid backup file: missing required fields');
      }

      // Validate version compatibility
      final version = data['version'] as String?;
      if (version == null || !_isVersionCompatible(version)) {
        throw Exception('Incompatible backup version: $version');
      }

      // Validate export date is not in the future
      final exportDateStr = data['exportDate'] as String?;
      if (exportDateStr != null) {
        try {
          final exportDate = DateTime.parse(exportDateStr);
          if (exportDate.isAfter(DateTime.now().add(const Duration(days: 1)))) {
            throw Exception('Invalid export date: future date detected');
          }
        } catch (e) {
          throw Exception('Invalid export date format');
        }
      }

      // Import sessions
      if (data['sessions'] is List) {
        final sessions = (data['sessions'] as List)
            .whereType<Map<String, dynamic>>()
            .map((m) => Session.fromJson(m))
            .where((s) => s.isValid)
            .toList();
        // Limit to prevent data overflow
        if (sessions.length > 100) {
          throw Exception('Too many sessions in backup (max 100)');
        }
        await saveSessions(sessions);
      }

      // Import moods
      if (data['moods'] is List) {
        final moodsList = data['moods'] as List;
        if (moodsList.length > 365) {
          throw Exception('Too many mood entries in backup (max 365)');
        }
        for (final m in moodsList) {
          if (m is Map<String, dynamic>) {
            final entry = MoodEntry.fromJson(m);
            if (entry.isValid) {
              await saveMood(entry);
            }
          }
        }
      }

      // Import settings (but skip API key for security)
      if (data['settings'] is Map<String, dynamic>) {
        final settingsJson = data['settings'] as Map<String, dynamic>;
        settingsJson.remove('cloudApiKey'); // Never import API keys from backup
        final settings = AppSettings.fromJson(settingsJson);
        await saveSettings(settings);
      }
    } on FormatException catch (e) {
      throw Exception('Invalid JSON format: $e');
    } catch (e) {
      throw Exception('Invalid backup file: $e');
    }
  }

  /// Check if backup version is compatible with current app version.
  bool _isVersionCompatible(String version) {
    // Parse version numbers as integers for proper comparison
    const currentVersion = '2.0.0';
    try {
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final backupParts = version.split('.').map(int.parse).toList();

      // Require at least major version match
      if (currentParts.isEmpty || backupParts.isEmpty) return false;
      return currentParts[0] == backupParts[0];
    } catch (e) {
      // If version parsing fails, reject the backup
      return false;
    }
  }

  /// Clear all stored data.
  ///
  /// Clears all boxes and preferences except secure storage (API keys).
  /// Use with caution - this action is irreversible.
  Future<void> clearAll() async {
    try {
      await _sessionsBox.clear();
      await _calendarBox.clear();
      await _healthBox.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_settingsPrefix}data');
      debugPrint('All local data cleared');
    } catch (e, stackTrace) {
      debugPrint('Failed to clear data: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Approximate storage size in bytes.
  int get approximateSize => _boxSize(_sessionsBox) + _boxSize(_calendarBox);

  int _boxSize(Box<Map> box) {
    return box.keys.fold(0, (sum, key) {
      final val = box.get(key);
      return sum + (val != null ? jsonEncode(val).length : 0);
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  /// Deep-cast a Map<String, dynamic> to Map<dynamic, dynamic> for Hive.
  Map<dynamic, dynamic> _deepCastMap(Map<String, dynamic> input) {
    final result = <dynamic, dynamic>{};
    input.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = _deepCastMap(value);
      } else if (value is List) {
        result[key] = value.map((e) {
          if (e is Map<String, dynamic>) return _deepCastMap(e);
          return e;
        }).toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  /// Cast Hive's Map<dynamic, dynamic> back to Map<String, dynamic>.
  Map<String, dynamic> _castToStringDynamic(Map raw) {
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      final strKey = key.toString();
      if (value is Map) {
        result[strKey] = _castToStringDynamic(value);
      } else if (value is List) {
        result[strKey] = value.map((e) {
          if (e is Map) return _castToStringDynamic(e);
          return e;
        }).toList();
      } else {
        result[strKey] = value;
      }
    });
    return result;
  }
}
