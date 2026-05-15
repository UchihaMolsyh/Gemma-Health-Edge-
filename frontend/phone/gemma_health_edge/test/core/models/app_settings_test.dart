import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_health_edge/core/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('default values', () {
      const s = AppSettings();
      expect(s.serverUrl, AppSettings.defaultServerUrl);
      expect(s.theme, AppSettings.defaultTheme);
      expect(s.accentColor, AppSettings.defaultAccentColor);
      expect(s.language, AppSettings.defaultLanguage);
      expect(s.showThinking, AppSettings.defaultShowThinking);
      expect(s.useCloudApi, AppSettings.defaultUseCloudApi);
    });

    test('toJson/fromJson roundtrip', () {
      const s = AppSettings(
        serverUrl: 'http://example.com',
        theme: 'light',
        accentColor: 0xFF112233,
        language: 'fr',
        showThinking: false,
        enableVoice: true,
        enableResearch: false,
        disclaimerAccepted: true,
        maxHistoryTurns: 5,
        useCloudApi: true,
        cloudApiKey: 'key',
        cloudModelId: 'model',
      );

      final json = s.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.serverUrl, equals(s.serverUrl));
      expect(restored.theme, equals(s.theme));
      expect(restored.accentColor, equals(s.accentColor));
      expect(restored.language, equals(s.language));
      expect(restored.showThinking, equals(s.showThinking));
      expect(restored.enableVoice, equals(s.enableVoice));
      expect(restored.enableResearch, equals(s.enableResearch));
      expect(restored.disclaimerAccepted, equals(s.disclaimerAccepted));
      expect(restored.maxHistoryTurns, equals(s.maxHistoryTurns));
      expect(restored.useCloudApi, equals(s.useCloudApi));
      expect(restored.cloudApiKey, equals(s.cloudApiKey));
      expect(restored.cloudModelId, equals(s.cloudModelId));
    });

    test('copyWith', () {
      const s = AppSettings();
      final updated = s.copyWith(language: 'fr', theme: 'light');
      expect(updated.language, 'fr');
      expect(updated.theme, 'light');
    });
  });
}
