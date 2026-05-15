// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Gemma Health Edge';

  @override
  String get chatPlaceholder => 'Haz una pregunta de salud...';

  @override
  String get sendButton => 'Enviar';

  @override
  String get clearChat => 'Borrar chat';

  @override
  String get newSession => 'Nueva sesión';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get serverUrl => 'URL del servidor';

  @override
  String get serverStatus => 'Estado del servidor';

  @override
  String get serverOnline => 'En línea';

  @override
  String get serverOffline => 'Sin conexión';

  @override
  String get serverChecking => 'Verificando...';

  @override
  String get autoDetect => 'Detección automática';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get voiceInput => 'Entrada de voz';

  @override
  String get voiceOutput => 'Salida de voz';

  @override
  String get researchMode => 'Modo investigación';

  @override
  String get showThinking => 'Mostrar proceso de pensamiento';

  @override
  String get calendarTitle => 'Calendario de salud';

  @override
  String get moodLabel => 'Estado de ánimo';

  @override
  String get moodPoor => 'Malo';

  @override
  String get moodFair => 'Regular';

  @override
  String get moodOkay => 'Normal';

  @override
  String get moodGood => 'Bueno';

  @override
  String get moodGreat => 'Excelente';

  @override
  String get moodAverage => 'Prom. este mes';

  @override
  String get clearMood => 'Borrar';

  @override
  String get disclaimerTitle => '⚠️ Aviso médico';

  @override
  String get disclaimerBody =>
      'Esta aplicación proporciona **solo información general de salud**. **NO** sustituye el consejo médico profesional, el diagnóstico o el tratamiento.\n\n• No confíe únicamente en esta herramienta para decisiones de salud\n• Consulte siempre a profesionales de salud calificados\n• En emergencias, contacte inmediatamente a los servicios de emergencia locales\n• La IA puede producir información inexacta\n\n**Privacidad:** En modo sin conexión, todos los datos permanecen en su dispositivo. En modo en línea/investigación, las consultas se envían a Wikipedia.';

  @override
  String get disclaimerAccept => 'Entiendo — Continuar';

  @override
  String get exportData => 'Exportar copia de seguridad';

  @override
  String get importData => 'Importar copia de seguridad';

  @override
  String get clearAllData => 'Borrar todos los datos';

  @override
  String get cameraButton => 'Cámara';

  @override
  String get galleryButton => 'Galería';

  @override
  String get removeImage => 'Eliminar imagen';

  @override
  String get imageAttached => 'Imagen adjunta';

  @override
  String get thinking => 'Pensando...';

  @override
  String get researchNote => '🔬 Contexto de Wikipedia añadido';

  @override
  String get notADoctor =>
      'No soy médico. Siempre consulte a un profesional de salud.';

  @override
  String get consultProfessional =>
      'Consulte a un profesional de salud para consejo médico.';

  @override
  String get emergencyNote =>
      'En emergencias, contacte a sus servicios de emergencia locales.';

  @override
  String get sessionHistory => 'Historial de sesiones';

  @override
  String get deleteSession => 'Eliminar sesión';

  @override
  String get noSessions => 'Sin sesiones guardadas';

  @override
  String get typingIndicator => 'Escribiendo...';

  @override
  String get copyMessage => 'Copiar';

  @override
  String get errorTitle => 'Error';

  @override
  String get errorRetry => 'Reintentar';

  @override
  String get offlineMode => 'Sin conexión';

  @override
  String get onlineMode => 'En línea';

  @override
  String get accentColor => 'Color de acento';

  @override
  String get resetColors => 'Restablecer colores';

  @override
  String get serverNote =>
      'Para acceso LAN, use la IP local de su PC. Para acceso remoto, use la URL del túnel cloudflared.';

  @override
  String get clearAllConfirm =>
      '¿Está seguro de que desea borrar todos los datos? Esta acción no se puede deshacer.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get welcomeTitle => 'Bienvenido a Gemma Health Edge';

  @override
  String get welcomeSubtitle => 'Tu asistente de salud sin conexión';

  @override
  String get suggestionSkin => 'Analizar una condición cutánea';

  @override
  String get suggestionMeds => 'Consultar info de medicamentos';

  @override
  String get suggestionNutrition => 'Consejos de nutrición';

  @override
  String get suggestionFirstAid => 'Guía de primeros auxilios';

  @override
  String get storageStats => 'Almacenamiento usado';

  @override
  String get aboutVersion => 'Versión';

  @override
  String get aboutDisclaimer => 'Aviso médico';

  @override
  String get featuresSection => 'Funciones';

  @override
  String get dataSection => 'Datos';

  @override
  String get aboutSection => 'Acerca de';

  @override
  String get serverSection => 'Servidor';

  @override
  String get appearanceSection => 'Apariencia';

  @override
  String get testConnection => 'Probar';

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
