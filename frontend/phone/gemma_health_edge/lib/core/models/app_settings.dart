/// App settings stored in Hive / SharedPreferences.
class AppSettings {
  final String serverUrl;
  final String theme; // 'dark' | 'light' | 'system'
  final int accentColor; // ARGB int
  final String language; // 'en'|'fr'|'de'|'es'|'zh'|'hi'|'ru'
  final bool showThinking;
  final bool enableVoice;
  final bool enableResearch;
  final bool enableServerCritic;
  final bool disclaimerAccepted;
  final int maxHistoryTurns;

  final bool useCloudApi;
  final String cloudApiKey;
  final String cloudModelId;
  final bool useOllama;
  final bool useSubBackendE2B;
  final bool useLocalOnDeviceAi;
  final String localAiType; // 'litert' | 'llama_cpp'

  // Clinical Profile
  final String allergies;
  final String conditions;
  final String medications;
  final int? age;
  final double? weight;
  final String clinicalNotes;

  static const String defaultServerUrl = 'http://127.0.0.1:8000';
  static const String defaultTheme = 'dark';
  static const int defaultAccentColor = 0xFF3B82F6;
  static const String defaultLanguage = 'en';
  static const bool defaultShowThinking = true;
  static const bool defaultEnableVoice = false;
  static const bool defaultEnableResearch = true;
  static const bool defaultEnableServerCritic = false;
  static const bool defaultDisclaimerAccepted = false;
  static const int defaultMaxHistoryTurns = 10;
  static const bool defaultUseCloudApi = false;
  static const String defaultCloudApiKey = '';
  static const String defaultCloudModelId = 'google/gemma-4-27b-it';
  static const bool defaultUseOllama = false;
  static const bool defaultUseSubBackendE2B = false;
  static const bool defaultUseLocalOnDeviceAi = false;
  static const String defaultLocalAiType = 'llama_cpp';

  static const String defaultAllergies = '';
  static const String defaultConditions = '';
  static const String defaultMedications = '';
  static const String defaultClinicalNotes = '';

  static const List<String> supportedLanguages = [
    'en',
    'fr',
    'de',
    'es',
    'zh',
    'hi',
    'ru',
    'ja',
    'ko',
    'mn'
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'zh': '中文',
    'hi': 'हिन्दी',
    'ru': 'Русский',
    'ja': '日本語',
    'ko': '한국어',
    'mn': 'Монгол',
  };

  const AppSettings({
    this.serverUrl = defaultServerUrl,
    this.theme = defaultTheme,
    this.accentColor = defaultAccentColor,
    this.language = defaultLanguage,
    this.showThinking = defaultShowThinking,
    this.enableVoice = defaultEnableVoice,
    this.enableResearch = defaultEnableResearch,
    this.enableServerCritic = defaultEnableServerCritic,
    this.disclaimerAccepted = defaultDisclaimerAccepted,
    this.maxHistoryTurns = defaultMaxHistoryTurns,
    this.useCloudApi = defaultUseCloudApi,
    this.cloudApiKey = defaultCloudApiKey,
    this.cloudModelId = defaultCloudModelId,
    this.useOllama = defaultUseOllama,
    this.useSubBackendE2B = defaultUseSubBackendE2B,
    this.useLocalOnDeviceAi = defaultUseLocalOnDeviceAi,
    this.localAiType = defaultLocalAiType,
    this.allergies = defaultAllergies,
    this.conditions = defaultConditions,
    this.medications = defaultMedications,
    this.age,
    this.weight,
    this.clinicalNotes = defaultClinicalNotes,
  });

