// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Gemma Health Edge';

  @override
  String get chatPlaceholder => 'Stellen Sie eine Gesundheitsfrage...';

  @override
  String get sendButton => 'Senden';

  @override
  String get clearChat => 'Chat löschen';

  @override
  String get newSession => 'Neue Sitzung';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get serverUrl => 'Server-URL';

  @override
  String get serverStatus => 'Serverstatus';

  @override
  String get serverOnline => 'Online';

  @override
  String get serverOffline => 'Offline';

  @override
  String get serverChecking => 'Wird überprüft...';

  @override
  String get autoDetect => 'Auto-Erkennung';

  @override
  String get themeLabel => 'Design';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeSystem => 'System';

  @override
  String get languageLabel => 'Sprache';

  @override
  String get voiceInput => 'Spracheingabe';

  @override
  String get voiceOutput => 'Sprachausgabe';

  @override
  String get researchMode => 'Recherchemodus';

  @override
  String get showThinking => 'Denkprozess anzeigen';

  @override
  String get calendarTitle => 'Gesundheitskalender';

  @override
  String get moodLabel => 'Stimmung';

  @override
  String get moodPoor => 'Schlecht';

  @override
  String get moodFair => 'Mäßig';

  @override
  String get moodOkay => 'Okay';

  @override
  String get moodGood => 'Gut';

  @override
  String get moodGreat => 'Sehr gut';

  @override
  String get moodAverage => 'Durchschn. diesen Monat';

  @override
  String get clearMood => 'Löschen';

  @override
  String get disclaimerTitle => '⚠️ Medizinischer Haftungsausschluss';

  @override
  String get disclaimerBody =>
      'Diese Anwendung bietet **nur allgemeine Gesundheitsinformationen**. Sie ist **KEIN** Ersatz für professionelle medizinische Beratung, Diagnose oder Behandlung.\n\n• Verlassen Sie sich nicht ausschließlich auf dieses Tool für Gesundheitsentscheidungen\n• Konsultieren Sie immer qualifizierte Gesundheitsfachkräfte\n• Kontaktieren Sie im Notfall sofort Ihre örtlichen Rettungsdienste\n• Die KI kann ungenaue Informationen liefern\n\n**Datenschutz:** Im Offlinemodus bleiben alle Daten auf Ihrem Gerät. Im Online-/Recherchemodus werden Anfragen an Wikipedia gesendet.';

  @override
  String get disclaimerAccept => 'Ich verstehe — Weiter';

  @override
  String get exportData => 'Sicherung exportieren';

  @override
  String get importData => 'Sicherung importieren';

  @override
  String get clearAllData => 'Alle Daten löschen';

  @override
  String get cameraButton => 'Kamera';

  @override
  String get galleryButton => 'Galerie';

  @override
  String get removeImage => 'Bild entfernen';

  @override
  String get imageAttached => 'Bild angehängt';

  @override
  String get thinking => 'Denken...';

  @override
  String get researchNote => '🔬 Wikipedia-Kontext hinzugefügt';

  @override
  String get notADoctor =>
      'Ich bin kein Arzt. Konsultieren Sie immer einen Gesundheitsfachmann.';

  @override
  String get consultProfessional =>
      'Konsultieren Sie einen Gesundheitsfachmann für medizinische Beratung.';

  @override
  String get emergencyNote =>
      'Im Notfall kontaktieren Sie Ihre örtlichen Rettungsdienste.';

  @override
  String get sessionHistory => 'Sitzungsverlauf';

  @override
  String get deleteSession => 'Sitzung löschen';

  @override
  String get noSessions => 'Keine gespeicherten Sitzungen';

  @override
  String get typingIndicator => 'Schreibt...';

  @override
  String get copyMessage => 'Kopieren';

  @override
  String get errorTitle => 'Fehler';

  @override
  String get errorRetry => 'Wiederholen';

  @override
  String get offlineMode => 'Offline';

  @override
  String get onlineMode => 'Online';

  @override
  String get accentColor => 'Akzentfarbe';

  @override
  String get resetColors => 'Farben zurücksetzen';

  @override
  String get serverNote =>
      'Für LAN-Zugang verwenden Sie die lokale IP Ihres PCs. Für Fernzugriff verwenden Sie die cloudflared-Tunnel-URL.';

  @override
  String get clearAllConfirm =>
      'Möchten Sie wirklich alle Daten löschen? Dies kann nicht rückgängig gemacht werden.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get welcomeTitle => 'Willkommen bei Gemma Health Edge';

  @override
  String get welcomeSubtitle => 'Ihr Offline-Gesundheitsassistent';

  @override
  String get suggestionSkin => 'Hautzustand analysieren';

  @override
  String get suggestionMeds => 'Medikamenteninfo prüfen';

  @override
  String get suggestionNutrition => 'Ernährungsberatung';

  @override
  String get suggestionFirstAid => 'Erste-Hilfe-Anleitung';

  @override
  String get storageStats => 'Speicher verwendet';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutDisclaimer => 'Medizinischer Haftungsausschluss';

  @override
  String get featuresSection => 'Funktionen';

  @override
  String get dataSection => 'Daten';

  @override
  String get aboutSection => 'Über';

  @override
  String get serverSection => 'Server';

  @override
  String get appearanceSection => 'Darstellung';

  @override
  String get testConnection => 'Testen';

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
