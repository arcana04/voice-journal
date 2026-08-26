// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navRecord => 'Record';

  @override
  String get navDiary => 'Diary';

  @override
  String get navIdea => 'Idea';

  @override
  String get navTask => 'Task';

  @override
  String get navKnowledgeBase => 'Ask';

  @override
  String get emotionFatigue => 'Fatigue';

  @override
  String get emotionLove => 'Love';

  @override
  String get emotionAnxious => 'Anxious';

  @override
  String get emotionExcited => 'Excited';

  @override
  String get emotionJoy => 'Joy';

  @override
  String get emotionSadness => 'Sadness';

  @override
  String get emotionAnger => 'Anger';

  @override
  String get emotionSatisfaction => 'Satisfaction';

  @override
  String get emotionNeutral => 'Neutral';

  @override
  String get confirmDeleteTitle => 'Delete this?';

  @override
  String get confirmDeleteMessage => 'Deleting this entry can\'t be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get editTooltip => 'Edit';

  @override
  String get micPermissionDenied => 'Microphone access is not allowed';

  @override
  String get recordingStopFailedTitle => 'Failed to stop recording';

  @override
  String get recordingErrorTitle => 'Recording error';

  @override
  String get recordingSaveFailed => 'Failed to save the recording';

  @override
  String get processingErrorTitle => 'An error occurred while processing';

  @override
  String statusError(String message) {
    return 'Error: $message';
  }

  @override
  String statusOrganized(String summary) {
    return 'Organized: $summary';
  }

  @override
  String get statusTapToRecord => 'Tap to start recording';

  @override
  String get statusRecording => 'Recording… tap again to stop';

  @override
  String get statusProcessing => 'AI is analyzing…';

  @override
  String maxRecordingSeconds(int seconds) {
    return 'Each recording can be up to $seconds seconds';
  }

  @override
  String get textComposeTooltip => 'Enter as text';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get menuCustomDictionary => 'Custom dictionary';

  @override
  String get menuSummaryLevel => 'AI summarization level';

  @override
  String get textComposerTitle => 'Enter as text';

  @override
  String get textComposerDescription =>
      'Use this when you can\'t speak. The AI sorts it into a diary entry or task just like a recording.';

  @override
  String get textComposerHint =>
      'e.g. Book a dentist appointment tomorrow at 3pm';

  @override
  String get textComposerSubmit => 'Let AI analyze it';

  @override
  String get summaryLevelSheetTitle => 'AI summarization level';

  @override
  String get summaryLevelSheetDescription =>
      'Choose how much the AI shortens diary content from recordings or text. This doesn\'t affect how concise tasks are.';

  @override
  String get summaryLevelPreserveLabel => 'Preserve';

  @override
  String get summaryLevelStandardLabel => 'Standard';

  @override
  String get summaryLevelCompactLabel => 'Compact';

  @override
  String get summaryLevelPreserveDescription =>
      'Keeps feelings, phrasing, and names exactly as spoken, without summarizing.';

  @override
  String get summaryLevelStandardDescription =>
      'Tidies up redundant repetition while keeping a natural diary length.';

  @override
  String get summaryLevelCompactDescription =>
      'Condenses everything down to just the core in 1-2 sentences.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get displaySectionTitle => 'Display';

  @override
  String get darkModeTitle => 'Dark mode';

  @override
  String get integrationsSettingsTitle => 'Integrations';

  @override
  String get integrationsScreenTitle => 'Integrations';

  @override
  String get integrationsDescription =>
      'Choose a calendar already set up on this device (like iOS Calendar or a Google account added in system settings). Once turned on, any task with a specific date and time will automatically be added there as an event.';

  @override
  String get integrationsOff => 'Off';

  @override
  String get integrationsPermissionDenied =>
      'Calendar access wasn\'t granted. You can allow it from the system Settings app.';

  @override
  String get integrationsNoCalendars =>
      'No writable calendars were found on this device. Add a calendar (like a Google account) in the system Settings app, then refresh.';

  @override
  String get integrationsRefresh => 'Refresh';

  @override
  String get appBackgroundSettingsTitle => 'Background';

  @override
  String get appBackgroundScreenTitle => 'Choose a background';

  @override
  String get backgroundAurora => 'Aurora & Ice Hut';

  @override
  String get backgroundWhitehavenBeach => 'Whitehaven Beach';

  @override
  String get backgroundFlowerPark => 'Flower Park';

  @override
  String get backgroundStarrySky => 'Starry Sky';

  @override
  String get backgroundBalloon => 'Hot Air Balloon';

  @override
  String get backgroundSavanna => 'Savanna';

  @override
  String get backgroundDesert => 'Desert';

  @override
  String get backgroundDeepSea => 'Deep Sea';

  @override
  String get backgroundAmazon => 'Amazon Rainforest';

  @override
  String get backgroundCat => 'Cat';

  @override
  String get freeTierSectionTitle => 'Free tier';

  @override
  String get freeTierFetchFailed => 'Couldn\'t load usage status';

  @override
  String freeTierUsage(int used, int limit) {
    return 'Recordings today: $used / $limit';
  }

  @override
  String freeTierRemaining(int remaining) {
    return '$remaining left today (resets daily, Japan time)';
  }

  @override
  String get notificationSectionTitle => 'Notifications';

  @override
  String get reminderNotificationsTitle => 'Reminder notifications';

  @override
  String get notificationCheckingStatus => 'Checking…';

  @override
  String get notificationGranted => 'Allowed';

  @override
  String get notificationDenied =>
      'Not allowed (reminders won\'t be delivered)';

  @override
  String get allow => 'Allow';

  @override
  String get notificationPermissionDialogTitle =>
      'Notifications aren\'t allowed';

  @override
  String get notificationPermissionDialogMessage =>
      'Allow notifications to receive reminders. You can change this in the Settings app.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get customDictionaryTitle => 'Custom dictionary';

  @override
  String get customDictionaryDescription =>
      'Register names of friends, groups, or technical terms so they\'re prioritized during voice recognition. Adding a note also helps the AI catch and fix misspellings.';

  @override
  String get wordLabel => 'Word';

  @override
  String get wordHint => 'e.g. Taro Yamada';

  @override
  String get descriptionLabelOptional => 'Description (optional)';

  @override
  String get descriptionHint => 'e.g. A friend from university';

  @override
  String get add => 'Add';

  @override
  String get customDictionaryEmpty => 'No words registered yet';

  @override
  String get diaryMonthEmpty => 'No diary entries this month';

  @override
  String get fontStandard => 'Standard';

  @override
  String get fontMincho => 'Serif';

  @override
  String get fontHandwriting => 'Handwritten';

  @override
  String get fontPop => 'Pop';

  @override
  String get fontMonospace => 'Monospace';

  @override
  String mediaPickFailed(String error) {
    return 'Failed to select photo/video: $error';
  }

  @override
  String get pickFromLibrary => 'Choose photo/video from library';

  @override
  String get backgroundSheetTitle => 'Background';

  @override
  String get backgroundNone => 'None';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get fontSheetTitle => 'Font';

  @override
  String get setAsDefaultTooltip => 'Set as default';

  @override
  String get setAsDefaultSnackbar => 'Set as default';

  @override
  String get closeTooltip => 'Close';

  @override
  String get toolbarMedia => 'Photo/Video';

  @override
  String get toolbarBackground => 'Background';

  @override
  String get toolbarText => 'Text';

  @override
  String get titleHint => 'Title';

  @override
  String get bodyHint => 'Write more here…';

  @override
  String get filterAll => 'All';

  @override
  String get filterToday => 'Today';

  @override
  String get filterThisWeek => 'This week';

  @override
  String get filterSomeday => 'Someday';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get tasksEmpty => 'No tasks yet\nTry saying \"I need to…\"';

  @override
  String get tasksFilterEmpty => 'No tasks match this filter';

  @override
  String get reminderLabel => 'Reminder';

  @override
  String get removeReminderTooltip => 'Remove reminder';

  @override
  String get addReminder => 'Add reminder';

  @override
  String get taskContentHint => 'Task content';

  @override
  String get ideasEmpty => 'No ideas yet\nTry saying what comes to mind';

  @override
  String get editIdeaTitle => 'Edit idea';

  @override
  String get ideaTitleHint => 'Heading (optional)';

  @override
  String get ideaContentHint => 'Idea content';

  @override
  String get reviewTitle => 'Review content';

  @override
  String get reviewDescription =>
      'Edit the text if it\'s off. Drag a card to move it between diary, idea, and task.';

  @override
  String get sectionDiary => 'Diary';

  @override
  String get sectionIdea => 'Idea';

  @override
  String get sectionTask => 'Task';

  @override
  String get discard => 'Discard';

  @override
  String get dragCardHere => 'Drag a card here';

  @override
  String get genericProcessingError => 'An error occurred while processing';

  @override
  String get usageFetchError => 'Failed to load usage status';

  @override
  String get reminderNotificationTitle => 'Reminder';

  @override
  String get reminderNotificationChannelName => 'To-do reminders';

  @override
  String get reminderNotificationChannelDescription =>
      'Time-based reminders for to-dos created from your voice notes';

  @override
  String get knowledgeBaseTitle => 'Second Brain';

  @override
  String get knowledgeBaseDescription =>
      'AI looks back across all your diary entries, ideas, and tasks to answer you.';

  @override
  String get knowledgeBaseInputHint =>
      'e.g. What was that app idea I mentioned last month?';

  @override
  String get knowledgeBaseSend => 'Send';

  @override
  String get knowledgeBaseThinking => 'Looking back through your past entries…';

  @override
  String get knowledgeBaseEmpty =>
      'There\'s nothing recorded yet. Record something, then ask again.';

  @override
  String get knowledgeBaseErrorTitle => 'Couldn\'t get an answer';

  @override
  String get weeklyReportSettingsTitle => 'Weekly report';

  @override
  String get weeklyReportTitle => 'Weekly Brain Report';

  @override
  String get weeklyReportRetry => 'Retry';

  @override
  String get weeklyReportLoadingInsights => 'AI is reflecting on your week…';

  @override
  String get weeklyReportErrorTitle => 'Couldn\'t load the report';

  @override
  String get weeklyReportEmotionSectionTitle => 'Emotional trends';

  @override
  String get weeklyReportNoEmotionData => 'No emotional entries yet this week';

  @override
  String get weeklyReportKeywordsSectionTitle => 'This week\'s keywords';

  @override
  String get weeklyReportNoKeywords => 'No standout keywords this week';

  @override
  String get weeklyReportIdeasSectionTitle => 'Ideas that shined';

  @override
  String get weeklyReportNoIdeas => 'No ideas recorded yet this week';

  @override
  String get weeklyReportAchievementSectionTitle => 'This week\'s wins';

  @override
  String weeklyReportTasksCompleted(int count) {
    return '$count tasks completed';
  }

  @override
  String weeklyReportDiaryCount(int count) {
    return '$count diary entries';
  }

  @override
  String get weeklyReportEncouragement => 'You did great this week!';

  @override
  String get weeklyReportAdviceSectionTitle => 'Advice for next week';
}
