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
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingCreateAccount =>
      'Create an account (you can also do this later in Settings)';

  @override
  String get onboardingPage1Title =>
      'The moment it crosses your mind,\njust say it out loud';

  @override
  String get onboardingPage1Body =>
      'Tap the record button and speak — VoiceJournal takes care of the rest';

  @override
  String get onboardingPage2Title => 'AI sorts it out for you';

  @override
  String get onboardingPage2Body =>
      'What you say is automatically sorted into a diary entry, idea, or task';

  @override
  String get onboardingPage3Title => 'Let\'s get started';

  @override
  String get onboardingPage3Body =>
      'Whenever something\'s on your mind, just tap and talk';

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
  String get emotionGratitude => 'Gratitude';

  @override
  String get emotionHappy => 'Happy';

  @override
  String get emotionFunny => 'Amused';

  @override
  String get emotionRelief => 'Relief';

  @override
  String get emotionCalm => 'Calm';

  @override
  String get emotionBoredom => 'Bored';

  @override
  String get emotionRegret => 'Regret';

  @override
  String get emotionDislike => 'Dislike';

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
  String maxRecordingMinutes(int minutes) {
    return 'Each recording can be up to $minutes minutes';
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
      'Use this when you can\'t speak. The AI sorts it into a diary entry, task, or idea just like a recording.';

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
  String get darkModeSubtitle => 'Switch to an easier-on-the-eyes look';

  @override
  String get settingsCustomBackgroundTitle => 'Background Image';

  @override
  String get settingsCustomBackgroundSubtitleUnset => 'Not set';

  @override
  String get settingsCustomBackgroundSubtitleSet =>
      'Custom photo set (tap to change)';

  @override
  String get settingsCustomBackgroundClearTooltip => 'Reset to default';

  @override
  String get settingsProBadge => 'Pro only';

  @override
  String get integrationsSettingsTitle => 'Integrations';

  @override
  String get integrationsCalendarRowTitle => 'Calendar integration';

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
  String get appleRemindersSettingsTitle => 'Reminders';

  @override
  String get appleRemindersScreenTitle => 'Reminders Integration';

  @override
  String get appleRemindersDescription =>
      'Choose a list from the device\'s Reminders app. Once turned on, any task with a due date will automatically be added there, and completing it in the app marks it as completed in Reminders too.';

  @override
  String get appleRemindersPermissionDenied =>
      'Reminders access wasn\'t granted. You can allow it from the system Settings app.';

  @override
  String get appleRemindersNoLists =>
      'No writable reminder lists were found. Create a list in the Reminders app, then refresh.';

  @override
  String get accountSectionTitle => 'Account';

  @override
  String accountSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get accountNotSignedIn => 'Not signed in';

  @override
  String get accountNotSignedInDescription =>
      'Sign in with Google or Apple to carry your diary data over to other devices';

  @override
  String get accountScreenTitle => 'Account';

  @override
  String get accountSignInWithGoogle => 'Sign in with Google';

  @override
  String get accountSignInWithApple => 'Sign in with Apple';

  @override
  String get accountSignOutButton => 'Sign out';

  @override
  String get accountRestoreButton => 'Restore from cloud';

  @override
  String get watchPairingButton => 'Pair Apple Watch';

  @override
  String get watchPairingSuccessTitle => 'Paired';

  @override
  String get watchPairingSuccessMessage =>
      'Your Apple Watch is paired. You can now record on the Watch by itself.';

  @override
  String get syncErrorBannerMessage => 'Some data failed to sync';

  @override
  String get syncErrorBannerAction => 'Check';

  @override
  String get loadErrorBannerMessage => 'Failed to load your data';

  @override
  String get loadErrorBannerAction => 'Retry';

  @override
  String get mediaStorageWarningBannerMessage =>
      'Your photo/video cloud storage is almost full';

  @override
  String get mediaStorageFullBannerMessage =>
      'Photo/video cloud storage is full. New photos and videos won\'t sync';

  @override
  String get mediaStorageBannerAction => 'Clean up';

  @override
  String get accountSyncingMessage => 'Syncing…';

  @override
  String get accountSyncCompleteTitle => 'Done';

  @override
  String get accountSyncCompleteMessage => 'Sync complete.';

  @override
  String get accountErrorTitle => 'Error';

  @override
  String get accountErrorNetwork =>
      'A network error occurred. Please try again shortly.';

  @override
  String get accountErrorUnknown =>
      'Something went wrong. Please try again shortly.';

  @override
  String get accountSignOutConfirmTitle => 'Sign out?';

  @override
  String get accountSignOutConfirmMessage =>
      'Your data on this device won\'t be deleted. Sign back in anytime to resume syncing.';

  @override
  String get accountMediaSyncFreeNote =>
      'Only text (diary entries, ideas, and tasks) is backed up. Photos and videos aren\'t synced to the cloud — that\'s limited to the monthly/annual plans (not included with the lifetime plan).';

  @override
  String get accountMediaSyncProNote =>
      'Photos and videos are backed up to the cloud too.';

  @override
  String get supportSectionTitle => 'Support';

  @override
  String get contactSupportTitle => 'Contact us';

  @override
  String get contactSupportEmailSubject => 'VoiceJournal Support';

  @override
  String get planSectionTitle => 'Plan';

  @override
  String get planCurrentTitle => 'Current plan';

  @override
  String get planProTitle => 'Pro plan';

  @override
  String get planFreeTitle => 'Free plan';

  @override
  String get planProSubtitle =>
      'Up to 15 minutes per recording, 30 recordings a day';

  @override
  String get planFreeSubtitle =>
      'Up to 60 seconds per recording, 3 recordings a day for free';

  @override
  String get planManage => 'Manage';

  @override
  String get planUpgrade => 'Upgrade';

  @override
  String get paywallTitle => 'Pro plan';

  @override
  String get paywallSectionTitle => 'What Pro unlocks';

  @override
  String get paywallSectionSubtitle => 'Unlimited access to every Pro feature';

  @override
  String get paywallBenefitDurationTitle => 'Longer recordings';

  @override
  String get paywallBenefitDurationBefore => '60 sec';

  @override
  String get paywallBenefitDurationAfter => '15 min';

  @override
  String get paywallBenefitDurationDesc =>
      'Talk as long as you need without losing the details';

  @override
  String get paywallBenefitCountTitle => 'More uses per day';

  @override
  String get paywallBenefitCountBefore => '3 / day';

  @override
  String get paywallBenefitCountAfter => '30 / day';

  @override
  String get paywallBenefitCountDesc =>
      'Capture every thought, whenever it strikes';

  @override
  String get paywallBenefitCustomBackgroundTitle => 'Add ';

  @override
  String get paywallBenefitCustomBackgroundHighlight => 'your own photo';

  @override
  String get paywallBenefitCustomBackgroundDesc =>
      'Make every entry feel like yours';

  @override
  String get paywallBenefitKnowledgeBaseHighlight => 'Ask (second brain)';

  @override
  String get paywallBenefitKnowledgeBaseSuffix => ' is unlocked';

  @override
  String get paywallBenefitKnowledgeBaseDesc =>
      'AI digs through everything you\'ve recorded to help';

  @override
  String get paywallBenefitWeeklyReportTitle => 'Weekly Brain Report';

  @override
  String get paywallBenefitWeeklyReportDesc =>
      'AI reads your week and delivers the highlights';

  @override
  String get paywallBenefitMediaSyncTitle => 'Cloud photo & video sync';

  @override
  String get paywallBenefitMediaSyncDesc =>
      'Keep your memories safely backed up';

  @override
  String get paywallBenefitMediaSyncBadge => 'Monthly / annual plans only';

  @override
  String get paywallUnavailable =>
      'Couldn\'t load plans right now. Please try again later.';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallTerms => 'Terms of Service';

  @override
  String get paywallPrivacy => 'Privacy Policy';

  @override
  String get paywallPurchaseFailed =>
      'Something went wrong. Please try again later.';

  @override
  String get paywallRestoreNotFound => 'No restorable purchase was found.';

  @override
  String get paywallPlanMonthly => 'Monthly';

  @override
  String get paywallPlanAnnual => 'Annual';

  @override
  String get paywallPlanLifetime => 'Lifetime';

  @override
  String get paywallPlanRecommended => 'Recommended';

  @override
  String get paywallPlanLifetimeCaption =>
      'Everything except cloud photo/video sync';

  @override
  String get paywallPlanComingSoon => 'Coming soon';

  @override
  String get paywallContinueButton => 'Continue';

  @override
  String homeUsageToday(int used, int limit) {
    return 'Today $used / $limit';
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
  String get diaryDayEmpty => 'No diary entries this day';

  @override
  String get diaryPickDateTooltip => 'Pick a date';

  @override
  String get diaryPreviousWeekTooltip => 'Previous week';

  @override
  String get diaryNextWeekTooltip => 'Next week';

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
  String get fontGothic => 'Gothic';

  @override
  String get fontRoundGothic => 'Rounded';

  @override
  String get fontThinMincho => 'Thin Serif';

  @override
  String get fontBrush => 'Brush';

  @override
  String get fontRetro => 'Retro';

  @override
  String get fontImpact => 'Impact';

  @override
  String get fontCute => 'Cute';

  @override
  String mediaPickFailed(String error) {
    return 'Failed to select photo/video: $error';
  }

  @override
  String get pickPhotosFromLibrary => 'Choose photos';

  @override
  String get pickPhotosFromLibrarySubtitle =>
      'Pick photos from your library to add';

  @override
  String get pickVideoFromLibrary => 'Choose a video';

  @override
  String get pickVideoFromLibrarySubtitle =>
      'Pick a video from your library to add';

  @override
  String get backgroundSheetTitle => 'Background';

  @override
  String get backgroundNone => 'None';

  @override
  String get emotionSheetTitle => 'Emotion';

  @override
  String get emotionNone => 'None';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get diaryBgFruit => 'Fruit';

  @override
  String get diaryBgMintPlant => 'Botanical Notes';

  @override
  String get diaryBgCoffee => 'Coffee';

  @override
  String get diaryBgCake => 'Cake';

  @override
  String get diaryBgPicnic => 'Bread Basket';

  @override
  String get diaryBgHeartBalloon => 'Heart Balloons';

  @override
  String get diaryBgSakuraStation => 'Sakura Station';

  @override
  String get diaryBgAutumnLeaves => 'Autumn Leaves';

  @override
  String get diaryBgStudyDesk => 'Study Desk';

  @override
  String get diaryBgHome => 'At Home';

  @override
  String get diaryBgParkDay => 'Dandelion Field';

  @override
  String get diaryBgNightSky => 'Night Sky';

  @override
  String get diaryBgSadBoy => 'Feeling Down';

  @override
  String get diaryBgBeachGirl => 'By the Sea';

  @override
  String get diaryBgSleepingCat => 'Sleeping Cat';

  @override
  String get fontSheetTitle => 'Font';

  @override
  String get fontSheetSizeLabel => 'Heading size';

  @override
  String get fontSheetColorLabel => 'Text color';

  @override
  String get fontSheetStyleLabel => 'Font style';

  @override
  String get closeTooltip => 'Close';

  @override
  String get favoriteSettingsTooltip => 'Favorite settings';

  @override
  String get favoriteSettingsSheetTitle => 'Favorite settings';

  @override
  String get favoriteSettingsDescription =>
      'The default text style and background used for newly created diary entries';

  @override
  String get addCustomBackgroundTile => 'Add your own photo';

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
  String get filterWithinMonth => 'Within a month';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get tasksEmpty => 'No tasks yet\nTry saying \"I need to…\"';

  @override
  String get tasksFilterEmpty => 'No tasks match this filter';

  @override
  String get reminderLabel => 'Notification reminder';

  @override
  String get removeReminderTooltip => 'Remove reminder';

  @override
  String get addReminder => 'Add reminder';

  @override
  String get taskContentHint => 'Task content';

  @override
  String get allDayLabel => 'All day';

  @override
  String get taskScheduleLabel => 'Start & End Time';

  @override
  String get startTimeCaption => 'Start';

  @override
  String get endTimeCaption => 'End';

  @override
  String get addStartTime => 'Set start time';

  @override
  String get removeStartTimeTooltip => 'Remove start time';

  @override
  String get addEndTime => 'Add end time';

  @override
  String get removeEndTimeTooltip => 'Remove end time';

  @override
  String get manualTaskFabTooltip => 'Add task';

  @override
  String get manualTaskScreenTitle => 'Add task';

  @override
  String get manualTaskTitleHint => 'Task (e.g. Buy milk)';

  @override
  String get manualTaskTitleRequiredError => 'Please enter a task';

  @override
  String get manualDiaryFabTooltip => 'Add diary entry';

  @override
  String get manualDiaryScreenTitle => 'Add diary entry';

  @override
  String get manualDiaryTitleHint => 'Heading (optional)';

  @override
  String get manualDiaryContentHint => 'How was your day?';

  @override
  String get manualDiaryContentRequiredError => 'Please enter some content';

  @override
  String get manualIdeaFabTooltip => 'Add idea';

  @override
  String get manualIdeaScreenTitle => 'Add idea';

  @override
  String get manualIdeaTitleHint => 'Heading (optional)';

  @override
  String get manualIdeaContentHint => 'Idea content';

  @override
  String get manualIdeaContentRequiredError => 'Please enter some content';

  @override
  String get ideasEmpty => 'No ideas yet\nTry saying what comes to mind';

  @override
  String get editIdeaTitle => 'Edit idea';

  @override
  String get ideaTitleHint => 'Heading (optional)';

  @override
  String get ideaContentHint => 'Idea content';

  @override
  String get ideaStatusConsidering => 'Considering';

  @override
  String get ideaStatusAdopted => 'Adopted';

  @override
  String get ideaStatusRejected => 'Rejected';

  @override
  String get ideaStatusNone => 'No status';

  @override
  String get ideaStatusLabel => 'Status';

  @override
  String get ideaTagLabel => 'Tag';

  @override
  String get ideaTagHint => 'Tag (optional)';

  @override
  String get ideaSearchHint => 'Search ideas';

  @override
  String get ideaPinTooltip => 'Pin';

  @override
  String get ideaUnpinTooltip => 'Unpin';

  @override
  String get ideaSortNewestFirstTooltip =>
      'Sorted newest first (tap for oldest first)';

  @override
  String get ideaSortOldestFirstTooltip =>
      'Sorted oldest first (tap for newest first)';

  @override
  String get ideasFilterEmpty => 'No ideas match this filter';

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
  String get addCardButton => 'Add card';

  @override
  String get genericProcessingError => 'An error occurred while processing';

  @override
  String get usageFetchError => 'Failed to load usage status';

  @override
  String get watchNotPairedMessage =>
      'Your Apple Watch isn\'t paired. Keep it nearby and finish pairing in Apple\'s Watch app first.';

  @override
  String get backgroundRecordingChannelName => 'Background recording';

  @override
  String get backgroundRecordingChannelDescription =>
      'Keeps recording running while the app is backgrounded or the screen is off';

  @override
  String get backgroundRecordingNotificationTitle => 'Recording…';

  @override
  String get backgroundRecordingNotificationText => 'Tap to return to the app';

  @override
  String get reminderNotificationTitle => 'Reminder';

  @override
  String get reminderNotificationChannelName => 'To-do reminders';

  @override
  String get reminderNotificationChannelDescription =>
      'Time-based reminders for to-dos created from your voice notes';

  @override
  String get weeklyReportNotificationTitle =>
      'Your Weekly Brain Report is ready!';

  @override
  String get weeklyReportNotificationBody =>
      'AI has looked back on your week. Tap to see it.';

  @override
  String get weeklyReportNotificationChannelName =>
      'Weekly report notifications';

  @override
  String get weeklyReportNotificationChannelDescription =>
      'Notifies you every Sunday at 8pm when your Weekly Brain Report is ready';

  @override
  String get weeklyReportHistoryTooltip => 'Past reports';

  @override
  String get weeklyReportHistoryTitle => 'Weekly Report History';

  @override
  String get weeklyReportHistoryEmpty => 'No saved reports yet';

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
  String get knowledgeBaseProLockedDescription =>
      'Chatting across all your entries is a Pro feature. Upgrade to unlock it.';

  @override
  String get ideaBrainstormTooltip => 'Brainstorm with AI';

  @override
  String ideaBrainstormChatQuestion(Object title) {
    return 'Explore 3 different angles for \"$title\"';
  }

  @override
  String get ideaBrainstormErrorTitle => 'Couldn\'t get suggestions';

  @override
  String get weeklyReportSettingsTitle => 'Weekly Brain Report';

  @override
  String get weeklyReportSettingsSubtitle => 'Delivered every week';

  @override
  String get weeklyReportTitle => 'Weekly Brain Report';

  @override
  String get weeklyReportProLockedDescription =>
      'The Weekly Brain Report is a Pro feature. Upgrade to unlock it.';

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
  String get weeklyReportConstellationSectionTitle => 'Weekly Constellation';

  @override
  String get weeklyReportMentalWaveSectionTitle => 'Mental Wave';

  @override
  String get weeklyReportCategorySectionTitle => 'Category mix';

  @override
  String get weeklyReportNoCategoryData => 'No entries yet this week';

  @override
  String get weeklyReportKeywordsSectionTitle => 'Brain Map';

  @override
  String get weeklyReportNoKeywords => 'No standout keywords found this week';

  @override
  String get weeklyReportBrainMapSubtitle =>
      'What\'s been driving your feelings and thoughts';

  @override
  String get weeklyReportBrainMapSheetEmpty => 'No related entries found';

  @override
  String get weeklyReportIdeasSectionTitle => 'Ideas that shined';

  @override
  String get weeklyReportNoIdeas => 'No ideas recorded yet this week';

  @override
  String get weeklyReportHighlightSectionTitle => 'This week\'s highlight';

  @override
  String get weeklyReportNoHighlight => 'No diary entries yet this week';

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

  @override
  String get weeklyReportLetterSectionTitle => 'Your Weekly Letter';

  @override
  String get weeklyReportShareTooltip => 'Share as image';

  @override
  String get weeklyReportShareCaption =>
      'Here\'s what my week looked like 📝 #VoiceJournal';
}
