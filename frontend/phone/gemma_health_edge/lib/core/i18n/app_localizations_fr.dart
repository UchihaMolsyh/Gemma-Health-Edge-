// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Gemma Health Edge';

  @override
  String get chatPlaceholder => 'Posez une question de santé...';

  @override
  String get sendButton => 'Envoyer';

  @override
  String get clearChat => 'Effacer le chat';

  @override
  String get newSession => 'Nouvelle session';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get serverUrl => 'URL du serveur';

  @override
  String get serverStatus => 'État du serveur';

  @override
  String get serverOnline => 'En ligne';

  @override
  String get serverOffline => 'Hors ligne';

  @override
  String get serverChecking => 'Vérification...';

  @override
  String get autoDetect => 'Détection auto';

  @override
  String get themeLabel => 'Thème';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeSystem => 'Système';

  @override
  String get languageLabel => 'Langue';

  @override
  String get voiceInput => 'Entrée vocale';

  @override
  String get voiceOutput => 'Sortie vocale';

  @override
  String get researchMode => 'Mode recherche';

  @override
  String get showThinking => 'Afficher le processus de réflexion';

  @override
  String get calendarTitle => 'Calendrier santé';

  @override
  String get moodLabel => 'Humeur';

  @override
  String get moodPoor => 'Mauvais';

  @override
  String get moodFair => 'Passable';

  @override
  String get moodOkay => 'Correct';

  @override
  String get moodGood => 'Bien';

  @override
  String get moodGreat => 'Excellent';

  @override
  String get moodAverage => 'Moy. ce mois';

  @override
  String get clearMood => 'Effacer';

  @override
  String get disclaimerTitle => '⚠️ Avertissement médical';

  @override
  String get disclaimerBody =>
      'Cette application fournit **uniquement des informations générales sur la santé**. Elle ne remplace **PAS** un avis médical professionnel, un diagnostic ou un traitement.\n\n• Ne vous fiez pas uniquement à cet outil pour vos décisions de santé\n• Consultez toujours des professionnels de santé qualifiés\n• En cas d\'urgence, contactez immédiatement les services d\'urgence locaux\n• L\'IA peut produire des informations inexactes\n\n**Confidentialité :** En mode hors ligne, toutes les données restent sur votre appareil. En mode en ligne/recherche, les requêtes sont envoyées à Wikipédia.';

  @override
  String get disclaimerAccept => 'Je comprends — Continuer';

  @override
  String get exportData => 'Exporter la sauvegarde';

  @override
  String get importData => 'Importer la sauvegarde';

  @override
  String get clearAllData => 'Effacer toutes les données';

  @override
  String get cameraButton => 'Caméra';

  @override
  String get galleryButton => 'Galerie';

  @override
  String get removeImage => 'Supprimer l\'image';

  @override
  String get imageAttached => 'Image jointe';

  @override
  String get thinking => 'Réflexion...';

  @override
  String get researchNote => '🔬 Contexte Wikipédia ajouté';

  @override
  String get notADoctor =>
      'Je ne suis pas médecin. Consultez toujours un professionnel de santé.';

  @override
  String get consultProfessional =>
      'Consultez un professionnel de santé pour un avis médical.';

  @override
  String get emergencyNote =>
      'En cas d\'urgence, contactez vos services d\'urgence locaux.';

  @override
  String get sessionHistory => 'Historique des sessions';

  @override
  String get deleteSession => 'Supprimer la session';

  @override
  String get noSessions => 'Aucune session enregistrée';

  @override
  String get typingIndicator => 'Saisie en cours...';

  @override
  String get copyMessage => 'Copier';

  @override
  String get errorTitle => 'Erreur';

  @override
  String get errorRetry => 'Réessayer';

  @override
  String get offlineMode => 'Hors ligne';

  @override
  String get onlineMode => 'En ligne';

  @override
  String get accentColor => 'Couleur d\'accentuation';

  @override
  String get resetColors => 'Réinitialiser les couleurs';

  @override
  String get serverNote =>
      'Pour l\'accès LAN, utilisez l\'IP locale de votre PC. Pour l\'accès distant, utilisez l\'URL du tunnel cloudflared.';

  @override
  String get clearAllConfirm =>
      'Êtes-vous sûr de vouloir effacer toutes les données ? Cette action est irréversible.';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get welcomeTitle => 'Bienvenue sur Gemma Health Edge';

  @override
  String get welcomeSubtitle => 'Votre assistant santé hors ligne';

  @override
  String get suggestionSkin => 'Analyser une affection cutanée';

  @override
  String get suggestionMeds => 'Vérifier les infos médicaments';

  @override
  String get suggestionNutrition => 'Conseils nutrition';

  @override
  String get suggestionFirstAid => 'Premiers secours';

  @override
  String get storageStats => 'Stockage utilisé';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutDisclaimer => 'Avertissement médical';

  @override
  String get featuresSection => 'Fonctionnalités';

  @override
  String get dataSection => 'Données';

  @override
  String get aboutSection => 'À propos';

  @override
  String get serverSection => 'Serveur';

  @override
  String get appearanceSection => 'Apparence';

  @override
  String get testConnection => 'Tester';

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