  AppSettings copyWith({
    String? serverUrl,
    String? theme,
    int? accentColor,
    String? language,
    bool? showThinking,
    bool? enableVoice,
    bool? enableResearch,
    bool? enableServerCritic,
    bool? disclaimerAccepted,
    int? maxHistoryTurns,
    bool? useCloudApi,
    String? cloudApiKey,
    String? cloudModelId,
    bool? useOllama,
    bool? useSubBackendE2B,
    bool? useLocalOnDeviceAi,
    String? localAiType,
    String? allergies,
    String? conditions,
    String? medications,
    int? age,
    double? weight,
    String? clinicalNotes,
  }) {
    return AppSettings(
      serverUrl: serverUrl ?? this.serverUrl,
      theme: theme ?? this.theme,
      accentColor: accentColor ?? this.accentColor,
      language: language ?? this.language,
      showThinking: showThinking ?? this.showThinking,
      enableVoice: enableVoice ?? this.enableVoice,
      enableResearch: enableResearch ?? this.enableResearch,
      enableServerCritic: enableServerCritic ?? this.enableServerCritic,
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
      maxHistoryTurns: maxHistoryTurns ?? this.maxHistoryTurns,
      useCloudApi: useCloudApi ?? this.useCloudApi,
      cloudApiKey: cloudApiKey ?? this.cloudApiKey,
      cloudModelId: cloudModelId ?? this.cloudModelId,
      useOllama: useOllama ?? this.useOllama,
      useSubBackendE2B: useSubBackendE2B ?? this.useSubBackendE2B,
      useLocalOnDeviceAi: useLocalOnDeviceAi ?? this.useLocalOnDeviceAi,
      localAiType: localAiType ?? this.localAiType,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      medications: medications ?? this.medications,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'theme': theme,
      'accentColor': accentColor,
      'language': language,
      'showThinking': showThinking,
      'enableVoice': enableVoice,
      'enableResearch': enableResearch,
      'enableServerCritic': enableServerCritic,
      'disclaimerAccepted': disclaimerAccepted,
      'maxHistoryTurns': maxHistoryTurns,
      'useCloudApi': useCloudApi,
      'cloudApiKey': cloudApiKey,
      'cloudModelId': cloudModelId,
      'useOllama': useOllama,
      'useSubBackendE2B': useSubBackendE2B,
      'useLocalOnDeviceAi': useLocalOnDeviceAi,
      'localAiType': localAiType,
      'allergies': allergies,
      'conditions': conditions,
      'medications': medications,
      'age': age,
      'weight': weight,
      'clinicalNotes': clinicalNotes,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      serverUrl: json['serverUrl'] as String? ?? defaultServerUrl,
      theme: json['theme'] as String? ?? defaultTheme,
      accentColor: json['accentColor'] as int? ?? defaultAccentColor,
      language: json['language'] as String? ?? defaultLanguage,
      showThinking: json['showThinking'] as bool? ?? defaultShowThinking,
      enableVoice: json['enableVoice'] as bool? ?? defaultEnableVoice,
      enableResearch: json['enableResearch'] as bool? ?? defaultEnableResearch,
      enableServerCritic:
          json['enableServerCritic'] as bool? ?? defaultEnableServerCritic,
      disclaimerAccepted:
          json['disclaimerAccepted'] as bool? ?? defaultDisclaimerAccepted,
      maxHistoryTurns:
          json['maxHistoryTurns'] as int? ?? defaultMaxHistoryTurns,
      useCloudApi: json['useCloudApi'] as bool? ?? defaultUseCloudApi,
      cloudApiKey: json['cloudApiKey'] as String? ?? defaultCloudApiKey,
      cloudModelId: json['cloudModelId'] as String? ?? defaultCloudModelId,
      useOllama: json['useOllama'] as bool? ?? defaultUseOllama,
      useSubBackendE2B: json['useSubBackendE2B'] as bool? ?? defaultUseSubBackendE2B,
      useLocalOnDeviceAi: json['useLocalOnDeviceAi'] as bool? ?? defaultUseLocalOnDeviceAi,
      localAiType: json['localAiType'] as String? ?? defaultLocalAiType,
      allergies: json['allergies'] as String? ?? defaultAllergies,
      conditions: json['conditions'] as String? ?? defaultConditions,
      medications: json['medications'] as String? ?? defaultMedications,
      age: json['age'] as int?,
      weight: json['weight'] as double?,
      clinicalNotes: json['clinicalNotes'] as String? ?? defaultClinicalNotes,
    );
  }

  @override
  String toString() =>
      'AppSettings(server: $serverUrl, theme: $theme, lang: $language, cloud: $useCloudApi)';
}
