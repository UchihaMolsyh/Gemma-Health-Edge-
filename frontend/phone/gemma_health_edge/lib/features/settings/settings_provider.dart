import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_settings.dart';
import '../../core/storage_service.dart';
import '../../core/api_client.dart';
import '../chat/chat_provider.dart';

// ─── Settings State ─────────────────────────────────────────────────────────

class SettingsState {
  final AppSettings settings;
  final bool isLoading;

  const SettingsState({
    this.settings = const AppSettings(),
    this.isLoading = false,
  });

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Settings Notifier ──────────────────────────────────────────────────────

class SettingsNotifier extends Notifier<SettingsState> {
  late final StorageService _storage;

  @override
  SettingsState build() {
    _storage = ref.read(storageServiceProvider);
    // Defer settings loading to avoid state updates during build phase
    Future.microtask(() => _loadSettings());
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    final settings = await _storage.loadSettings();
    state = state.copyWith(settings: settings, isLoading: false);
    // Defer sync to avoid circular dependency during initialization
    Future.microtask(() => _syncToChat());
  }

  void _syncToChat() {
    // Check if chatProvider is initialized before accessing
    try {
      ref.read(chatProvider.notifier).updateSettings(state.settings);
    } catch (e) {
      // Chat provider not ready yet - will sync on next settings change
      debugPrint('Settings sync deferred: chatProvider not ready');
    }
  }

  Future<void> updateServerUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    // Validate URL format
    if (!UrlValidator.isValidServerUrl(trimmed)) {
      throw ArgumentError(
          'Invalid server URL format. Must be a valid HTTP/HTTPS URL.');
    }

    final newSettings = state.settings.copyWith(serverUrl: trimmed);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    _syncToChat();
  }

  Future<void> updateTheme(String theme) async {
    final newSettings = state.settings.copyWith(theme: theme);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
  }

  Future<void> updateAccentColor(int color) async {
    final newSettings = state.settings.copyWith(accentColor: color);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
  }

  Future<void> updateLanguage(String language) async {
    final newSettings = state.settings.copyWith(language: language);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    _syncToChat();
  }

  Future<void> updateShowThinking(bool value) async {
    final newSettings = state.settings.copyWith(showThinking: value);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    _syncToChat();
  }

  Future<void> updateEnableVoice(bool value) async {
    final newSettings = state.settings.copyWith(enableVoice: value);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
  }

  Future<void> updateEnableResearch(bool value) async {
    final newSettings = state.settings.copyWith(enableResearch: value);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    _syncToChat();
  }

  Future<void> updateEnableServerCritic(bool value) async {
    final newSettings = state.settings.copyWith(enableServerCritic: value);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    _syncToChat();
  }

  Future<void> updateUseCloudApi(bool value) async {
    final newSettings = state.settings.copyWith(useCloudApi: value);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    _syncToChat();
  }

  Future<void> updateUseOllama(bool value) async {
    final newSettings = state.settings.copyWith(useOllama: value);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    _syncToChat();
  }

  Future<void> updateUseSubBackendE2B(bool value) async {
    final newSettings = state.settings.copyWith(useSubBackendE2B: value);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    _syncToChat();
  }

  Future<void> updateUseLocalOnDeviceAi(bool value) async {
    final newSettings = state.settings.copyWith(useLocalOnDeviceAi: value);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    _syncToChat();
  }

  Future<void> updateLocalAiType(String type) async {
    final newSettings = state.settings.copyWith(localAiType: type);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    _syncToChat();
  }

  Future<void> updateCloudApiKey(String key) async {
    final trimmed = key.trim();
    // Allow empty string to clear the API key
    final newSettings = state.settings.copyWith(cloudApiKey: trimmed);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    _syncToChat();
  }

  Future<void> updateCloudModelId(String modelId) async {
    final trimmed = modelId.trim();
    if (trimmed.isEmpty) return;

    final newSettings = state.settings.copyWith(cloudModelId: trimmed);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    _syncToChat();
  }

  Future<void> acceptDisclaimer() async {
    final newSettings = state.settings.copyWith(disclaimerAccepted: true);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
  }

  Future<void> resetColors() async {
    final newSettings = state.settings.copyWith(
      accentColor: AppSettings.defaultAccentColor,
    );
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
  }

  // ─── Clinical Profile Methods ────────────────────────────────────────────

  Future<void> updateAllergies(String value) async {
    final newSettings = state.settings.copyWith(allergies: value.trim());
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    await _syncClinicalProfileToBackend(newSettings);
  }

  Future<void> updateConditions(String value) async {
    final newSettings = state.settings.copyWith(conditions: value.trim());
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    await _syncClinicalProfileToBackend(newSettings);
  }

  Future<void> updateMedications(String value) async {
    final newSettings = state.settings.copyWith(medications: value.trim());
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    await _syncClinicalProfileToBackend(newSettings);
  }

  Future<void> updateAge(int? value) async {
    final newSettings = state.settings.copyWith(age: value);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    await _syncClinicalProfileToBackend(newSettings);
  }

  Future<void> updateWeight(double? value) async {
    final newSettings = state.settings.copyWith(weight: value);
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    await _syncClinicalProfileToBackend(newSettings);
  }

  Future<void> updateClinicalNotes(String value) async {
    final newSettings = state.settings.copyWith(clinicalNotes: value.trim());
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    
    // Sync to backend if connected
    _syncClinicalProfileToBackend(newSettings);
  }

  Future<void> _syncClinicalProfileToBackend(AppSettings settings) async {
    try {
      final apiClient = ApiClient(serverUrl: settings.serverUrl);
      final profile = {
        'allergies': settings.allergies,
        'conditions': settings.conditions,
        'medications': settings.medications,
        'age': settings.age?.toString() ?? '',
        'weight': settings.weight?.toString() ?? '',
        'notes': settings.clinicalNotes,
      };
      await apiClient.saveClinicalProfile(profile);
    } catch (e) {
      debugPrint('[Settings] Failed to sync clinical profile to backend: $e');
    }
  }

  Future<void> clearAllData() async {
    await _storage.clearAll();
    state = state.copyWith(settings: const AppSettings());
    ref.read(chatProvider.notifier).clearChat();
  }

  Future<String> exportData() async {
    return await _storage.exportAll();
  }

  Future<void> importData(String json) async {
    await _storage.importAll(json);
    await _loadSettings();
    ref.read(chatProvider.notifier).newSession();
  }

  int get storageSize => _storage.approximateSize;
}

// ─── Provider ───────────────────────────────────────────────────────────────

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
