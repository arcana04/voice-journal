import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @navRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get navRecord;

  /// No description provided for @navDiary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get navDiary;

  /// No description provided for @navIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get navIdea;

  /// No description provided for @navTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get navTask;

  /// No description provided for @navKnowledgeBase.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get navKnowledgeBase;

  /// No description provided for @emotionFatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue'**
  String get emotionFatigue;

  /// No description provided for @emotionLove.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get emotionLove;

  /// No description provided for @emotionAnxious.
  ///
  /// In en, this message translates to:
  /// **'Anxious'**
  String get emotionAnxious;

  /// No description provided for @emotionExcited.
  ///
  /// In en, this message translates to:
  /// **'Excited'**
  String get emotionExcited;

  /// No description provided for @emotionJoy.
  ///
  /// In en, this message translates to:
  /// **'Joy'**
  String get emotionJoy;

  /// No description provided for @emotionSadness.
  ///
  /// In en, this message translates to:
  /// **'Sadness'**
  String get emotionSadness;

  /// No description provided for @emotionAnger.
  ///
  /// In en, this message translates to:
  /// **'Anger'**
  String get emotionAnger;

  /// No description provided for @emotionSatisfaction.
  ///
  /// In en, this message translates to:
  /// **'Satisfaction'**
  String get emotionSatisfaction;

  /// No description provided for @emotionNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get emotionNeutral;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting this entry can\'t be undone.'**
  String get confirmDeleteMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is not allowed'**
  String get micPermissionDenied;

  /// No description provided for @recordingStopFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to stop recording'**
  String get recordingStopFailedTitle;

  /// No description provided for @recordingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording error'**
  String get recordingErrorTitle;

  /// No description provided for @recordingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the recording'**
  String get recordingSaveFailed;

  /// No description provided for @processingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while processing'**
  String get processingErrorTitle;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String statusError(String message);

  /// No description provided for @statusOrganized.
  ///
  /// In en, this message translates to:
  /// **'Organized: {summary}'**
  String statusOrganized(String summary);

  /// No description provided for @statusTapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to start recording'**
  String get statusTapToRecord;

  /// No description provided for @statusRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording… tap again to stop'**
  String get statusRecording;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing…'**
  String get statusProcessing;

  /// No description provided for @maxRecordingSeconds.
  ///
  /// In en, this message translates to:
  /// **'Each recording can be up to {seconds} seconds'**
  String maxRecordingSeconds(int seconds);

  /// No description provided for @textComposeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Enter as text'**
  String get textComposeTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @menuCustomDictionary.
  ///
  /// In en, this message translates to:
  /// **'Custom dictionary'**
  String get menuCustomDictionary;

  /// No description provided for @menuSummaryLevel.
  ///
  /// In en, this message translates to:
  /// **'AI summarization level'**
  String get menuSummaryLevel;

  /// No description provided for @textComposerTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter as text'**
  String get textComposerTitle;

  /// No description provided for @textComposerDescription.
  ///
  /// In en, this message translates to:
  /// **'Use this when you can\'t speak. The AI sorts it into a diary entry, task, or idea just like a recording.'**
  String get textComposerDescription;

  /// No description provided for @textComposerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Book a dentist appointment tomorrow at 3pm'**
  String get textComposerHint;

  /// No description provided for @textComposerSubmit.
  ///
  /// In en, this message translates to:
  /// **'Let AI analyze it'**
  String get textComposerSubmit;

  /// No description provided for @summaryLevelSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'AI summarization level'**
  String get summaryLevelSheetTitle;

  /// No description provided for @summaryLevelSheetDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how much the AI shortens diary content from recordings or text. This doesn\'t affect how concise tasks are.'**
  String get summaryLevelSheetDescription;

  /// No description provided for @summaryLevelPreserveLabel.
  ///
  /// In en, this message translates to:
  /// **'Preserve'**
  String get summaryLevelPreserveLabel;

  /// No description provided for @summaryLevelStandardLabel.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get summaryLevelStandardLabel;

  /// No description provided for @summaryLevelCompactLabel.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get summaryLevelCompactLabel;

  /// No description provided for @summaryLevelPreserveDescription.
  ///
  /// In en, this message translates to:
  /// **'Keeps feelings, phrasing, and names exactly as spoken, without summarizing.'**
  String get summaryLevelPreserveDescription;

  /// No description provided for @summaryLevelStandardDescription.
  ///
  /// In en, this message translates to:
  /// **'Tidies up redundant repetition while keeping a natural diary length.'**
  String get summaryLevelStandardDescription;

  /// No description provided for @summaryLevelCompactDescription.
  ///
  /// In en, this message translates to:
  /// **'Condenses everything down to just the core in 1-2 sentences.'**
  String get summaryLevelCompactDescription;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @displaySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySectionTitle;

  /// No description provided for @darkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkModeTitle;

  /// No description provided for @integrationsSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrationsSettingsTitle;

  /// No description provided for @integrationsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrationsScreenTitle;

  /// No description provided for @integrationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a calendar already set up on this device (like iOS Calendar or a Google account added in system settings). Once turned on, any task with a specific date and time will automatically be added there as an event.'**
  String get integrationsDescription;

  /// No description provided for @integrationsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get integrationsOff;

  /// No description provided for @integrationsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Calendar access wasn\'t granted. You can allow it from the system Settings app.'**
  String get integrationsPermissionDenied;

  /// No description provided for @integrationsNoCalendars.
  ///
  /// In en, this message translates to:
  /// **'No writable calendars were found on this device. Add a calendar (like a Google account) in the system Settings app, then refresh.'**
  String get integrationsNoCalendars;

  /// No description provided for @integrationsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get integrationsRefresh;

  /// No description provided for @appBackgroundSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get appBackgroundSettingsTitle;

  /// No description provided for @appBackgroundScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a background'**
  String get appBackgroundScreenTitle;

  /// No description provided for @backgroundAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora & Ice Hut'**
  String get backgroundAurora;

  /// No description provided for @backgroundWhitehavenBeach.
  ///
  /// In en, this message translates to:
  /// **'Whitehaven Beach'**
  String get backgroundWhitehavenBeach;

  /// No description provided for @backgroundFlowerPark.
  ///
  /// In en, this message translates to:
  /// **'Flower Park'**
  String get backgroundFlowerPark;

  /// No description provided for @backgroundStarrySky.
  ///
  /// In en, this message translates to:
  /// **'Starry Sky'**
  String get backgroundStarrySky;

  /// No description provided for @backgroundBalloon.
  ///
  /// In en, this message translates to:
  /// **'Hot Air Balloon'**
  String get backgroundBalloon;

  /// No description provided for @backgroundSavanna.
  ///
  /// In en, this message translates to:
  /// **'Savanna'**
  String get backgroundSavanna;

  /// No description provided for @backgroundDesert.
  ///
  /// In en, this message translates to:
  /// **'Desert'**
  String get backgroundDesert;

  /// No description provided for @backgroundDeepSea.
  ///
  /// In en, this message translates to:
  /// **'Deep Sea'**
  String get backgroundDeepSea;

  /// No description provided for @backgroundAmazon.
  ///
  /// In en, this message translates to:
  /// **'Amazon Rainforest'**
  String get backgroundAmazon;

  /// No description provided for @backgroundCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get backgroundCat;

  /// No description provided for @freeTierSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Free tier'**
  String get freeTierSectionTitle;

  /// No description provided for @freeTierFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load usage status'**
  String get freeTierFetchFailed;

  /// No description provided for @freeTierUsage.
  ///
  /// In en, this message translates to:
  /// **'Recordings today: {used} / {limit}'**
  String freeTierUsage(int used, int limit);

  /// No description provided for @freeTierRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} left today (resets daily, Japan time)'**
  String freeTierRemaining(int remaining);

  /// No description provided for @notificationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationSectionTitle;

  /// No description provided for @reminderNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder notifications'**
  String get reminderNotificationsTitle;

  /// No description provided for @notificationCheckingStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get notificationCheckingStatus;

  /// No description provided for @notificationGranted.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get notificationGranted;

  /// No description provided for @notificationDenied.
  ///
  /// In en, this message translates to:
  /// **'Not allowed (reminders won\'t be delivered)'**
  String get notificationDenied;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @notificationPermissionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications aren\'t allowed'**
  String get notificationPermissionDialogTitle;

  /// No description provided for @notificationPermissionDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to receive reminders. You can change this in the Settings app.'**
  String get notificationPermissionDialogMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @customDictionaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom dictionary'**
  String get customDictionaryTitle;

  /// No description provided for @customDictionaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Register names of friends, groups, or technical terms so they\'re prioritized during voice recognition. Adding a note also helps the AI catch and fix misspellings.'**
  String get customDictionaryDescription;

  /// No description provided for @wordLabel.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get wordLabel;

  /// No description provided for @wordHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Taro Yamada'**
  String get wordHint;

  /// No description provided for @descriptionLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionLabelOptional;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. A friend from university'**
  String get descriptionHint;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @customDictionaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No words registered yet'**
  String get customDictionaryEmpty;

  /// No description provided for @diaryMonthEmpty.
  ///
  /// In en, this message translates to:
  /// **'No diary entries this month'**
  String get diaryMonthEmpty;

  /// No description provided for @fontStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get fontStandard;

  /// No description provided for @fontMincho.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get fontMincho;

  /// No description provided for @fontHandwriting.
  ///
  /// In en, this message translates to:
  /// **'Handwritten'**
  String get fontHandwriting;

  /// No description provided for @fontPop.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get fontPop;

  /// No description provided for @fontMonospace.
  ///
  /// In en, this message translates to:
  /// **'Monospace'**
  String get fontMonospace;

  /// No description provided for @fontGothic.
  ///
  /// In en, this message translates to:
  /// **'Gothic'**
  String get fontGothic;

  /// No description provided for @fontRoundGothic.
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get fontRoundGothic;

  /// No description provided for @fontThinMincho.
  ///
  /// In en, this message translates to:
  /// **'Thin Serif'**
  String get fontThinMincho;

  /// No description provided for @fontBrush.
  ///
  /// In en, this message translates to:
  /// **'Brush'**
  String get fontBrush;

  /// No description provided for @fontRetro.
  ///
  /// In en, this message translates to:
  /// **'Retro'**
  String get fontRetro;

  /// No description provided for @fontImpact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get fontImpact;

  /// No description provided for @fontCute.
  ///
  /// In en, this message translates to:
  /// **'Cute'**
  String get fontCute;

  /// No description provided for @mediaPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select photo/video: {error}'**
  String mediaPickFailed(String error);

  /// No description provided for @pickFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose photo/video from library'**
  String get pickFromLibrary;

  /// No description provided for @backgroundSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundSheetTitle;

  /// No description provided for @backgroundNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get backgroundNone;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @fontSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get fontSheetTitle;

  /// No description provided for @setAsDefaultTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefaultTooltip;

  /// No description provided for @setAsDefaultSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefaultSnackbar;

  /// No description provided for @closeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeTooltip;

  /// No description provided for @toolbarMedia.
  ///
  /// In en, this message translates to:
  /// **'Photo/Video'**
  String get toolbarMedia;

  /// No description provided for @toolbarBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get toolbarBackground;

  /// No description provided for @toolbarText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get toolbarText;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleHint;

  /// No description provided for @bodyHint.
  ///
  /// In en, this message translates to:
  /// **'Write more here…'**
  String get bodyHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get filterThisWeek;

  /// No description provided for @filterWithinMonth.
  ///
  /// In en, this message translates to:
  /// **'Within a month'**
  String get filterWithinMonth;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @tasksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet\nTry saying \"I need to…\"'**
  String get tasksEmpty;

  /// No description provided for @tasksFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks match this filter'**
  String get tasksFilterEmpty;

  /// No description provided for @reminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderLabel;

  /// No description provided for @removeReminderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get removeReminderTooltip;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @taskContentHint.
  ///
  /// In en, this message translates to:
  /// **'Task content'**
  String get taskContentHint;

  /// No description provided for @ideasEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ideas yet\nTry saying what comes to mind'**
  String get ideasEmpty;

  /// No description provided for @editIdeaTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit idea'**
  String get editIdeaTitle;

  /// No description provided for @ideaTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Heading (optional)'**
  String get ideaTitleHint;

  /// No description provided for @ideaContentHint.
  ///
  /// In en, this message translates to:
  /// **'Idea content'**
  String get ideaContentHint;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review content'**
  String get reviewTitle;

  /// No description provided for @reviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit the text if it\'s off. Drag a card to move it between diary, idea, and task.'**
  String get reviewDescription;

  /// No description provided for @sectionDiary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get sectionDiary;

  /// No description provided for @sectionIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get sectionIdea;

  /// No description provided for @sectionTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get sectionTask;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @dragCardHere.
  ///
  /// In en, this message translates to:
  /// **'Drag a card here'**
  String get dragCardHere;

  /// No description provided for @genericProcessingError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while processing'**
  String get genericProcessingError;

  /// No description provided for @usageFetchError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load usage status'**
  String get usageFetchError;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'To-do reminders'**
  String get reminderNotificationChannelName;

  /// No description provided for @reminderNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Time-based reminders for to-dos created from your voice notes'**
  String get reminderNotificationChannelDescription;

  /// No description provided for @knowledgeBaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Second Brain'**
  String get knowledgeBaseTitle;

  /// No description provided for @knowledgeBaseDescription.
  ///
  /// In en, this message translates to:
  /// **'AI looks back across all your diary entries, ideas, and tasks to answer you.'**
  String get knowledgeBaseDescription;

  /// No description provided for @knowledgeBaseInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. What was that app idea I mentioned last month?'**
  String get knowledgeBaseInputHint;

  /// No description provided for @knowledgeBaseSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get knowledgeBaseSend;

  /// No description provided for @knowledgeBaseThinking.
  ///
  /// In en, this message translates to:
  /// **'Looking back through your past entries…'**
  String get knowledgeBaseThinking;

  /// No description provided for @knowledgeBaseEmpty.
  ///
  /// In en, this message translates to:
  /// **'There\'s nothing recorded yet. Record something, then ask again.'**
  String get knowledgeBaseEmpty;

  /// No description provided for @knowledgeBaseErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get an answer'**
  String get knowledgeBaseErrorTitle;

  /// No description provided for @weeklyReportSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly report'**
  String get weeklyReportSettingsTitle;

  /// No description provided for @weeklyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Brain Report'**
  String get weeklyReportTitle;

  /// No description provided for @weeklyReportRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get weeklyReportRetry;

  /// No description provided for @weeklyReportLoadingInsights.
  ///
  /// In en, this message translates to:
  /// **'AI is reflecting on your week…'**
  String get weeklyReportLoadingInsights;

  /// No description provided for @weeklyReportErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the report'**
  String get weeklyReportErrorTitle;

  /// No description provided for @weeklyReportEmotionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Emotional trends'**
  String get weeklyReportEmotionSectionTitle;

  /// No description provided for @weeklyReportNoEmotionData.
  ///
  /// In en, this message translates to:
  /// **'No emotional entries yet this week'**
  String get weeklyReportNoEmotionData;

  /// No description provided for @weeklyReportKeywordsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'This week\'s keywords'**
  String get weeklyReportKeywordsSectionTitle;

  /// No description provided for @weeklyReportNoKeywords.
  ///
  /// In en, this message translates to:
  /// **'No standout keywords this week'**
  String get weeklyReportNoKeywords;

  /// No description provided for @weeklyReportIdeasSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Ideas that shined'**
  String get weeklyReportIdeasSectionTitle;

  /// No description provided for @weeklyReportNoIdeas.
  ///
  /// In en, this message translates to:
  /// **'No ideas recorded yet this week'**
  String get weeklyReportNoIdeas;

  /// No description provided for @weeklyReportAchievementSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'This week\'s wins'**
  String get weeklyReportAchievementSectionTitle;

  /// No description provided for @weeklyReportTasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks completed'**
  String weeklyReportTasksCompleted(int count);

  /// No description provided for @weeklyReportDiaryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} diary entries'**
  String weeklyReportDiaryCount(int count);

  /// No description provided for @weeklyReportEncouragement.
  ///
  /// In en, this message translates to:
  /// **'You did great this week!'**
  String get weeklyReportEncouragement;

  /// No description provided for @weeklyReportAdviceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Advice for next week'**
  String get weeklyReportAdviceSectionTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
