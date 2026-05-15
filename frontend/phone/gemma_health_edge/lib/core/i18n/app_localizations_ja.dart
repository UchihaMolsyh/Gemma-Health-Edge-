// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Gemma Health Edge';

  @override
  String get chatPlaceholder => '健康について質問する...';

  @override
  String get sendButton => '送信';

  @override
  String get clearChat => 'チャットをクリア';

  @override
  String get newSession => '新しいセッション';

  @override
  String get settingsTitle => '設定';

  @override
  String get serverUrl => 'サーバーURL';

  @override
  String get serverStatus => 'サーバー状態';

  @override
  String get serverOnline => 'オンライン';

  @override
  String get serverOffline => 'オフライン';

  @override
  String get serverChecking => '確認中...';

  @override
  String get autoDetect => '自動検出';

  @override
  String get themeLabel => 'テーマ';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeSystem => 'システム';

  @override
  String get languageLabel => '言語';

  @override
  String get voiceInput => '音声入力';

  @override
  String get voiceOutput => '音声出力';

  @override
  String get researchMode => 'リサーチモード';

  @override
  String get showThinking => '思考プロセスを表示';

  @override
  String get calendarTitle => 'ヘルスカレンダー';

  @override
  String get moodLabel => '気分';

  @override
  String get moodPoor => '悪い';

  @override
  String get moodFair => 'まあまあ';

  @override
  String get moodOkay => '普通';

  @override
  String get moodGood => '良い';

  @override
  String get moodGreat => '素晴らしい';

  @override
  String get moodAverage => '今月の平均';

  @override
  String get clearMood => 'クリア';

  @override
  String get disclaimerTitle => '⚠️ 医療免責事項';

  @override
  String get disclaimerBody =>
      'このアプリケーションは**一般的な健康情報のみ**を提供します。専門的な医療アドバイス、診断、または治療の代わりではありません。\n\n• 健康上の決定をこのツールのみに依存しないでください\n• 常に資格のある医療専門家に相談してください\n• 緊急時は、直ちに地元の緊急サービスに連絡してください\n• AIは不正確な情報を生成する可能性があります\n\n**プライバシー:** オフラインモードでは、すべてのデータはデバイス上に残ります。オンライン/リサーチモードでは、クエリがWikipediaに送信されます。';

  @override
  String get disclaimerAccept => '理解しました — 続行';

  @override
  String get exportData => 'バックアップをエクスポート';

  @override
  String get importData => 'バックアップをインポート';

  @override
  String get clearAllData => 'すべてのデータをクリア';

  @override
  String get cameraButton => 'カメラ';

  @override
  String get galleryButton => 'ギャラリー';

  @override
  String get removeImage => '画像を削除';

  @override
  String get imageAttached => '画像が添付されました';

  @override
  String get thinking => '思考中...';

  @override
  String get researchNote => '🔬 Wikipediaのコンテキストが追加されました';

  @override
  String get notADoctor => '私は医師ではありません。常に医療専門家に相談してください。';

  @override
  String get consultProfessional => '医療アドバイスについては医療専門家に相談してください。';

  @override
  String get emergencyNote => '緊急時は、地元の緊急サービスに連絡してください。';

  @override
  String get sessionHistory => 'セッション履歴';

  @override
  String get deleteSession => 'セッションを削除';

  @override
  String get noSessions => '保存されたセッションはありません';

  @override
  String get typingIndicator => '入力中...';

  @override
  String get copyMessage => 'コピー';

  @override
  String get errorTitle => 'エラー';

  @override
  String get errorRetry => '再試行';

  @override
  String get offlineMode => 'オフライン';

  @override
  String get onlineMode => 'オンライン';

  @override
  String get accentColor => 'アクセントカラー';

  @override
  String get resetColors => '色をリセット';

  @override
  String get serverNote =>
      'LANアクセスの場合、PCのローカルIPを使用してください。リモートアクセスの場合、cloudflaredトンネルURLを使用してください。';

  @override
  String get clearAllConfirm => 'すべてのデータをクリアしてもよろしいですか？これは元に戻すことができません。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get welcomeTitle => 'Gemma Health Edgeへようこそ';

  @override
  String get welcomeSubtitle => 'あなたのオフラインヘルスアシスタント';

  @override
  String get suggestionSkin => '皮膚の状態を分析';

  @override
  String get suggestionMeds => '薬の情報を確認';

  @override
  String get suggestionNutrition => '栄養アドバイス';

  @override
  String get suggestionFirstAid => '応急処置ガイダンス';

  @override
  String get storageStats => '使用済みストレージ';

  @override
  String get aboutVersion => 'バージョン';

  @override
  String get aboutDisclaimer => '医療免責事項';

  @override
  String get featuresSection => '機能';

  @override
  String get dataSection => 'データ';

  @override
  String get aboutSection => 'について';

  @override
  String get serverSection => 'サーバー';

  @override
  String get appearanceSection => '外観';

  @override
  String get testConnection => 'テスト';

  @override
  String serverFound(String url) {
    return 'サーバーが見つかりました: $url';
  }

  @override
  String get noServerFound => 'サーバーが見つかりません';

  @override
  String get serverNotRunning => 'サーバーは実行されていますか？';

  @override
  String get requestTimeout => 'リクエストがタイムアウトしました';

  @override
  String serverError(int code) {
    return 'サーバーエラー: $code';
  }

  @override
  String get exportChat => 'チャットをエクスポート';

  @override
  String get privacyBadge => '100% プライベート';
}
