// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navRecord => '録音';

  @override
  String get navDiary => '日記';

  @override
  String get navIdea => 'アイデア';

  @override
  String get navTask => 'タスク';

  @override
  String get navKnowledgeBase => '相談';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingGetStarted => 'はじめる';

  @override
  String get onboardingCreateAccount => 'アカウントを作成する（あとで設定からも可能）';

  @override
  String get onboardingPage1Title => '思いついた瞬間に、\nつぶやくだけ';

  @override
  String get onboardingPage1Body => '録音ボタンをタップして話すだけで、VoiceJournalが記録してくれます';

  @override
  String get onboardingPage2Title => 'AIが自動で仕分けします';

  @override
  String get onboardingPage2Body => '話した内容から、日記・アイデア・タスクに自動で振り分けます';

  @override
  String get onboardingPage3Title => 'さあ、はじめましょう';

  @override
  String get onboardingPage3Body => '気になったことがあれば、いつでもタップして話しかけてください';

  @override
  String get emotionFatigue => '疲れた';

  @override
  String get emotionLove => '好き';

  @override
  String get emotionAnxious => '不安';

  @override
  String get emotionExcited => 'ドキドキ';

  @override
  String get emotionJoy => '楽しい';

  @override
  String get emotionSadness => '悲しい';

  @override
  String get emotionAnger => '怒り';

  @override
  String get emotionSatisfaction => '満足';

  @override
  String get emotionNeutral => '普通';

  @override
  String get emotionGratitude => '感謝';

  @override
  String get emotionHappy => '嬉しい';

  @override
  String get emotionFunny => '面白い';

  @override
  String get emotionRelief => '安心';

  @override
  String get emotionCalm => '穏やか';

  @override
  String get emotionBoredom => '退屈';

  @override
  String get emotionRegret => '後悔';

  @override
  String get emotionDislike => '嫌い';

  @override
  String get confirmDeleteTitle => '削除しますか？';

  @override
  String get confirmDeleteMessage => 'この記録を削除すると元に戻せません。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get save => '保存';

  @override
  String get editTooltip => '編集';

  @override
  String get micPermissionDenied => 'マイクの使用が許可されていません';

  @override
  String get recordingStopFailedTitle => '録音の停止に失敗しました';

  @override
  String get recordingErrorTitle => '録音エラー';

  @override
  String get recordingSaveFailed => '録音の保存に失敗しました';

  @override
  String get processingErrorTitle => '処理中にエラーが発生しました';

  @override
  String statusError(String message) {
    return 'エラー: $message';
  }

  @override
  String statusOrganized(String summary) {
    return '整理しました：$summary';
  }

  @override
  String get statusTapToRecord => 'タップして録音開始';

  @override
  String get statusRecording => '録音中… もう一度タップで停止';

  @override
  String get statusProcessing => 'AIが解析中です…';

  @override
  String maxRecordingSeconds(int seconds) {
    return '1回の録音は最大$seconds秒です';
  }

  @override
  String maxRecordingMinutes(int minutes) {
    return '1回の録音は最大$minutes分です';
  }

  @override
  String get textComposeTooltip => 'テキストで入力';

  @override
  String get settingsTooltip => '設定';

  @override
  String get menuCustomDictionary => 'カスタム辞書';

  @override
  String get menuSummaryLevel => 'AIの要約度';

  @override
  String get textComposerTitle => 'テキストで入力';

  @override
  String get textComposerDescription =>
      '話せない時はこちらに入力してください。内容は録音と同じようにAIが日記かタスクかアイデアかを判断します。';

  @override
  String get textComposerHint => '例: 明日15時に歯医者の予約を入れる';

  @override
  String get textComposerSubmit => 'AIに解析してもらう';

  @override
  String get summaryLevelSheetTitle => 'AIの要約度';

  @override
  String get summaryLevelSheetDescription =>
      '録音・テキストの内容を日記として仕分けるとき、AIがどれくらい短くまとめるかを選べます。タスクの簡潔さには影響しません。';

  @override
  String get summaryLevelPreserveLabel => '原型重視';

  @override
  String get summaryLevelStandardLabel => '標準';

  @override
  String get summaryLevelCompactLabel => '超コンパクト';

  @override
  String get summaryLevelPreserveDescription => '要約・圧縮せず、感情や言い回し、固有名詞をそのまま残します';

  @override
  String get summaryLevelStandardDescription => '冗長な繰り返しだけ整理し、日記らしい自然な長さを保ちます';

  @override
  String get summaryLevelCompactDescription => '核心だけを1〜2文程度にぎゅっと短くまとめます';

  @override
  String get settingsTitle => '設定';

  @override
  String get displaySectionTitle => '表示';

  @override
  String get darkModeTitle => 'ダークモード';

  @override
  String get darkModeSubtitle => '目にやさしい表示に切り替えます';

  @override
  String get settingsProBadge => 'Pro限定';

  @override
  String get integrationsSettingsTitle => '連携';

  @override
  String get integrationsCalendarRowTitle => '連携カレンダー';

  @override
  String get integrationsScreenTitle => '連携';

  @override
  String get integrationsDescription =>
      '端末にすでに登録されているカレンダー（iOS標準カレンダーや、設定アプリで追加したGoogleアカウントなど）から連携先を選べます。ONにすると、日時が確定したタスクが自動でそのカレンダーに予定として登録されます。';

  @override
  String get integrationsOff => '連携しない';

  @override
  String get integrationsPermissionDenied =>
      'カレンダーへのアクセスが許可されていません。設定アプリから許可できます。';

  @override
  String get integrationsNoCalendars =>
      '書き込み可能なカレンダーが端末に見つかりませんでした。設定アプリでGoogleアカウントなどのカレンダーを追加してから、再読み込みしてください。';

  @override
  String get integrationsRefresh => '再読み込み';

  @override
  String get appleRemindersSettingsTitle => 'リマインダー';

  @override
  String get appleRemindersScreenTitle => 'リマインダー連携';

  @override
  String get appleRemindersDescription =>
      '端末の「リマインダー」アプリにあるリストから連携先を選べます。ONにすると、期限が確定したタスクが自動でそのリストに登録され、アプリ側で完了にするとリマインダー側でも完了扱いになります。';

  @override
  String get appleRemindersPermissionDenied =>
      'リマインダーへのアクセスが許可されていません。設定アプリから許可できます。';

  @override
  String get appleRemindersNoLists =>
      '書き込み可能なリマインダーリストが見つかりませんでした。リマインダーアプリでリストを作成してから、再読み込みしてください。';

  @override
  String get accountSectionTitle => 'アカウント';

  @override
  String accountSignedInAs(String email) {
    return '$email でログイン中';
  }

  @override
  String get accountNotSignedIn => 'ログインしていません';

  @override
  String get accountNotSignedInDescription =>
      'Google/Appleアカウントでログインすると、他の端末でも同じ日記データを引き継げます';

  @override
  String get accountScreenTitle => 'アカウント';

  @override
  String get accountSignInWithGoogle => 'Googleでサインイン';

  @override
  String get accountSignInWithApple => 'Appleでサインイン';

  @override
  String get accountSignOutButton => 'ログアウト';

  @override
  String get accountRestoreButton => 'クラウドから復元';

  @override
  String get watchPairingButton => 'Apple Watchをペアリング';

  @override
  String get watchPairingSuccessTitle => 'ペアリングしました';

  @override
  String get watchPairingSuccessMessage =>
      'Apple Watchとのペアリングが完了しました。Watch単体で録音できます。';

  @override
  String get syncErrorBannerMessage => '一部のデータの同期に失敗しました';

  @override
  String get syncErrorBannerAction => '確認する';

  @override
  String get loadErrorBannerMessage => 'データの読み込みに失敗しました';

  @override
  String get loadErrorBannerAction => '再試行';

  @override
  String get mediaStorageWarningBannerMessage => '写真・動画のクラウド容量がそろそろ上限です';

  @override
  String get mediaStorageFullBannerMessage =>
      '写真・動画のクラウド容量が上限に達しました。新しい写真・動画は同期されません';

  @override
  String get mediaStorageBannerAction => '整理する';

  @override
  String get accountSyncingMessage => '同期中です…';

  @override
  String get accountSyncCompleteTitle => '完了しました';

  @override
  String get accountSyncCompleteMessage => 'データの同期が完了しました。';

  @override
  String get accountErrorTitle => 'エラー';

  @override
  String get accountErrorNetwork => '通信エラーが発生しました。しばらくしてから再度お試しください。';

  @override
  String get accountErrorUnknown => 'エラーが発生しました。しばらくしてから再度お試しください。';

  @override
  String get accountSignOutConfirmTitle => 'ログアウトしますか？';

  @override
  String get accountSignOutConfirmMessage =>
      '端末内のデータは削除されません。再度ログインすると同期を再開できます。';

  @override
  String get accountMediaSyncFreeNote =>
      'バックアップされるのは日記・アイデア・タスクのテキストのみです。写真・動画はクラウドに同期されません（月額/年額プラン限定機能、買い切りプランは対象外）。';

  @override
  String get accountMediaSyncProNote => '写真・動画もクラウドにバックアップされます。';

  @override
  String get supportSectionTitle => 'サポート';

  @override
  String get contactSupportTitle => 'お問い合わせ';

  @override
  String get contactSupportEmailSubject => 'VoiceJournalへのお問い合わせ';

  @override
  String get planSectionTitle => 'プラン';

  @override
  String get planCurrentTitle => '現在のプラン';

  @override
  String get planProTitle => 'Proプラン';

  @override
  String get planFreeTitle => '無料プラン';

  @override
  String get planProSubtitle => '録音15分・1日30回まで利用できます';

  @override
  String get planFreeSubtitle => '録音60秒・1日3回まで無料で利用できます';

  @override
  String get planManage => '管理する';

  @override
  String get planUpgrade => 'アップグレード';

  @override
  String get paywallTitle => 'Proプラン';

  @override
  String get paywallSectionTitle => 'Proプランでできること';

  @override
  String get paywallSectionSubtitle => 'すべてのPro機能が使い放題';

  @override
  String get paywallBenefitDurationTitle => '録音時間が長く';

  @override
  String get paywallBenefitDurationBefore => '60秒';

  @override
  String get paywallBenefitDurationAfter => '15分';

  @override
  String get paywallBenefitDurationDesc => 'じっくり話せて、細かいニュアンスも逃さない';

  @override
  String get paywallBenefitCountTitle => '1日の利用回数が多く';

  @override
  String get paywallBenefitCountBefore => '3回';

  @override
  String get paywallBenefitCountAfter => '30回';

  @override
  String get paywallBenefitCountDesc => '思いついた時に、いつでもたくさん使える';

  @override
  String get paywallBenefitCustomBackgroundTitle => '日記背景に';

  @override
  String get paywallBenefitCustomBackgroundHighlight => '自分の画像を追加';

  @override
  String get paywallBenefitCustomBackgroundDesc => 'お気に入りの写真で、あなただけの特別な日記に';

  @override
  String get paywallBenefitKnowledgeBaseHighlight => '相談（第二の脳）';

  @override
  String get paywallBenefitKnowledgeBaseSuffix => 'が使える';

  @override
  String get paywallBenefitKnowledgeBaseDesc => '過去の記録を横断して、AIが深くサポート';

  @override
  String get paywallBenefitWeeklyReportTitle => '週刊脳内レポート';

  @override
  String get paywallBenefitWeeklyReportDesc => '毎週あなたの心の傾向をAIが分析・お届け';

  @override
  String get paywallBenefitMediaSyncTitle => '写真・動画のクラウド同期';

  @override
  String get paywallBenefitMediaSyncDesc => '大切な思い出を、安全にバックアップ';

  @override
  String get paywallBenefitMediaSyncBadge => '月額・年額プラン限定';

  @override
  String get paywallUnavailable => '現在プランを取得できません。しばらくしてからもう一度お試しください。';

  @override
  String get paywallRestore => '購入を復元';

  @override
  String get paywallTerms => '利用規約';

  @override
  String get paywallPrivacy => 'プライバシーポリシー';

  @override
  String get paywallPurchaseFailed => '処理に失敗しました。時間をおいて再度お試しください。';

  @override
  String get paywallRestoreNotFound => '復元できる購入が見つかりませんでした。';

  @override
  String get paywallPlanMonthly => '月額プラン';

  @override
  String get paywallPlanAnnual => '年額プラン';

  @override
  String get paywallPlanLifetime => '買い切りプラン';

  @override
  String get paywallPlanRecommended => 'おすすめ';

  @override
  String get paywallPlanLifetimeCaption => '写真・動画のクラウド同期以外は使い放題';

  @override
  String get paywallPlanComingSoon => '近日公開';

  @override
  String get paywallContinueButton => '続ける';

  @override
  String homeUsageToday(int used, int limit) {
    return '本日 $used / $limit回';
  }

  @override
  String get notificationSectionTitle => '通知';

  @override
  String get reminderNotificationsTitle => 'リマインダー通知';

  @override
  String get notificationCheckingStatus => '確認中…';

  @override
  String get notificationGranted => '許可されています';

  @override
  String get notificationDenied => '許可されていません（リマインダーが届きません）';

  @override
  String get allow => '許可する';

  @override
  String get notificationPermissionDialogTitle => '通知が許可されていません';

  @override
  String get notificationPermissionDialogMessage =>
      'リマインダーを届けるには通知を許可してください。設定アプリから変更できます。';

  @override
  String get openSettings => '設定を開く';

  @override
  String get customDictionaryTitle => 'カスタム辞書';

  @override
  String get customDictionaryDescription =>
      '友達の名前、ゼミ名、専門用語などを登録しておくと、録音時の音声認識で優先的に候補に使われます。説明を添えると、AIが表記の間違いを見つけて直す際のヒントにもなります。';

  @override
  String get wordLabel => '単語';

  @override
  String get wordHint => '例: 山田太郎';

  @override
  String get descriptionLabelOptional => '説明（任意）';

  @override
  String get descriptionHint => '例: 大学の友人';

  @override
  String get add => '追加';

  @override
  String get customDictionaryEmpty => '登録された単語はまだありません';

  @override
  String get diaryDayEmpty => 'この日の日記・感想はありません';

  @override
  String get diaryPickDateTooltip => '日付を選択';

  @override
  String get diaryPreviousWeekTooltip => '前の週';

  @override
  String get diaryNextWeekTooltip => '次の週';

  @override
  String get fontStandard => '標準';

  @override
  String get fontMincho => '明朝';

  @override
  String get fontHandwriting => '手書き風';

  @override
  String get fontPop => 'ポップ';

  @override
  String get fontMonospace => '等幅';

  @override
  String get fontGothic => 'ゴシック';

  @override
  String get fontRoundGothic => '丸ゴシック';

  @override
  String get fontThinMincho => '細明朝';

  @override
  String get fontBrush => '筆文字';

  @override
  String get fontRetro => 'レトロ';

  @override
  String get fontImpact => 'インパクト';

  @override
  String get fontCute => 'ゆるかわ';

  @override
  String mediaPickFailed(String error) {
    return '写真・動画の選択に失敗しました: $error';
  }

  @override
  String get pickPhotosFromLibrary => '写真を選択';

  @override
  String get pickPhotosFromLibrarySubtitle => 'アルバムから写真を選んで追加できます';

  @override
  String get pickVideoFromLibrary => '動画を選択';

  @override
  String get pickVideoFromLibrarySubtitle => 'アルバムから動画を選んで追加できます';

  @override
  String get backgroundSheetTitle => '背景';

  @override
  String get backgroundNone => 'なし';

  @override
  String get emotionSheetTitle => '感情';

  @override
  String get emotionNone => 'なし';

  @override
  String get comingSoon => '準備中です';

  @override
  String get diaryBgFruit => 'フルーツ';

  @override
  String get diaryBgMintPlant => 'ボタニカルノート';

  @override
  String get diaryBgCoffee => 'コーヒー';

  @override
  String get diaryBgCake => 'ケーキ';

  @override
  String get diaryBgPicnic => 'パン';

  @override
  String get diaryBgHeartBalloon => 'ハート風船';

  @override
  String get diaryBgSakuraStation => '桜の駅';

  @override
  String get diaryBgAutumnLeaves => '秋の紅葉';

  @override
  String get diaryBgStudyDesk => '勉強机';

  @override
  String get diaryBgHome => '家の中';

  @override
  String get diaryBgParkDay => 'タンポポ畑';

  @override
  String get diaryBgNightSky => '夜空';

  @override
  String get diaryBgSadBoy => '落ち込んでいる少年';

  @override
  String get diaryBgBeachGirl => '海辺の少女';

  @override
  String get diaryBgSleepingCat => '眠る猫';

  @override
  String get fontSheetTitle => 'フォント';

  @override
  String get fontSheetSizeLabel => '見出しサイズ';

  @override
  String get fontSheetColorLabel => '文字色';

  @override
  String get fontSheetStyleLabel => 'フォントスタイル';

  @override
  String get closeTooltip => '閉じる';

  @override
  String get favoriteSettingsTooltip => 'お気に入り設定';

  @override
  String get favoriteSettingsSheetTitle => 'お気に入り設定';

  @override
  String get favoriteSettingsDescription => '新しく作られる日記に使われる、文字スタイルと背景のデフォルトです';

  @override
  String get addCustomBackgroundTile => '自分の画像を追加';

  @override
  String get toolbarMedia => '画像・動画';

  @override
  String get toolbarBackground => '背景';

  @override
  String get toolbarText => 'テキスト';

  @override
  String get titleHint => '題名';

  @override
  String get bodyHint => 'ここにもっと書く…';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterToday => '今日';

  @override
  String get filterThisWeek => '今週';

  @override
  String get filterWithinMonth => '一か月以内';

  @override
  String get filterCompleted => '完了済み';

  @override
  String get tasksEmpty => 'まだタスクがありません\n「〜する」と話してみましょう';

  @override
  String get tasksFilterEmpty => 'この絞り込みに該当するタスクはありません';

  @override
  String get reminderLabel => 'リマインダー通知';

  @override
  String get removeReminderTooltip => 'リマインダーを解除';

  @override
  String get addReminder => 'リマインダーを追加';

  @override
  String get taskContentHint => 'タスク内容';

  @override
  String get allDayLabel => '終日';

  @override
  String get taskScheduleLabel => '開始・終了時間';

  @override
  String get startTimeCaption => '開始';

  @override
  String get endTimeCaption => '終了';

  @override
  String get addStartTime => '開始時間を設定';

  @override
  String get removeStartTimeTooltip => '開始時間を解除';

  @override
  String get addEndTime => '終了時間を追加';

  @override
  String get removeEndTimeTooltip => '終了時間を解除';

  @override
  String get manualTaskFabTooltip => 'タスクを追加';

  @override
  String get manualTaskScreenTitle => 'タスクを追加';

  @override
  String get manualTaskTitleHint => 'タスク内容（例: 牛乳を買う）';

  @override
  String get manualTaskTitleRequiredError => 'タスク内容を入力してください';

  @override
  String get ideasEmpty => 'まだアイデアがありません\n思いついたことを話してみましょう';

  @override
  String get editIdeaTitle => 'アイデアを編集';

  @override
  String get ideaTitleHint => '見出し（任意）';

  @override
  String get ideaContentHint => 'アイデアの内容';

  @override
  String get ideaStatusConsidering => '検討中';

  @override
  String get ideaStatusAdopted => '採用';

  @override
  String get ideaStatusRejected => '却下';

  @override
  String get ideaStatusNone => '未設定';

  @override
  String get ideaStatusLabel => '検討状況';

  @override
  String get ideaTagLabel => 'タグ';

  @override
  String get ideaTagHint => 'タグ（任意）';

  @override
  String get ideaSearchHint => 'アイデアを検索';

  @override
  String get ideaPinTooltip => 'ピン留め';

  @override
  String get ideaUnpinTooltip => 'ピン留めを解除';

  @override
  String get ideaSortNewestFirstTooltip => '新しい順に並び替え中（タップで古い順に）';

  @override
  String get ideaSortOldestFirstTooltip => '古い順に並び替え中（タップで新しい順に）';

  @override
  String get ideasFilterEmpty => 'この絞り込みに該当するアイデアはありません';

  @override
  String get reviewTitle => '内容を確認';

  @override
  String get reviewDescription =>
      '違っていればテキストを直せます。カードをドラッグすると日記・アイデア・タスクを入れ替えられます';

  @override
  String get sectionDiary => '日記';

  @override
  String get sectionIdea => 'アイデア';

  @override
  String get sectionTask => 'タスク';

  @override
  String get discard => '破棄';

  @override
  String get dragCardHere => 'ここにカードをドラッグ';

  @override
  String get genericProcessingError => '処理中にエラーが発生しました';

  @override
  String get usageFetchError => '利用状況の取得に失敗しました';

  @override
  String get watchNotPairedMessage =>
      'Apple Watchがペアリングされていません。Watchを近くに置いて、Apple純正の「Watch」アプリでペアリングを完了させてください。';

  @override
  String get backgroundRecordingChannelName => 'バックグラウンド録音';

  @override
  String get backgroundRecordingChannelDescription =>
      '録音中にバックグラウンド/画面オフでも録音を継続するための通知です';

  @override
  String get backgroundRecordingNotificationTitle => '録音中です';

  @override
  String get backgroundRecordingNotificationText => 'タップしてアプリに戻る';

  @override
  String get reminderNotificationTitle => 'リマインダー';

  @override
  String get reminderNotificationChannelName => 'ToDoリマインダー';

  @override
  String get reminderNotificationChannelDescription => '独り言から作られたToDoの時刻リマインダー';

  @override
  String get weeklyReportNotificationTitle => '週刊脳内レポートができました！';

  @override
  String get weeklyReportNotificationBody =>
      '今週のあなたの記録をAIが振り返りました。タップして見てみましょう';

  @override
  String get weeklyReportNotificationChannelName => '週刊レポート通知';

  @override
  String get weeklyReportNotificationChannelDescription =>
      '毎週日曜20時に週刊脳内レポートの完成をお知らせします';

  @override
  String get weeklyReportHistoryTooltip => '過去のレポート';

  @override
  String get weeklyReportHistoryTitle => '週刊レポート履歴';

  @override
  String get weeklyReportHistoryEmpty => 'まだ保存されたレポートがありません';

  @override
  String get knowledgeBaseTitle => '思考、記憶の検索';

  @override
  String get knowledgeBaseDescription => 'これまでの日記・アイデア・タスクをAIが振り返って答えます。';

  @override
  String get knowledgeBaseInputHint => '例：先月話してたアプリのアイデアってなんだっけ？';

  @override
  String get knowledgeBaseSend => '送信';

  @override
  String get knowledgeBaseThinking => '過去の記録を振り返っています…';

  @override
  String get knowledgeBaseEmpty => 'まだ記録がありません。録音してからまた聞いてみてください。';

  @override
  String get knowledgeBaseErrorTitle => '回答の取得に失敗しました';

  @override
  String get knowledgeBaseProLockedDescription =>
      '記録を横断したAIチャットはProプラン限定の機能です。アップグレードすると使えるようになります。';

  @override
  String get weeklyReportSettingsTitle => '週刊脳内レポート';

  @override
  String get weeklyReportSettingsSubtitle => '毎週のレポートをお届けします';

  @override
  String get weeklyReportTitle => '週刊脳内レポート';

  @override
  String get weeklyReportProLockedDescription =>
      '週刊脳内レポートはProプラン限定の機能です。アップグレードすると使えるようになります。';

  @override
  String get weeklyReportRetry => '再試行';

  @override
  String get weeklyReportLoadingInsights => 'AIが今週を振り返っています…';

  @override
  String get weeklyReportErrorTitle => 'レポートの取得に失敗しました';

  @override
  String get weeklyReportEmotionSectionTitle => '感情の傾向';

  @override
  String get weeklyReportNoEmotionData => '今週はまだ感情の記録がありません';

  @override
  String get weeklyReportAuroraSectionTitle => '今週のオーロラ';

  @override
  String get weeklyReportMentalWaveSectionTitle => 'メンタルウェーブ';

  @override
  String get weeklyReportCategorySectionTitle => '仕分け比率';

  @override
  String get weeklyReportNoCategoryData => '今週はまだ記録がありません';

  @override
  String get weeklyReportKeywordsSectionTitle => '脳内マップ';

  @override
  String get weeklyReportNoKeywords => '今週は目立ったキーワードが見つかりませんでした';

  @override
  String get weeklyReportBrainMapSubtitle => '何が自分の感情や思考を動かしていたのか';

  @override
  String get weeklyReportBrainMapSheetEmpty => '関連する記録が見つかりませんでした';

  @override
  String get weeklyReportIdeasSectionTitle => '輝いていたアイデア';

  @override
  String get weeklyReportNoIdeas => '今週はまだアイデアの記録がありません';

  @override
  String get weeklyReportHighlightSectionTitle => '今週のベストフレーズ';

  @override
  String get weeklyReportNoHighlight => '今週はまだ日記の記録がありません';

  @override
  String get weeklyReportAchievementSectionTitle => '今週の達成';

  @override
  String weeklyReportTasksCompleted(int count) {
    return '完了したタスク $count件';
  }

  @override
  String weeklyReportDiaryCount(int count) {
    return '書いた日記 $count件';
  }

  @override
  String get weeklyReportEncouragement => '今週もよく頑張りました！';

  @override
  String get weeklyReportAdviceSectionTitle => '来週へのアドバイス';

  @override
  String get weeklyReportLetterSectionTitle => 'AIからの週刊レター';

  @override
  String get weeklyReportShareTooltip => '画像として共有';

  @override
  String get weeklyReportShareCaption => '今週の脳内、こんな感じでした📝 #VoiceJournal';
}
