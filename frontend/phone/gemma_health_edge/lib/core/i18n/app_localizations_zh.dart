// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Gemma 健康助手';

  @override
  String get chatPlaceholder => '提出健康问题...';

  @override
  String get sendButton => '发送';

  @override
  String get clearChat => '清除聊天';

  @override
  String get newSession => '新会话';

  @override
  String get settingsTitle => '设置';

  @override
  String get serverUrl => '服务器地址';

  @override
  String get serverStatus => '服务器状态';

  @override
  String get serverOnline => '在线';

  @override
  String get serverOffline => '离线';

  @override
  String get serverChecking => '检查中...';

  @override
  String get autoDetect => '自动检测';

  @override
  String get themeLabel => '主题';

  @override
  String get themeDark => '深色';

  @override
  String get themeLight => '浅色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get languageLabel => '语言';

  @override
  String get voiceInput => '语音输入';

  @override
  String get voiceOutput => '语音输出';

  @override
  String get researchMode => '研究模式';

  @override
  String get showThinking => '显示思考过程';

  @override
  String get calendarTitle => '健康日历';

  @override
  String get moodLabel => '心情';

  @override
  String get moodPoor => '差';

  @override
  String get moodFair => '一般';

  @override
  String get moodOkay => '还好';

  @override
  String get moodGood => '好';

  @override
  String get moodGreat => '很棒';

  @override
  String get moodAverage => '本月平均';

  @override
  String get clearMood => '清除';

  @override
  String get disclaimerTitle => '⚠️ 医疗免责声明';

  @override
  String get disclaimerBody =>
      '此应用仅提供**一般健康信息**。它**不能**替代专业医疗建议、诊断或治疗。\n\n• 不要仅依赖此工具做出健康决定\n• 始终咨询合格的医疗专业人员\n• 紧急情况请立即联系当地急救服务\n• AI可能产生不准确的信息\n\n**隐私：** 在离线模式下，所有数据都保留在您的设备上。在在线/研究模式下，查询会发送到维基百科。';

  @override
  String get disclaimerAccept => '我理解 — 继续';

  @override
  String get exportData => '导出备份';

  @override
  String get importData => '导入备份';

  @override
  String get clearAllData => '清除所有数据';

  @override
  String get cameraButton => '相机';

  @override
  String get galleryButton => '相册';

  @override
  String get removeImage => '删除图片';

  @override
  String get imageAttached => 'Image attached';

  @override
  String get thinking => '思考中...';

  @override
  String get researchNote => '🔬 已添加维基百科上下文';

  @override
  String get notADoctor => '我不是医生。请始终咨询医疗专业人员。';

  @override
  String get consultProfessional => '请咨询医疗专业人员获取医疗建议。';

  @override
  String get emergencyNote => '紧急情况请联系当地急救服务。';

  @override
  String get sessionHistory => '会话历史';

  @override
  String get deleteSession => '删除会话';

  @override
  String get noSessions => '没有保存的会话';

  @override
  String get typingIndicator => '输入中...';

  @override
  String get copyMessage => '复制';

  @override
  String get errorTitle => '错误';

  @override
  String get errorRetry => '重试';

  @override
  String get offlineMode => '离线';

  @override
  String get onlineMode => '在线';

  @override
  String get accentColor => '强调色';

  @override
  String get resetColors => '重置颜色';

  @override
  String get serverNote => '局域网访问请使用电脑的本地IP。远程访问请使用cloudflared隧道URL。';

  @override
  String get clearAllConfirm => '确定要清除所有数据吗？此操作不可撤销。';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get welcomeTitle => '欢迎使用 Gemma 健康助手';

  @override
  String get welcomeSubtitle => '您的离线健康助手';

  @override
  String get suggestionSkin => '分析皮肤状况';

  @override
  String get suggestionMeds => '查询药物信息';

  @override
  String get suggestionNutrition => '营养建议';

  @override
  String get suggestionFirstAid => '急救指导';

  @override
  String get storageStats => '已用存储';

  @override
  String get aboutVersion => '版本';

  @override
  String get aboutDisclaimer => '医疗免责声明';

  @override
  String get featuresSection => '功能';

  @override
  String get dataSection => '数据';

  @override
  String get aboutSection => '关于';

  @override
  String get serverSection => '服务器';

  @override
  String get appearanceSection => '外观';

  @override
  String get testConnection => '测试';

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
