// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Gemma Health Edge';

  @override
  String get chatPlaceholder => '건강 질문을 입력하세요...';

  @override
  String get sendButton => '보내기';

  @override
  String get clearChat => '채팅 지우기';

  @override
  String get newSession => '새 세션';

  @override
  String get settingsTitle => '설정';

  @override
  String get serverUrl => '서버 URL';

  @override
  String get serverStatus => '서버 상태';

  @override
  String get serverOnline => '온라인';

  @override
  String get serverOffline => '오프라인';

  @override
  String get serverChecking => '확인 중...';

  @override
  String get autoDetect => '자동 감지';

  @override
  String get themeLabel => '테마';

  @override
  String get themeDark => '다크';

  @override
  String get themeLight => '라이트';

  @override
  String get themeSystem => '시스템';

  @override
  String get languageLabel => '언어';

  @override
  String get voiceInput => '음성 입력';

  @override
  String get voiceOutput => '음성 출력';

  @override
  String get researchMode => '연구 모드';

  @override
  String get showThinking => '생각 과정 표시';

  @override
  String get calendarTitle => '건강 캘린더';

  @override
  String get moodLabel => '기분';

  @override
  String get moodPoor => '나쁨';

  @override
  String get moodFair => '보통';

  @override
  String get moodOkay => '괜찮음';

  @override
  String get moodGood => '좋음';

  @override
  String get moodGreat => '매우 좋음';

  @override
  String get moodAverage => '이번 달 평균';

  @override
  String get clearMood => '지우기';

  @override
  String get disclaimerTitle => '⚠️ 의료 면책 조항';

  @override
  String get disclaimerBody =>
      '이 애플리케이션은 **일반적인 건강 정보만 제공**합니다. 전문적인 의료 조언, 진단 또는 치료의 대체품이 아닙니다.\n\n• 건강 결정을 이 도구에만 의존하지 마세요\n• 항상 자격 있는 의료 전문가와 상담하세요\n• 응급 상황에서는 즉시 지역 응급 서비스에 연락하세요\n• AI는 부정확한 정보를 생성할 수 있습니다\n\n**개인정보:** 오프라인 모드에서는 모든 데이터가 기기에 유지됩니다. 온라인/연구 모드에서는 쿼리가 Wikipedia로 전송됩니다.';

  @override
  String get disclaimerAccept => '이해했습니다 — 계속';

  @override
  String get exportData => '백업 내보내기';

  @override
  String get importData => '백업 가져오기';

  @override
  String get clearAllData => '모든 데이터 지우기';

  @override
  String get cameraButton => '카메라';

  @override
  String get galleryButton => '갤러리';

  @override
  String get removeImage => '이미지 제거';

  @override
  String get imageAttached => '이미지가 첨부됨';

  @override
  String get thinking => '생각 중...';

  @override
  String get researchNote => '🔬 Wikipedia 컨텍스트가 추가됨';

  @override
  String get notADoctor => '저는 의사가 아닙니다. 항상 의료 전문가와 상담하세요.';

  @override
  String get consultProfessional => '의료 조언은 의료 전문가와 상담하세요.';

  @override
  String get emergencyNote => '응급 상황에서는 지역 응급 서비스에 연락하세요.';

  @override
  String get sessionHistory => '세션 기록';

  @override
  String get deleteSession => '세션 삭제';

  @override
  String get noSessions => '저장된 세션 없음';

  @override
  String get typingIndicator => '입력 중...';

  @override
  String get copyMessage => '복사';

  @override
  String get errorTitle => '오류';

  @override
  String get errorRetry => '재시도';

  @override
  String get offlineMode => '오프라인';

  @override
  String get onlineMode => '온라인';

  @override
  String get accentColor => '강조 색상';

  @override
  String get resetColors => '색상 재설정';

  @override
  String get serverNote =>
      'LAN 액세스의 경우 PC의 로컬 IP를 사용하세요. 원격 액세스의 경우 cloudflared 터널 URL을 사용하세요.';

  @override
  String get clearAllConfirm => '모든 데이터를 지우시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get welcomeTitle => 'Gemma Health Edge에 오신 것을 환영합니다';

  @override
  String get welcomeSubtitle => '오프라인 건강 도우미';

  @override
  String get suggestionSkin => '피부 상태 분석';

  @override
  String get suggestionMeds => '약품 정보 확인';

  @override
  String get suggestionNutrition => '영양 조언';

  @override
  String get suggestionFirstAid => '응급 처치 가이드';

  @override
  String get storageStats => '사용된 저장 공간';

  @override
  String get aboutVersion => '버전';

  @override
  String get aboutDisclaimer => '의료 면책 조항';

  @override
  String get featuresSection => '기능';

  @override
  String get dataSection => '데이터';

  @override
  String get aboutSection => '정보';

  @override
  String get serverSection => '서버';

  @override
  String get appearanceSection => '모양';

  @override
  String get testConnection => '테스트';

  @override
  String serverFound(String url) {
    return '서버 찾음: $url';
  }

  @override
  String get noServerFound => '서버를 찾을 수 없음';

  @override
  String get serverNotRunning => '서버가 실행 중인가요?';

  @override
  String get requestTimeout => '요청 시간 초과';

  @override
  String serverError(int code) {
    return '서버 오류: $code';
  }

  @override
  String get exportChat => '채팅 내보내기';

  @override
  String get privacyBadge => '100% 개인정보 보호';
}
