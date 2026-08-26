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
  String get emotionFatigue => '疲労';

  @override
  String get emotionLove => '愛情';

  @override
  String get emotionAnxious => '焦り';

  @override
  String get emotionExcited => 'ワクワク';

  @override
  String get emotionJoy => '喜び';

  @override
  String get emotionSadness => '悲しみ';

  @override
  String get emotionAnger => '怒り';

  @override
  String get emotionSatisfaction => '満足';

  @override
  String get emotionNeutral => 'ふつう';

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
      '話せない時はこちらに入力してください。内容は録音と同じようにAIが日記かタスクかを判断します。';

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
  String get integrationsSettingsTitle => '連携';

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
  String get appBackgroundSettingsTitle => '背景';

  @override
  String get appBackgroundScreenTitle => '背景を選択';

  @override
  String get backgroundAurora => 'オーロラと氷原の小屋';

  @override
  String get backgroundWhitehavenBeach => 'ホワイトヘブンビーチ';

  @override
  String get backgroundFlowerPark => 'フラワーパーク';

  @override
  String get backgroundStarrySky => '星空';

  @override
  String get backgroundBalloon => '気球';

  @override
  String get backgroundSavanna => 'サバンナ';

  @override
  String get backgroundDesert => '砂漠';

  @override
  String get backgroundDeepSea => '深海';

  @override
  String get backgroundAmazon => 'アマゾン';

  @override
  String get backgroundCat => '猫';

  @override
  String get freeTierSectionTitle => '無料枠';

  @override
  String get freeTierFetchFailed => '利用状況を取得できませんでした';

  @override
  String freeTierUsage(int used, int limit) {
    return '本日の録音回数: $used / $limit回';
  }

  @override
  String freeTierRemaining(int remaining) {
    return '残り$remaining回（日本時間の日付で毎日リセット）';
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
  String get diaryMonthEmpty => 'この月の日記・感想はありません';

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
  String mediaPickFailed(String error) {
    return '写真・動画の選択に失敗しました: $error';
  }

  @override
  String get pickFromLibrary => '写真・動画をライブラリから選択';

  @override
  String get backgroundSheetTitle => '背景';

  @override
  String get backgroundNone => 'なし';

  @override
  String get comingSoon => '準備中です';

  @override
  String get fontSheetTitle => 'フォント';

  @override
  String get setAsDefaultTooltip => 'この設定をデフォルトにする';

  @override
  String get setAsDefaultSnackbar => 'デフォルトに設定しました';

  @override
  String get closeTooltip => '閉じる';

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
  String get filterSomeday => 'いつか';

  @override
  String get filterCompleted => '完了済み';

  @override
  String get tasksEmpty => 'まだタスクがありません\n「〜する」と話してみましょう';

  @override
  String get tasksFilterEmpty => 'この絞り込みに該当するタスクはありません';

  @override
  String get reminderLabel => 'リマインダー';

  @override
  String get removeReminderTooltip => 'リマインダーを解除';

  @override
  String get addReminder => 'リマインダーを追加';

  @override
  String get taskContentHint => 'タスク内容';

  @override
  String get ideasEmpty => 'まだアイデアがありません\n思いついたことを話してみましょう';

  @override
  String get editIdeaTitle => 'アイデアを編集';

  @override
  String get ideaTitleHint => '見出し（任意）';

  @override
  String get ideaContentHint => 'アイデアの内容';

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
  String get reminderNotificationTitle => 'リマインダー';

  @override
  String get reminderNotificationChannelName => 'ToDoリマインダー';

  @override
  String get reminderNotificationChannelDescription => '独り言から作られたToDoの時刻リマインダー';

  @override
  String get knowledgeBaseTitle => '第二の脳';

  @override
  String get knowledgeBaseDescription => 'これまでの日記・アイデア・タスクをAIが横断的に振り返って答えます。';

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
  String get weeklyReportSettingsTitle => '週刊レポート';

  @override
  String get weeklyReportTitle => '週刊脳内レポート';

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
  String get weeklyReportKeywordsSectionTitle => '今週のキーワード';

  @override
  String get weeklyReportNoKeywords => '目立ったキーワードはありませんでした';

  @override
  String get weeklyReportIdeasSectionTitle => '輝いていたアイデア';

  @override
  String get weeklyReportNoIdeas => '今週はまだアイデアの記録がありません';

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
}
