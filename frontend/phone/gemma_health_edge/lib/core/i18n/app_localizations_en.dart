// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gemma Health Edge';

  @override
  String get chatPlaceholder => 'Ask a health question...';

  @override
  String get sendButton => 'Send';

  @override
  String get clearChat => 'Clear Chat';

  @override
  String get newSession => 'New Session';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverStatus => 'Server Status';

  @override
  String get serverOnline => 'Online';

  @override
  String get serverOffline => 'Offline';

  @override
  String get serverChecking => 'Checking...';

  @override
  String get autoDetect => 'Auto-detect';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get languageLabel => 'Language';

  @override
  String get voiceInput => 'Voice Input';

  @override
  String get voiceOutput => 'Voice Output';

  @override
  String get researchMode => 'Research Mode';

  @override
  String get showThinking => 'Show Thinking Process';

  @override
  String get calendarTitle => 'Health Calendar';

  @override
  String get moodLabel => 'Mood';

  @override
  String get moodPoor => 'Poor';

  @override
  String get moodFair => 'Fair';

  @override
  String get moodOkay => 'Okay';

  @override
  String get moodGood => 'Good';

  @override
  String get moodGreat => 'Great';

  @override
  String get moodAverage => 'Avg this month';

  @override
  String get clearMood => 'Clear';

  @override
  String get disclaimerTitle => '⚠️ Medical Disclaimer';

  @override
  String get disclaimerBody =>
      'This application provides **general health information only**. It is **NOT** a substitute for professional medical advice, diagnosis, or treatment.\n\n• Do not rely solely on this tool for health decisions\n• Always consult qualified healthcare professionals\n• In emergencies, contact your local emergency services immediately\n• The AI may produce inaccurate information\n\n**Privacy:** In offline mode, all data stays on your device. In online/research mode, queries are sent to Wikipedia.';

  @override
  String get disclaimerAccept => 'I Understand — Continue';

  @override
  String get exportData => 'Export Backup';

  @override
  String get importData => 'Import Backup';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get cameraButton => 'Camera';

  @override
  String get galleryButton => 'Gallery';

  @override
  String get removeImage => 'Remove Image';

  @override
  String get imageAttached => 'Image attached';

  @override
  String get thinking => 'Thinking...';

  @override
  String get researchNote => '🔬 Wikipedia context added';

  @override
  String get notADoctor =>
      'I\'m not a doctor. Always consult a healthcare professional.';

  @override
  String get consultProfessional =>
      'Consult a healthcare professional for medical advice.';

  @override
  String get emergencyNote =>
      'In emergencies, contact your local emergency services.';

  @override
  String get sessionHistory => 'Session History';

  @override
  String get deleteSession => 'Delete Session';

  @override
  String get noSessions => 'No saved sessions';

  @override
  String get typingIndicator => 'Typing...';

  @override
  String get copyMessage => 'Copy';

  @override
  String get errorTitle => 'Error';

  @override
  String get errorRetry => 'Retry';

  @override
  String get offlineMode => 'Offline';

  @override
  String get onlineMode => 'Online';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get resetColors => 'Reset Colors';

  @override
  String get serverNote =>
      'For LAN access, use your PC\'s local IP. For remote access, use the cloudflared tunnel URL.';

  @override
  String get clearAllConfirm =>
      'Are you sure you want to clear all data? This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get welcomeTitle => 'Welcome to Gemma Health Edge';

  @override
  String get welcomeSubtitle => 'Your offline health assistant';

  @override
  String get suggestionSkin => 'Analyze a skin condition';

  @override
  String get suggestionMeds => 'Check medication info';

  @override
  String get suggestionNutrition => 'Nutrition advice';

  @override
  String get suggestionFirstAid => 'First aid guidance';

  @override
  String get storageStats => 'Storage Used';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutDisclaimer => 'Medical Disclaimer';

  @override
  String get featuresSection => 'Features';

  @override
  String get dataSection => 'Data';

  @override
  String get aboutSection => 'About';

  @override
  String get serverSection => 'Server';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get testConnection => 'Test';

  @override
  String serverFound(String url) {
    return 'Server found: $url';
  }

  @override
  String get noServerFound => 'No server found';

  @override
  String get serverNotRunning => 'Is the server running?';

  @override
  String get requestTimeout => 'Request timed out';

  @override
  String serverError(int code) {
    return 'Server returned $code';
  }

  @override
  String get exportChat => 'Export Chat';

  @override
  String get privacyBadge => '100% Private';
}
