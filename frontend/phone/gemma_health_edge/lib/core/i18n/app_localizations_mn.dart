// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Mongolian (`mn`).
class AppLocalizationsMn extends AppLocalizations {
  AppLocalizationsMn([String locale = 'mn']) : super(locale);

  @override
  String get appTitle => 'Gemma Health Edge';

  @override
  String get chatPlaceholder => 'Эрүүл мэндийн талаар асуулт асуух...';

  @override
  String get sendButton => 'Илгээх';

  @override
  String get clearChat => 'Чатыг цэвэрлэх';

  @override
  String get newSession => 'Шинэ сесс';

  @override
  String get settingsTitle => 'Тохиргоо';

  @override
  String get serverUrl => 'Серверийн URL';

  @override
  String get serverStatus => 'Серверийн төлөв';

  @override
  String get serverOnline => 'Онлайн';

  @override
  String get serverOffline => 'Оффлайн';

  @override
  String get serverChecking => 'Шалгаж байна...';

  @override
  String get autoDetect => 'Автомат илрүүлэх';

  @override
  String get themeLabel => 'Загвар';

  @override
  String get themeDark => 'Харанхуй';

  @override
  String get themeLight => 'Гэгээн';

  @override
  String get themeSystem => 'Систем';

  @override
  String get languageLabel => 'Хэл';

  @override
  String get voiceInput => 'Дуут оролт';

  @override
  String get voiceOutput => 'Дуут гаралт';

  @override
  String get researchMode => 'Судалгааны горим';

  @override
  String get showThinking => 'Сэтгэгдлийн үйл явц харуулах';

  @override
  String get calendarTitle => 'Эрүүл мэндийн календар';

  @override
  String get moodLabel => 'Сэтгэл';

  @override
  String get moodPoor => 'Муу';

  @override
  String get moodFair => 'Дундаж';

  @override
  String get moodOkay => 'Зүгээр';

  @override
  String get moodGood => 'Сайн';

  @override
  String get moodGreat => 'Маш сайн';

  @override
  String get moodAverage => 'Энэ сарын дундаж';

  @override
  String get clearMood => 'Цэвэрлэх';

  @override
  String get disclaimerTitle => '⚠️ Эрүүл мэндийн анхааруулга';

  @override
  String get disclaimerBody =>
      'Энэ аппликейшн нь **ерөнхий эрүүл мэндийн мэдээлэл л** өгдөг. Энэ нь мэргэжлийн эмнэлгийн зөвлөгөө, оношилгоо эсвэл эмчилгээний орлог биш юм.\n\n• Эрүүл мэндийн шийдвэрийг зөвхөн энэ багажид итгэж болохгүй\n• үргэлж мэргэжлийн эмч нарын зөвлөгөө авна уу\n• Онцгой тохиолдолд орон нутгийн яаралтай тусламжийн үйлчилгээнд шууд холбогдоно уу\n• AI буруу мэдээлэл үүсгэж болно\n\n**Нууцлал:** Оффлайн горимд бүх өгөгдөл төхөөрөм дээр үлдэнэ. Онлайн/судалгааны горимод асуултууд Wikipedia руу илгээгддэг.';

  @override
  String get disclaimerAccept => 'Ойлголоо — Үргэлжлүүлэх';

  @override
  String get exportData => 'Бакап экспортлох';

  @override
  String get importData => 'Бакап импортлох';

  @override
  String get clearAllData => 'Бүх өгөгдлийг цэвэрлэх';

  @override
  String get cameraButton => 'Камер';

  @override
  String get galleryButton => 'Галерей';

  @override
  String get removeImage => 'Зураг устгах';

  @override
  String get imageAttached => 'Зураг хавсаргагдсан';

  @override
  String get thinking => 'Сэтгэж байна...';

  @override
  String get researchNote => '🔬 Wikipedia контекст нэмэгдсэн';

  @override
  String get notADoctor =>
      'Би эмч биш. үргэлж мэргэжлийн эмч нарын зөвлөгөө авна уу.';

  @override
  String get consultProfessional =>
      'Эмнэлгийн зөвлөгөөний тулд мэргэжлийн эмч нартай зөвлөлдөнө үү.';

  @override
  String get emergencyNote =>
      'Онцгой тохиолдолд орон нутгийн яаралтай тусламжийн үйлчилгээнд холбогдоно уу.';

  @override
  String get sessionHistory => 'Сессийн түүх';

  @override
  String get deleteSession => 'Сесс устгах';

  @override
  String get noSessions => 'Хадгалагдсан сесс байхгүй';

  @override
  String get typingIndicator => 'Бичиж байна...';

  @override
  String get copyMessage => 'Хуулах';

  @override
  String get errorTitle => 'Алдаа';

  @override
  String get errorRetry => 'Дахин оролдох';

  @override
  String get offlineMode => 'Оффлайн';

  @override
  String get onlineMode => 'Онлайн';

  @override
  String get accentColor => 'Өнгө';

  @override
  String get resetColors => 'Өнгө дахин тохируулах';

  @override
  String get serverNote =>
      'LAN хандахын тулд PC-ийн дотоод IP-г хэрэглэнэ үү. Алс хандахын тулд cloudflared туннелийн URL-г хэрэглэнэ үү.';

  @override
  String get clearAllConfirm =>
      'Та бүх өгөгдлийг цэвэрлэхийг хүсч байна уу? Энэ үйлдлийг буцаах боломжгүй.';

  @override
  String get cancel => 'Цуцлах';

  @override
  String get confirm => 'Батлах';

  @override
  String get welcomeTitle => 'Gemma Health Edge-д тавтай морилно уу';

  @override
  String get welcomeSubtitle => 'Таны оффлайн эрүүл мэндийн туслах';

  @override
  String get suggestionSkin => 'Арьсны өөрчлөлтийг шинжилгэх';

  @override
  String get suggestionMeds => 'Эмийн мэдээлэл шалгах';

  @override
  String get suggestionNutrition => 'Тэжээлийн зөвлөгөө';

  @override
  String get suggestionFirstAid => 'Анхны тусламжийн зааварчилгаа';

  @override
  String get storageStats => 'Хэрэглэсэн санах ой';

  @override
  String get aboutVersion => 'Хувилбар';

  @override
  String get aboutDisclaimer => 'Эрүүл мэндийн анхааруулга';

  @override
  String get featuresSection => ' боломжууд';

  @override
  String get dataSection => 'Өгөгдөл';

  @override
  String get aboutSection => 'Тухай';

  @override
  String get serverSection => 'Сервер';

  @override
  String get appearanceSection => 'Гадна төрх';

  @override
  String get testConnection => 'Тест';

  @override
  String serverFound(String url) {
    return 'Сервер олсон: $url';
  }

  @override
  String get noServerFound => 'Сервер олсонгүй';

  @override
  String get serverNotRunning => 'Сервер ажиллаж байна уу?';

  @override
  String get requestTimeout => 'Хугацаа хэтэрсэн';

  @override
  String serverError(int code) {
    return 'Серверийн алдаа: $code';
  }

  @override
  String get exportChat => 'Чат экспортлох';

  @override
  String get privacyBadge => '100% хувийн';
}
