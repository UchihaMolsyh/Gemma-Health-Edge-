import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure storage service for encrypting sensitive data like API keys.
/// Uses AES-256-GCM encryption for strong security.
class SecureStorageService {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _apiKeyPrefix = 'secure_api_key_';
  static const String _masterKeyName = '_master_encryption_key_';

  /// Master encryption key (lazy-loaded)
  encrypt.Key? _masterKey;

  /// Get or create the master encryption key
  Future<encrypt.Key> _getMasterKey() async {
    if (_masterKey != null) return _masterKey!;

    // Try to load existing key
    final existingKey = await _secureStorage.read(key: _masterKeyName);
    if (existingKey != null) {
      _masterKey = encrypt.Key(base64Decode(existingKey));
      return _masterKey!;
    }

    // Generate new key if none exists using cryptographically secure random
    final secureRandom = encrypt.SecureRandom(32); // 256 bits
    final keyBytes = secureRandom.bytes;
    _masterKey = encrypt.Key(keyBytes);

    // Store the key securely
    await _secureStorage.write(
      key: _masterKeyName,
      value: base64Encode(keyBytes),
    );

    return _masterKey!;
  }

  /// Encrypt and store an API key securely using AES-256-GCM.
  Future<void> storeApiKey(String keyName, String apiKey) async {
    final masterKey = await _getMasterKey();
    final iv = encrypt.IV.fromSecureRandom(12); // 96 bits for GCM

    final encrypter = encrypt.Encrypter(
      encrypt.AES(masterKey, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypter.encrypt(apiKey, iv: iv);

    // Store as JSON with IV + ciphertext
    final payload = jsonEncode({
      'iv': base64Encode(iv.bytes),
      'data': encrypted.base64,
    });

    await _secureStorage.write(
      key: '$_apiKeyPrefix$keyName',
      value: payload,
    );
  }

  /// Retrieve and decrypt an API key using AES-256-GCM.
  Future<String?> getApiKey(String keyName) async {
    final payload = await _secureStorage.read(key: '$_apiKeyPrefix$keyName');
    if (payload == null) return null;

    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final iv = encrypt.IV(base64Decode(json['iv'] as String));
      final encryptedData = json['data'] as String;

      final masterKey = await _getMasterKey();
      final encrypter = encrypt.Encrypter(
        encrypt.AES(masterKey, mode: encrypt.AESMode.gcm),
      );

      final decrypted = encrypter.decrypt64(encryptedData, iv: iv);
      return decrypted;
    } catch (e) {
      // If decryption fails, delete the corrupted key and log the error
      debugPrint('[SecureStorage] Failed to decrypt API key $keyName: $e');
      await deleteApiKey(keyName);
      return null;
    }
  }

  /// Delete an API key from secure storage.
  Future<void> deleteApiKey(String keyName) async {
    await _secureStorage.delete(key: '$_apiKeyPrefix$keyName');
  }

  /// Clear all stored API keys.
  Future<void> clearAllApiKeys() async {
    final allKeys = await _secureStorage.readAll();
    for (final key in allKeys.keys) {
      if (key.startsWith(_apiKeyPrefix)) {
        await _secureStorage.delete(key: key);
      }
    }
  }

  /// Hash a value for comparison (e.g., for verifying passwords without storing them).
  String hashValue(String value) {
    final bytes = utf8.encode(value);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}
