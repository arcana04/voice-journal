// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get navRecord => '녹음';

  @override
  String get navDiary => '일기';

  @override
  String get navIdea => '아이디어';

  @override
  String get navTask => '할 일';

  @override
  String get navKnowledgeBase => '질문';

  @override
  String get onboardingSkip => '건너뛰기';

  @override
  String get onboardingNext => '다음';

  @override
  String get onboardingGetStarted => '시작하기';

  @override
  String get onboardingCreateAccount => '계정 만들기(나중에 설정에서도 할 수 있어요)';

  @override
  String get onboardingPage1Title => '무언가 떠오르는 순간,\n그냥 소리 내어 말해보세요';

  @override
  String get onboardingPage1Body =>
      '녹음 버튼을 누르고 말하면, 나머지는 Voice Brain이 알아서 처리해요';

  @override
  String get onboardingPage2Title => 'AI가 알아서 정리해요';

  @override
  String get onboardingPage2Body =>
      '말한 내용은 AI가 텍스트로 변환해 일기, 아이디어, 할 일로 자동 분류합니다. 당신의 목소리는 오직 당신만의 데이터로 안전하게 다뤄집니다.';

  @override
  String get onboardingFreeTierTitle => '지금 바로 무료로 시작';

  @override
  String get onboardingFreeTierBody =>
      '무료 플랜에서는 하루 3회, 회당 최대 60초까지 녹음할 수 있어요. 더 필요하다면 더 길고 자주 녹음할 수 있는 Pro 플랜을 확인해 보세요.';

  @override
  String get onboardingMicTitle => '마이크 접근 권한이 필요해요';

  @override
  String get onboardingMicBody =>
      'Voice Brain은 녹음을 위해 마이크를 사용합니다. 다음에 권한 요청이 뜨면 \"허용\"을 눌러 주세요.';

  @override
  String get onboardingPage3Title => '시작해 볼까요';

  @override
  String get onboardingPage3Body => '떠오르는 생각이 있을 때마다 탭하고 말해 보세요';

  @override
  String get emotionFatigue => '피곤함';

  @override
  String get emotionLove => '사랑';

  @override
  String get emotionAnxious => '불안';

  @override
  String get emotionExcited => '설렘';

  @override
  String get emotionJoy => '즐거움';

  @override
  String get emotionSadness => '슬픔';

  @override
  String get emotionAnger => '분노';

  @override
  String get emotionSatisfaction => '만족';

  @override
  String get emotionNeutral => '보통';

  @override
  String get emotionGratitude => '감사';

  @override
  String get emotionHappy => '행복';

  @override
  String get emotionFunny => '재미있음';

  @override
  String get emotionRelief => '안심';

  @override
  String get emotionCalm => '차분함';

  @override
  String get emotionBoredom => '지루함';

  @override
  String get emotionRegret => '후회';

  @override
  String get emotionDislike => '싫음';

  @override
  String get confirmDeleteTitle => '삭제할까요?';

  @override
  String get confirmDeleteMessage => '이 항목을 삭제하면 되돌릴 수 없습니다.';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get save => '저장';

  @override
  String get editTooltip => '수정';

  @override
  String get micPermissionDenied => '마이크 사용이 허용되지 않았습니다';

  @override
  String get recordingStopFailedTitle => '녹음 중지에 실패했습니다';

  @override
  String get recordingErrorTitle => '녹음 오류';

  @override
  String get recordingSaveFailed => '녹음 저장에 실패했습니다';

  @override
  String get processingErrorTitle => '처리 중 오류가 발생했습니다';

  @override
  String statusError(String message) {
    return '오류: $message';
  }

  @override
  String statusOrganized(String summary) {
    return '정리했어요: $summary';
  }

  @override
  String get statusTapToRecord => '탭하여 녹음 시작';

  @override
  String get statusRecording => '녹음 중… 다시 탭하면 중지';

  @override
  String get statusProcessing => 'AI가 분석하고 있어요…';

  @override
  String get statusProcessingSorting => '일기·아이디어·할 일로 분류하고 있어요…';

  @override
  String get statusProcessingFinishing => '마무리하고 있어요…';

  @override
  String maxRecordingSeconds(int seconds) {
    return '한 번에 최대 $seconds초까지 녹음할 수 있어요';
  }

  @override
  String maxRecordingMinutes(int minutes) {
    return '한 번에 최대 $minutes분까지 녹음할 수 있어요';
  }

  @override
  String streakTooltip(int days) {
    return '$days일 연속 기록 중';
  }

  @override
  String get textComposeTooltip => '텍스트로 입력';

  @override
  String get settingsTooltip => '설정';

  @override
  String get menuCustomDictionary => '사용자 사전';

  @override
  String get menuSummaryLevel => 'AI 요약 정도';

  @override
  String get textComposerTitle => '텍스트로 입력';

  @override
  String get textComposerDescription =>
      '말할 수 없을 때 사용하세요. 녹음과 마찬가지로 AI가 일기, 할 일, 아이디어로 분류해줍니다.';

  @override
  String get textComposerHint => '예: 내일 오후 3시 치과 예약하기';

  @override
  String get textComposerSubmit => 'AI에게 분석시키기';

  @override
  String get summaryLevelSheetTitle => 'AI 요약 정도';

  @override
  String get summaryLevelSheetDescription =>
      '녹음이나 텍스트에서 일기 내용을 AI가 얼마나 줄일지 선택하세요. 할 일의 간결함에는 영향을 주지 않아요.';

  @override
  String get summaryLevelPreserveLabel => '원형 유지';

  @override
  String get summaryLevelStandardLabel => '표준';

  @override
  String get summaryLevelCompactLabel => '간결';

  @override
  String get summaryLevelPreserveDescription =>
      '말한 그대로의 감정, 표현, 이름을 요약 없이 그대로 유지해요.';

  @override
  String get summaryLevelStandardDescription =>
      '자연스러운 일기 길이는 유지하면서 중복된 반복만 정리해요.';

  @override
  String get summaryLevelCompactDescription => '핵심만 남기고 1~2문장으로 압축해요.';

  @override
  String get settingsTitle => '설정';

  @override
  String get displaySectionTitle => '화면';

  @override
  String get darkModeTitle => '다크 모드';

  @override
  String get darkModeSubtitle => '눈이 편안한 화면으로 전환';

  @override
  String get themeColorTitle => '테마 색상';

  @override
  String get themeColorSubtitle => '앱 전체의 강조 색상을 변경';

  @override
  String get themeColorSheetTitle => '테마 색상 선택';

  @override
  String get settingsProBadge => 'Pro 전용';

  @override
  String get integrationsSettingsTitle => '연동';

  @override
  String get integrationsCalendarRowTitle => '캘린더 연동';

  @override
  String get integrationsScreenTitle => '연동';

  @override
  String get integrationsDescription =>
      '이 기기에 이미 설정된 캘린더(iOS 캘린더나 시스템 설정에 추가한 Google 계정 등)를 선택하세요. 켜두면 날짜와 시간이 있는 할 일이 자동으로 해당 캘린더에 일정으로 추가됩니다.';

  @override
  String get integrationsOff => '끄기';

  @override
  String get integrationsPermissionDenied =>
      '캘린더 접근 권한이 허용되지 않았습니다. 시스템 설정 앱에서 허용할 수 있어요.';

  @override
  String get integrationsNoCalendars =>
      '이 기기에서 쓰기 가능한 캘린더를 찾을 수 없습니다. 시스템 설정 앱에서 캘린더(예: Google 계정)를 추가한 후 새로고침하세요.';

  @override
  String get integrationsRefresh => '새로고침';

  @override
  String get appleRemindersSettingsTitle => '미리 알림';

  @override
  String get appleRemindersScreenTitle => '미리 알림 연동';

  @override
  String get appleRemindersDescription =>
      '기기의 미리 알림 앱에서 목록을 선택하세요. 켜두면 마감일이 있는 할 일이 자동으로 그곳에 추가되고, 앱에서 완료 처리하면 미리 알림에서도 완료로 표시됩니다.';

  @override
  String get appleRemindersPermissionDenied =>
      '미리 알림 접근 권한이 허용되지 않았습니다. 시스템 설정 앱에서 허용할 수 있어요.';

  @override
  String get appleRemindersNoLists =>
      '쓰기 가능한 미리 알림 목록을 찾을 수 없습니다. 미리 알림 앱에서 목록을 만든 후 새로고침하세요.';

  @override
  String get accountSectionTitle => '계정';

  @override
  String accountSignedInAs(String email) {
    return '$email(으)로 로그인됨';
  }

  @override
  String get accountNotSignedIn => '로그인되지 않음';

  @override
  String get accountNotSignedInDescription =>
      'Google 또는 Apple로 로그인하면 일기 데이터를 다른 기기로 옮길 수 있어요';

  @override
  String get accountScreenTitle => '계정';

  @override
  String get accountSignInWithGoogle => 'Google로 로그인';

  @override
  String get accountSignInWithApple => 'Apple로 로그인';

  @override
  String get accountSignOutButton => '로그아웃';

  @override
  String get accountRestoreButton => '클라우드에서 복원';

  @override
  String get watchPairingButton => 'Apple Watch 페어링';

  @override
  String get watchPairingSuccessTitle => '페어링됨';

  @override
  String get watchPairingSuccessMessage =>
      'Apple Watch가 페어링되었습니다. 이제 Watch만으로도 녹음할 수 있어요.';

  @override
  String get syncErrorBannerMessage => '일부 데이터 동기화에 실패했습니다';

  @override
  String get syncErrorBannerAction => '확인';

  @override
  String get loadErrorBannerMessage => '데이터를 불러오지 못했습니다';

  @override
  String get loadErrorBannerAction => '다시 시도';

  @override
  String get mediaStorageWarningBannerMessage => '사진/동영상 클라우드 저장 공간이 거의 다 찼습니다';

  @override
  String get mediaStorageFullBannerMessage =>
      '사진/동영상 클라우드 저장 공간이 가득 찼습니다. 새 사진과 동영상은 동기화되지 않아요';

  @override
  String get mediaStorageBannerAction => '정리하기';

  @override
  String get accountSyncingMessage => '동기화 중…';

  @override
  String get accountSyncCompleteTitle => '완료';

  @override
  String get accountSyncCompleteMessage => '동기화가 완료되었습니다.';

  @override
  String get accountErrorTitle => '오류';

  @override
  String get accountErrorNetwork => '네트워크 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get accountErrorUnknown => '문제가 발생했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get accountSignOutConfirmTitle => '로그아웃할까요?';

  @override
  String get accountSignOutConfirmMessage =>
      '이 기기의 데이터는 삭제되지 않아요. 언제든 다시 로그인하면 동기화를 이어갈 수 있습니다.';

  @override
  String get accountDeleteButton => '계정 삭제';

  @override
  String get accountDeleteConfirmTitle => '계정을 삭제할까요?';

  @override
  String get accountDeleteConfirmMessage =>
      '이 작업은 되돌릴 수 없습니다. 클라우드에 저장된 일기·아이디어·할 일, 사진과 동영상, 그리고 이 기기의 모든 데이터가 영구적으로 삭제됩니다.';

  @override
  String get accountDeleteConfirmButton => '삭제';

  @override
  String get accountDeleteCompleteTitle => '삭제됨';

  @override
  String get accountDeleteCompleteMessage => '계정과 모든 데이터가 삭제되었습니다.';

  @override
  String get accountMediaSyncFreeNote =>
      '텍스트(일기·아이디어·할 일)만 백업됩니다. 사진과 동영상은 클라우드에 동기화되지 않으며, 이는 월간/연간 플랜에서만 제공됩니다(평생 플랜에는 포함되지 않음).';

  @override
  String get accountMediaSyncProNote => '사진과 동영상도 클라우드에 백업됩니다.';

  @override
  String get supportSectionTitle => '지원';

  @override
  String get contactSupportTitle => '문의하기';

  @override
  String get contactSupportEmailSubject => 'Voice Brain 고객 지원';

  @override
  String get planSectionTitle => '플랜';

  @override
  String get planCurrentTitle => '현재 플랜';

  @override
  String get planProTitle => 'Pro 플랜';

  @override
  String get planFreeTitle => '무료 플랜';

  @override
  String get planProSubtitle => '1회 최대 15분, 하루 30회 녹음';

  @override
  String get planFreeSubtitle => '1회 최대 60초, 하루 3회 무료 녹음';

  @override
  String get planManage => '관리';

  @override
  String get planUpgrade => '업그레이드';

  @override
  String get paywallTitle => 'Pro 플랜';

  @override
  String get paywallSectionTitle => 'Pro로 열리는 기능';

  @override
  String get paywallSectionSubtitle => '모든 Pro 기능을 무제한으로 이용';

  @override
  String get paywallBenefitDurationTitle => '더 긴 녹음';

  @override
  String get paywallBenefitDurationBefore => '60초';

  @override
  String get paywallBenefitDurationAfter => '15분';

  @override
  String get paywallBenefitDurationDesc => '디테일을 놓치지 않고 원하는 만큼 이야기하세요';

  @override
  String get paywallBenefitCountTitle => '하루 더 많은 사용 횟수';

  @override
  String get paywallBenefitCountBefore => '3회/일';

  @override
  String get paywallBenefitCountAfter => '30회/일';

  @override
  String get paywallBenefitCountDesc => '떠오르는 순간마다 모든 생각을 기록하세요';

  @override
  String get paywallMonthlyCapNote =>
      '* 총 녹음 시간은 월 240분으로 제한됩니다. 한도에 도달하면 추가 녹음 팩을 구매해 계속 이용할 수 있어요.';

  @override
  String get paywallBenefitCustomBackgroundTitle => '직접 찍은 ';

  @override
  String get paywallBenefitCustomBackgroundHighlight => '사진 추가';

  @override
  String get paywallBenefitCustomBackgroundDesc => '모든 기록을 나만의 것처럼 느껴지게';

  @override
  String get paywallBenefitImageLayoutTitle => '사진을 자유롭게 배치';

  @override
  String get paywallBenefitImageLayoutDesc => '드래그로 위치 이동, 슬라이더로 크기 조절';

  @override
  String get paywallBenefitKnowledgeBaseHighlight => '질문(두 번째 뇌)';

  @override
  String get paywallBenefitKnowledgeBaseSuffix => ' 잠금 해제';

  @override
  String get paywallBenefitKnowledgeBaseDesc => 'AI가 그동안 기록한 모든 내용을 찾아 도와드려요';

  @override
  String get paywallBenefitWeeklyReportTitle => '주간 두뇌 리포트';

  @override
  String get paywallBenefitWeeklyReportDesc => 'AI가 한 주를 읽고 핵심만 전해드려요';

  @override
  String get paywallBenefitMediaSyncTitle => '사진·동영상 클라우드 동기화';

  @override
  String get paywallBenefitMediaSyncDesc => '소중한 순간들을 안전하게 백업해두세요';

  @override
  String get paywallBenefitMediaSyncBadge => '월간/연간 플랜 전용';

  @override
  String get paywallUnavailable => '지금은 플랜을 불러올 수 없습니다. 나중에 다시 시도해 주세요.';

  @override
  String get paywallRestore => '구매 복원';

  @override
  String get paywallTerms => '이용약관';

  @override
  String get paywallPrivacy => '개인정보처리방침';

  @override
  String get paywallPurchaseFailed => '문제가 발생했습니다. 나중에 다시 시도해 주세요.';

  @override
  String get paywallRestoreNotFound => '복원할 수 있는 구매 내역이 없습니다.';

  @override
  String get paywallPlanMonthly => '월간';

  @override
  String get paywallPlanAnnual => '연간';

  @override
  String get paywallPlanLifetime => '평생';

  @override
  String get paywallPlanRecommended => '추천';

  @override
  String get paywallPlanLifetimeCaption => '사진/동영상 클라우드 동기화 미포함';

  @override
  String get paywallPlanComingSoon => '출시 예정';

  @override
  String get paywallContinueButton => '계속';

  @override
  String homeUsageToday(int used, int limit) {
    return '오늘 $used / $limit';
  }

  @override
  String homeUsageMonth(int usedMinutes, int limitMinutes) {
    return '이번 달 $usedMinutes / $limitMinutes분';
  }

  @override
  String get buyMinutesCta => '추가 분 구매';

  @override
  String get buyMinutesTitle => '추가 분 구매하기';

  @override
  String get buyMinutesDescription =>
      '이번 달 녹음 시간 한도에 도달했습니다. 추가 분 팩을 구매하면 다음 달까지 기다리지 않고 바로 녹음을 이어갈 수 있어요.';

  @override
  String get buyMinutesDescriptionProactive =>
      'Pro 및 평생 플랜에는 월 240분의 녹음 시간이 포함되어 있어요. 한도에 도달할 경우를 대비해 60분 추가 팩을 미리 구매해둘 수도 있습니다.';

  @override
  String get buyMinutesUnavailable => '지금은 추가 분 팩을 이용할 수 없습니다. 나중에 다시 시도해 주세요.';

  @override
  String get buyMinutesPurchaseFailed => '구매에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get buyMinutesPurchaseSuccess => '추가 분이 적립되었습니다. 이제 계속 녹음할 수 있어요.';

  @override
  String buyMinutesPurchaseButton(String price) {
    return '+60분 구매($price)';
  }

  @override
  String get notificationSectionTitle => '알림';

  @override
  String get reminderNotificationsTitle => '리마인더 알림';

  @override
  String get notificationCheckingStatus => '확인 중…';

  @override
  String get notificationGranted => '허용됨';

  @override
  String get notificationDenied => '허용되지 않음(리마인더가 전달되지 않습니다)';

  @override
  String get allow => '허용';

  @override
  String get notificationPermissionDialogTitle => '알림이 허용되지 않았습니다';

  @override
  String get notificationPermissionDialogMessage =>
      '리마인더를 받으려면 알림을 허용해 주세요. 설정 앱에서 변경할 수 있어요.';

  @override
  String get openSettings => '설정 열기';

  @override
  String get customDictionaryTitle => '사용자 사전';

  @override
  String get customDictionaryDescription =>
      '친구나 그룹 이름, 전문 용어를 등록하면 음성 인식 시 우선적으로 인식됩니다. 메모를 추가하면 AI가 오타를 찾아 수정하는 데도 도움이 됩니다.';

  @override
  String get wordLabel => '단어';

  @override
  String get wordHint => '예: 김철수';

  @override
  String get descriptionLabelOptional => '설명(선택)';

  @override
  String get descriptionHint => '예: 대학교 친구';

  @override
  String get add => '추가';

  @override
  String get customDictionaryEmpty => '등록된 단어가 아직 없습니다';

  @override
  String get diaryDayEmpty => '이 날의 일기가 없습니다';

  @override
  String get diaryPickDateTooltip => '날짜 선택';

  @override
  String get diaryPreviousWeekTooltip => '지난주';

  @override
  String get diaryNextWeekTooltip => '다음 주';

  @override
  String get fontStandard => '기본';

  @override
  String get fontMincho => '명조체';

  @override
  String get fontHandwriting => '손글씨';

  @override
  String get fontPop => '팝';

  @override
  String get fontMonospace => '고정폭';

  @override
  String get fontGothic => '고딕체';

  @override
  String get fontRoundGothic => '둥근 고딕';

  @override
  String get fontThinMincho => '얇은 명조체';

  @override
  String get fontBrush => '붓글씨';

  @override
  String get fontRetro => '레트로';

  @override
  String get fontImpact => '임팩트';

  @override
  String get fontCute => '귀여운체';

  @override
  String mediaPickFailed(String error) {
    return '사진/동영상 선택에 실패했습니다: $error';
  }

  @override
  String get pickPhotosFromLibrary => '사진 선택';

  @override
  String get pickPhotosFromLibrarySubtitle => '라이브러리에서 추가할 사진을 선택하세요';

  @override
  String get pickVideoFromLibrary => '동영상 선택';

  @override
  String get pickVideoFromLibrarySubtitle => '라이브러리에서 추가할 동영상을 선택하세요';

  @override
  String get backgroundSheetTitle => '배경';

  @override
  String get backgroundNone => '없음';

  @override
  String get emotionSheetTitle => '감정';

  @override
  String get emotionNone => '없음';

  @override
  String get comingSoon => '출시 예정';

  @override
  String get diaryBgFruit => '과일';

  @override
  String get diaryBgMintPlant => '식물 노트';

  @override
  String get diaryBgCoffee => '커피';

  @override
  String get diaryBgCake => '케이크';

  @override
  String get diaryBgPicnic => '빵 바구니';

  @override
  String get diaryBgHeartBalloon => '하트 풍선';

  @override
  String get diaryBgParkDay => '민들레 들판';

  @override
  String get diaryBgNightSky => '밤하늘';

  @override
  String get diaryBgSleepingCat => '잠자는 고양이';

  @override
  String get diaryBgBlueCheckBouquet => '파란 체크 꽃다발';

  @override
  String get diaryBgVintageCamera => '빈티지 카메라';

  @override
  String get diaryBgShopping => '쇼핑';

  @override
  String get diaryBgNewYork => '뉴욕';

  @override
  String get diaryBgBeach => '해변';

  @override
  String get diaryBgPalmTree => '야자수';

  @override
  String get diaryBgEuropeanStreet => '유럽 거리';

  @override
  String get diaryBgRunning => '러닝';

  @override
  String get diaryBgLivingRoom => '거실';

  @override
  String get diaryBgMusicNote => '음표';

  @override
  String get diaryBgLetter => '편지';

  @override
  String get diaryBgDeepSea => '심해';

  @override
  String get diaryBgSnow => '눈';

  @override
  String get diaryBgSoccerBall => '축구공';

  @override
  String get diaryBgLuxuryFrame => '럭셔리 프레임';

  @override
  String get diaryBgClock => '시계';

  @override
  String get fontSheetTitle => '글꼴';

  @override
  String get fontSheetSizeLabel => '제목 크기';

  @override
  String get fontSheetColorLabel => '글자 색상';

  @override
  String get fontSheetStyleLabel => '글꼴 스타일';

  @override
  String get closeTooltip => '닫기';

  @override
  String get favoriteSettingsTooltip => '즐겨찾는 설정';

  @override
  String get favoriteSettingsSheetTitle => '즐겨찾는 설정';

  @override
  String get favoriteSettingsDescription => '새로 만드는 일기에 기본으로 적용되는 글자 스타일과 배경';

  @override
  String get addCustomBackgroundTile => '직접 찍은 사진 추가';

  @override
  String get toolbarMedia => '사진/동영상';

  @override
  String get toolbarBackground => '배경';

  @override
  String get toolbarText => '텍스트';

  @override
  String get titleHint => '제목';

  @override
  String get bodyHint => '여기에 더 자세히 적어보세요…';

  @override
  String get filterAll => '전체';

  @override
  String get filterToday => '오늘';

  @override
  String get filterThisWeek => '이번 주';

  @override
  String get filterWithinMonth => '한 달 이내';

  @override
  String get filterCompleted => '완료됨';

  @override
  String get tasksEmpty => '아직 할 일이 없어요\n\"~해야 해\"라고 말해보세요';

  @override
  String get tasksFilterEmpty => '이 필터에 해당하는 할 일이 없습니다';

  @override
  String get reminderLabel => '알림 리마인더';

  @override
  String get removeReminderTooltip => '리마인더 삭제';

  @override
  String get addReminder => '리마인더 추가';

  @override
  String get taskContentHint => '할 일 내용';

  @override
  String get allDayLabel => '종일';

  @override
  String get taskScheduleLabel => '시작 및 종료 시간';

  @override
  String get startTimeCaption => '시작';

  @override
  String get endTimeCaption => '종료';

  @override
  String get addStartTime => '시작 시간 설정';

  @override
  String get removeStartTimeTooltip => '시작 시간 삭제';

  @override
  String get addEndTime => '종료 시간 추가';

  @override
  String get removeEndTimeTooltip => '종료 시간 삭제';

  @override
  String get manualTaskFabTooltip => '할 일 추가';

  @override
  String get manualTaskScreenTitle => '할 일 추가';

  @override
  String get manualTaskTitleHint => '할 일(예: 우유 사기)';

  @override
  String get manualTaskTitleRequiredError => '할 일을 입력해 주세요';

  @override
  String get manualDiaryFabTooltip => '일기 추가';

  @override
  String get manualDiaryScreenTitle => '일기 추가';

  @override
  String get manualDiaryTitleHint => '제목(선택)';

  @override
  String get manualDiaryContentHint => '오늘 하루는 어땠나요?';

  @override
  String get manualDiaryContentRequiredError => '내용을 입력해 주세요';

  @override
  String get manualIdeaFabTooltip => '아이디어 추가';

  @override
  String get manualIdeaScreenTitle => '아이디어 추가';

  @override
  String get manualIdeaTitleHint => '제목(선택)';

  @override
  String get manualIdeaContentHint => '아이디어 내용';

  @override
  String get manualIdeaContentRequiredError => '내용을 입력해 주세요';

  @override
  String get ideasEmpty => '아직 아이디어가 없어요\n떠오르는 생각을 말해보세요';

  @override
  String get editIdeaTitle => '아이디어 수정';

  @override
  String get ideaTitleHint => '제목(선택)';

  @override
  String get ideaContentHint => '아이디어 내용';

  @override
  String get ideaStatusConsidering => '검토 중';

  @override
  String get ideaStatusAdopted => '채택됨';

  @override
  String get ideaStatusRejected => '기각됨';

  @override
  String get ideaStatusNone => '상태 없음';

  @override
  String get ideaStatusLabel => '상태';

  @override
  String get ideaTagLabel => '태그';

  @override
  String get ideaTagHint => '태그(선택)';

  @override
  String get ideaSearchHint => '아이디어 검색';

  @override
  String get ideaPinTooltip => '고정';

  @override
  String get ideaUnpinTooltip => '고정 해제';

  @override
  String get ideaSortNewestFirstTooltip => '최신순 정렬(탭하면 오래된순)';

  @override
  String get ideaSortOldestFirstTooltip => '오래된순 정렬(탭하면 최신순)';

  @override
  String get ideasFilterEmpty => '이 필터에 해당하는 아이디어가 없습니다';

  @override
  String get reviewTitle => '내용 검토';

  @override
  String get reviewDescription =>
      '내용이 틀렸다면 텍스트를 수정하세요. 카드를 드래그하면 일기·아이디어·할 일 사이로 옮길 수 있어요.';

  @override
  String get reviewDescriptionNoDrag => '내용이 틀렸다면 텍스트를 수정하세요';

  @override
  String get sectionDiary => '일기';

  @override
  String get sectionIdea => '아이디어';

  @override
  String get sectionTask => '할 일';

  @override
  String get sectionEmptyPlaceholder => '아직 내용이 없습니다';

  @override
  String get discard => '취소';

  @override
  String get dragCardHere => '카드를 여기로 드래그하세요';

  @override
  String get addCardButton => '카드 추가';

  @override
  String get genericProcessingError => '처리 중 오류가 발생했습니다';

  @override
  String get usageFetchError => '이용 현황을 불러오지 못했습니다';

  @override
  String get watchNotPairedMessage =>
      'Apple Watch가 페어링되어 있지 않습니다. Watch를 가까이 두고 Apple의 Watch 앱에서 먼저 페어링을 완료해 주세요.';

  @override
  String get backgroundRecordingChannelName => '백그라운드 녹음';

  @override
  String get backgroundRecordingChannelDescription =>
      '앱이 백그라운드에 있거나 화면이 꺼져 있어도 녹음이 계속되도록 유지합니다';

  @override
  String get backgroundRecordingNotificationTitle => '녹음 중…';

  @override
  String get backgroundRecordingNotificationText => '탭하여 앱으로 돌아가기';

  @override
  String get reminderNotificationTitle => '리마인더';

  @override
  String get reminderNotificationChannelName => '할 일 리마인더';

  @override
  String get reminderNotificationChannelDescription =>
      '음성 메모로 만든 할 일의 시간 기반 리마인더';

  @override
  String get weeklyReportNotificationTitle => '주간 두뇌 리포트가 도착했어요!';

  @override
  String get weeklyReportNotificationBody => 'AI가 이번 주를 돌아봤어요. 탭해서 확인해보세요.';

  @override
  String get weeklyReportNotificationChannelName => '주간 리포트 알림';

  @override
  String get weeklyReportNotificationChannelDescription =>
      '매주 일요일 오후 8시, 주간 두뇌 리포트가 준비되면 알려드려요';

  @override
  String get weeklyReportHistoryTooltip => '지난 리포트';

  @override
  String get weeklyReportHistoryTitle => '주간 리포트 기록';

  @override
  String get weeklyReportHistoryEmpty => '아직 저장된 리포트가 없습니다';

  @override
  String get knowledgeBaseTitle => '두 번째 뇌';

  @override
  String get knowledgeBaseDescription =>
      'AI가 지금까지의 일기·아이디어·할 일을 모두 살펴보고 답해드려요.';

  @override
  String get knowledgeBaseInputHint => '예: 지난달에 말했던 그 앱 아이디어가 뭐였지?';

  @override
  String get knowledgeBaseSend => '전송';

  @override
  String get knowledgeBaseThinking => '과거 기록을 살펴보고 있어요…';

  @override
  String get knowledgeBaseEmpty => '아직 기록이 없습니다. 먼저 녹음한 후 다시 질문해 보세요.';

  @override
  String get knowledgeBaseErrorTitle => '답변을 가져오지 못했습니다';

  @override
  String get knowledgeBaseProLockedDescription =>
      '모든 기록을 넘나드는 AI 채팅은 Pro 전용 기능입니다. 업그레이드하면 이용할 수 있어요.';

  @override
  String get knowledgeBaseSourcesLabel => '참조한 기록';

  @override
  String get knowledgeBaseSourceSheetTitle => '이 답변이 참조한 기록';

  @override
  String get knowledgeBaseSourceNotFound => '이 기록을 찾을 수 없습니다';

  @override
  String get knowledgeBaseSignInNudgeText =>
      '계정을 연결하면 과거 기록을 근거로 더 정확하게 답변받을 수 있어요.';

  @override
  String get knowledgeBaseSignInNudgeCta => '계정 연결';

  @override
  String get knowledgeBaseVoiceQuestion => '음성으로 질문';

  @override
  String get knowledgeBaseRecordingQuestion => '질문을 녹음하고 있어요…';

  @override
  String get knowledgeBaseTranscribing => '텍스트로 변환하고 있어요…';

  @override
  String get knowledgeBasePlayAnswer => '답변 재생';

  @override
  String get knowledgeBaseStopAnswer => '재생 중지';

  @override
  String get weeklyReportSettingsTitle => '주간 두뇌 리포트';

  @override
  String get weeklyReportSettingsSubtitle => '매주 전달돼요';

  @override
  String get weeklyReportTitle => '주간 두뇌 리포트';

  @override
  String get weeklyReportProLockedDescription =>
      '주간 두뇌 리포트는 Pro 전용 기능입니다. 업그레이드하면 이용할 수 있어요.';

  @override
  String get weeklyReportRetry => '다시 시도';

  @override
  String get weeklyReportLoadingInsights => 'AI가 이번 주를 되돌아보고 있어요…';

  @override
  String get weeklyReportErrorTitle => '리포트를 불러오지 못했습니다';

  @override
  String get weeklyReportEmotionSectionTitle => '감정 경향';

  @override
  String get weeklyReportNoEmotionData => '이번 주는 아직 감정 기록이 없어요';

  @override
  String get weeklyReportConstellationSectionTitle => '감정 그래프';

  @override
  String get weeklyReportCategorySectionTitle => '카테고리 비율';

  @override
  String get weeklyReportNoCategoryData => '이번 주는 아직 기록이 없어요';

  @override
  String get weeklyReportKeywordsSectionTitle => '브레인 맵';

  @override
  String get weeklyReportBrainMapSubtitle => '이번 주가 긍정·보통·부정 감정으로 어떻게 나뉘었는지';

  @override
  String get weeklyReportWordsSectionTitle => '이번 주의 단어';

  @override
  String get weeklyReportWordsEmpty => '아직 눈에 띄는 단어가 없어요';

  @override
  String get weeklyReportWordDetailEmpty => '이 단어가 언급된 기록을 찾을 수 없습니다';

  @override
  String get emotionCategoryPositive => '긍정';

  @override
  String get emotionCategoryNormal => '보통';

  @override
  String get emotionCategoryNegative => '부정';

  @override
  String get weeklyReportIdeasSectionTitle => '빛났던 아이디어';

  @override
  String get weeklyReportNoIdeas => '이번 주는 아직 기록된 아이디어가 없어요';

  @override
  String get weeklyReportHighlightSectionTitle => '이번 주의 하이라이트';

  @override
  String get weeklyReportNoHighlight => '이번 주는 아직 일기가 없어요';

  @override
  String get weeklyReportAchievementSectionTitle => '이번 주의 성과';

  @override
  String weeklyReportTasksCompleted(int count) {
    return '할 일 $count개 완료';
  }

  @override
  String weeklyReportDiaryCount(int count) {
    return '일기 $count개';
  }

  @override
  String get weeklyReportEncouragement => '이번 주도 정말 잘했어요!';

  @override
  String get weeklyReportAdviceSectionTitle => '다음 주를 위한 조언';

  @override
  String get weeklyReportLetterSectionTitle => '이번 주의 편지';

  @override
  String get weeklyReportLetterLocked =>
      '이번 주의 편지는 일요일 오후 8시에 도착해요. 그때까지는 작은 비밀로 남겨둘게요.';

  @override
  String get weeklyReportShareTooltip => '이미지로 공유';

  @override
  String get weeklyReportShareCaption => '제 한 주는 이랬어요 📝 #VoiceBrain';
}
