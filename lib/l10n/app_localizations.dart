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

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account (you can also do this later in Settings)'**
  String get onboardingCreateAccount;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'The moment it crosses your mind,\njust say it out loud'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap the record button and speak — VoiceJournal takes care of the rest'**
  String get onboardingPage1Body;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'AI sorts it out for you'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Body.
  ///
  /// In en, this message translates to:
  /// **'What you say is automatically sorted into a diary entry, idea, or task'**
  String get onboardingPage2Body;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Whenever something\'s on your mind, just tap and talk'**
  String get onboardingPage3Body;

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

  /// No description provided for @maxRecordingMinutes.
  ///
  /// In en, this message translates to:
  /// **'Each recording can be up to {minutes} minutes'**
  String maxRecordingMinutes(int minutes);

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

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to an easier-on-the-eyes look'**
  String get darkModeSubtitle;

  /// No description provided for @settingsProBadge.
  ///
  /// In en, this message translates to:
  /// **'Pro only'**
  String get settingsProBadge;

  /// No description provided for @integrationsSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrationsSettingsTitle;

  /// No description provided for @integrationsCalendarRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar integration'**
  String get integrationsCalendarRowTitle;

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

  /// No description provided for @appleRemindersSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get appleRemindersSettingsTitle;

  /// No description provided for @appleRemindersScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders Integration'**
  String get appleRemindersScreenTitle;

  /// No description provided for @appleRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a list from the device\'s Reminders app. Once turned on, any task with a due date will automatically be added there, and completing it in the app marks it as completed in Reminders too.'**
  String get appleRemindersDescription;

  /// No description provided for @appleRemindersPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Reminders access wasn\'t granted. You can allow it from the system Settings app.'**
  String get appleRemindersPermissionDenied;

  /// No description provided for @appleRemindersNoLists.
  ///
  /// In en, this message translates to:
  /// **'No writable reminder lists were found. Create a list in the Reminders app, then refresh.'**
  String get appleRemindersNoLists;

  /// No description provided for @accountSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSectionTitle;

  /// No description provided for @accountSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String accountSignedInAs(String email);

  /// No description provided for @accountNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get accountNotSignedIn;

  /// No description provided for @accountNotSignedInDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google or Apple to carry your diary data over to other devices'**
  String get accountNotSignedInDescription;

  /// No description provided for @accountScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountScreenTitle;

  /// No description provided for @accountSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get accountSignInWithGoogle;

  /// No description provided for @accountSignInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get accountSignInWithApple;

  /// No description provided for @accountSignOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOutButton;

  /// No description provided for @accountRestoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore from cloud'**
  String get accountRestoreButton;

  /// No description provided for @syncErrorBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Some data failed to sync'**
  String get syncErrorBannerMessage;

  /// No description provided for @syncErrorBannerAction.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get syncErrorBannerAction;

  /// No description provided for @loadErrorBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load your data'**
  String get loadErrorBannerMessage;

  /// No description provided for @loadErrorBannerAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get loadErrorBannerAction;

  /// No description provided for @accountSyncingMessage.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get accountSyncingMessage;

  /// No description provided for @accountSyncCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get accountSyncCompleteTitle;

  /// No description provided for @accountSyncCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Sync complete.'**
  String get accountSyncCompleteMessage;

  /// No description provided for @accountErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get accountErrorTitle;

  /// No description provided for @accountErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'A network error occurred. Please try again shortly.'**
  String get accountErrorNetwork;

  /// No description provided for @accountErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again shortly.'**
  String get accountErrorUnknown;

  /// No description provided for @accountSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get accountSignOutConfirmTitle;

  /// No description provided for @accountSignOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data on this device won\'t be deleted. Sign back in anytime to resume syncing.'**
  String get accountSignOutConfirmMessage;

  /// No description provided for @accountMediaSyncFreeNote.
  ///
  /// In en, this message translates to:
  /// **'Only text (diary entries, ideas, and tasks) is backed up. Photos and videos aren\'t synced to the cloud — that\'s limited to the monthly/annual plans (not included with the lifetime plan).'**
  String get accountMediaSyncFreeNote;

  /// No description provided for @accountMediaSyncProNote.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos are backed up to the cloud too.'**
  String get accountMediaSyncProNote;

  /// No description provided for @supportSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportSectionTitle;

  /// No description provided for @contactSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactSupportTitle;

  /// No description provided for @contactSupportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'VoiceJournal Support'**
  String get contactSupportEmailSubject;

  /// No description provided for @planSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planSectionTitle;

  /// No description provided for @planCurrentTitle.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get planCurrentTitle;

  /// No description provided for @planProTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro plan'**
  String get planProTitle;

  /// No description provided for @planFreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get planFreeTitle;

  /// No description provided for @planProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Up to 15 minutes per recording, 30 recordings a day'**
  String get planProSubtitle;

  /// No description provided for @planFreeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Up to 60 seconds per recording, 3 recordings a day for free'**
  String get planFreeSubtitle;

  /// No description provided for @planManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get planManage;

  /// No description provided for @planUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get planUpgrade;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro plan'**
  String get paywallTitle;

  /// No description provided for @paywallSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'What Pro unlocks'**
  String get paywallSectionTitle;

  /// No description provided for @paywallSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited access to every Pro feature'**
  String get paywallSectionSubtitle;

  /// No description provided for @paywallBenefitDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Longer recordings'**
  String get paywallBenefitDurationTitle;

  /// No description provided for @paywallBenefitDurationBefore.
  ///
  /// In en, this message translates to:
  /// **'60 sec'**
  String get paywallBenefitDurationBefore;

  /// No description provided for @paywallBenefitDurationAfter.
  ///
  /// In en, this message translates to:
  /// **'15 min'**
  String get paywallBenefitDurationAfter;

  /// No description provided for @paywallBenefitDurationDesc.
  ///
  /// In en, this message translates to:
  /// **'Talk as long as you need without losing the details'**
  String get paywallBenefitDurationDesc;

  /// No description provided for @paywallBenefitCountTitle.
  ///
  /// In en, this message translates to:
  /// **'More uses per day'**
  String get paywallBenefitCountTitle;

  /// No description provided for @paywallBenefitCountBefore.
  ///
  /// In en, this message translates to:
  /// **'3 / day'**
  String get paywallBenefitCountBefore;

  /// No description provided for @paywallBenefitCountAfter.
  ///
  /// In en, this message translates to:
  /// **'30 / day'**
  String get paywallBenefitCountAfter;

  /// No description provided for @paywallBenefitCountDesc.
  ///
  /// In en, this message translates to:
  /// **'Capture every thought, whenever it strikes'**
  String get paywallBenefitCountDesc;

  /// No description provided for @paywallBenefitCustomBackgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Add '**
  String get paywallBenefitCustomBackgroundTitle;

  /// No description provided for @paywallBenefitCustomBackgroundHighlight.
  ///
  /// In en, this message translates to:
  /// **'your own photo'**
  String get paywallBenefitCustomBackgroundHighlight;

  /// No description provided for @paywallBenefitCustomBackgroundDesc.
  ///
  /// In en, this message translates to:
  /// **'Make every entry feel like yours'**
  String get paywallBenefitCustomBackgroundDesc;

  /// No description provided for @paywallBenefitKnowledgeBaseHighlight.
  ///
  /// In en, this message translates to:
  /// **'Ask (second brain)'**
  String get paywallBenefitKnowledgeBaseHighlight;

  /// No description provided for @paywallBenefitKnowledgeBaseSuffix.
  ///
  /// In en, this message translates to:
  /// **' is unlocked'**
  String get paywallBenefitKnowledgeBaseSuffix;

  /// No description provided for @paywallBenefitKnowledgeBaseDesc.
  ///
  /// In en, this message translates to:
  /// **'AI digs through everything you\'ve recorded to help'**
  String get paywallBenefitKnowledgeBaseDesc;

  /// No description provided for @paywallBenefitWeeklyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Brain Report'**
  String get paywallBenefitWeeklyReportTitle;

  /// No description provided for @paywallBenefitWeeklyReportDesc.
  ///
  /// In en, this message translates to:
  /// **'AI reads your week and delivers the highlights'**
  String get paywallBenefitWeeklyReportDesc;

  /// No description provided for @paywallBenefitMediaSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud photo & video sync'**
  String get paywallBenefitMediaSyncTitle;

  /// No description provided for @paywallBenefitMediaSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep your memories safely backed up'**
  String get paywallBenefitMediaSyncDesc;

  /// No description provided for @paywallBenefitMediaSyncBadge.
  ///
  /// In en, this message translates to:
  /// **'Monthly / annual plans only'**
  String get paywallBenefitMediaSyncBadge;

  /// No description provided for @paywallUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load plans right now. Please try again later.'**
  String get paywallUnavailable;

  /// No description provided for @paywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestore;

  /// No description provided for @paywallTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get paywallTerms;

  /// No description provided for @paywallPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get paywallPrivacy;

  /// No description provided for @paywallPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again later.'**
  String get paywallPurchaseFailed;

  /// No description provided for @paywallRestoreNotFound.
  ///
  /// In en, this message translates to:
  /// **'No restorable purchase was found.'**
  String get paywallRestoreNotFound;

  /// No description provided for @paywallPlanMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallPlanMonthly;

  /// No description provided for @paywallPlanAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get paywallPlanAnnual;

  /// No description provided for @paywallPlanLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get paywallPlanLifetime;

  /// No description provided for @paywallPlanRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get paywallPlanRecommended;

  /// No description provided for @paywallPlanLifetimeCaption.
  ///
  /// In en, this message translates to:
  /// **'Everything except cloud photo/video sync'**
  String get paywallPlanLifetimeCaption;

  /// No description provided for @paywallPlanComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get paywallPlanComingSoon;

  /// No description provided for @paywallContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paywallContinueButton;

  /// No description provided for @homeUsageToday.
  ///
  /// In en, this message translates to:
  /// **'Today {used} / {limit}'**
  String homeUsageToday(int used, int limit);

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

  /// No description provided for @diaryDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'No diary entries this day'**
  String get diaryDayEmpty;

  /// No description provided for @diaryPickDateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get diaryPickDateTooltip;

  /// No description provided for @diaryPreviousWeekTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get diaryPreviousWeekTooltip;

  /// No description provided for @diaryNextWeekTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get diaryNextWeekTooltip;

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

  /// No description provided for @pickPhotosFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose photos'**
  String get pickPhotosFromLibrary;

  /// No description provided for @pickPhotosFromLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick photos from your library to add'**
  String get pickPhotosFromLibrarySubtitle;

  /// No description provided for @pickVideoFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose a video'**
  String get pickVideoFromLibrary;

  /// No description provided for @pickVideoFromLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a video from your library to add'**
  String get pickVideoFromLibrarySubtitle;

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

  /// No description provided for @emotionSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Emotion'**
  String get emotionSheetTitle;

  /// No description provided for @emotionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get emotionNone;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @diaryBgFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get diaryBgFruit;

  /// No description provided for @diaryBgMintPlant.
  ///
  /// In en, this message translates to:
  /// **'Botanical Notes'**
  String get diaryBgMintPlant;

  /// No description provided for @diaryBgCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get diaryBgCoffee;

  /// No description provided for @diaryBgCake.
  ///
  /// In en, this message translates to:
  /// **'Cake'**
  String get diaryBgCake;

  /// No description provided for @diaryBgPicnic.
  ///
  /// In en, this message translates to:
  /// **'Bread Basket'**
  String get diaryBgPicnic;

  /// No description provided for @diaryBgHeartBalloon.
  ///
  /// In en, this message translates to:
  /// **'Heart Balloons'**
  String get diaryBgHeartBalloon;

  /// No description provided for @diaryBgSakuraStation.
  ///
  /// In en, this message translates to:
  /// **'Sakura Station'**
  String get diaryBgSakuraStation;

  /// No description provided for @diaryBgAutumnLeaves.
  ///
  /// In en, this message translates to:
  /// **'Autumn Leaves'**
  String get diaryBgAutumnLeaves;

  /// No description provided for @diaryBgStudyDesk.
  ///
  /// In en, this message translates to:
  /// **'Study Desk'**
  String get diaryBgStudyDesk;

  /// No description provided for @diaryBgHome.
  ///
  /// In en, this message translates to:
  /// **'At Home'**
  String get diaryBgHome;

  /// No description provided for @diaryBgParkDay.
  ///
  /// In en, this message translates to:
  /// **'Dandelion Field'**
  String get diaryBgParkDay;

  /// No description provided for @diaryBgNightSky.
  ///
  /// In en, this message translates to:
  /// **'Night Sky'**
  String get diaryBgNightSky;

  /// No description provided for @diaryBgSadBoy.
  ///
  /// In en, this message translates to:
  /// **'Feeling Down'**
  String get diaryBgSadBoy;

  /// No description provided for @diaryBgBeachGirl.
  ///
  /// In en, this message translates to:
  /// **'By the Sea'**
  String get diaryBgBeachGirl;

  /// No description provided for @diaryBgSleepingCat.
  ///
  /// In en, this message translates to:
  /// **'Sleeping Cat'**
  String get diaryBgSleepingCat;

  /// No description provided for @fontSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get fontSheetTitle;

  /// No description provided for @fontSheetSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Heading size'**
  String get fontSheetSizeLabel;

  /// No description provided for @fontSheetColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get fontSheetColorLabel;

  /// No description provided for @fontSheetStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Font style'**
  String get fontSheetStyleLabel;

  /// No description provided for @closeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeTooltip;

  /// No description provided for @favoriteSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Favorite settings'**
  String get favoriteSettingsTooltip;

  /// No description provided for @favoriteSettingsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite settings'**
  String get favoriteSettingsSheetTitle;

  /// No description provided for @favoriteSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'The default text style and background used for newly created diary entries'**
  String get favoriteSettingsDescription;

  /// No description provided for @addCustomBackgroundTile.
  ///
  /// In en, this message translates to:
  /// **'Add your own photo'**
  String get addCustomBackgroundTile;

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
  /// **'Notification reminder'**
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

  /// No description provided for @allDayLabel.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDayLabel;

  /// No description provided for @taskScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Start & End Time'**
  String get taskScheduleLabel;

  /// No description provided for @startTimeCaption.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startTimeCaption;

  /// No description provided for @endTimeCaption.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endTimeCaption;

  /// No description provided for @addStartTime.
  ///
  /// In en, this message translates to:
  /// **'Set start time'**
  String get addStartTime;

  /// No description provided for @removeStartTimeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove start time'**
  String get removeStartTimeTooltip;

  /// No description provided for @addEndTime.
  ///
  /// In en, this message translates to:
  /// **'Add end time'**
  String get addEndTime;

  /// No description provided for @removeEndTimeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove end time'**
  String get removeEndTimeTooltip;

  /// No description provided for @manualTaskFabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get manualTaskFabTooltip;

  /// No description provided for @manualTaskScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get manualTaskScreenTitle;

  /// No description provided for @manualTaskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Task (e.g. Buy milk)'**
  String get manualTaskTitleHint;

  /// No description provided for @manualTaskTitleRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a task'**
  String get manualTaskTitleRequiredError;

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

  /// No description provided for @backgroundRecordingChannelName.
  ///
  /// In en, this message translates to:
  /// **'Background recording'**
  String get backgroundRecordingChannelName;

  /// No description provided for @backgroundRecordingChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Keeps recording running while the app is backgrounded or the screen is off'**
  String get backgroundRecordingChannelDescription;

  /// No description provided for @backgroundRecordingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording…'**
  String get backgroundRecordingNotificationTitle;

  /// No description provided for @backgroundRecordingNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Tap to return to the app'**
  String get backgroundRecordingNotificationText;

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

  /// No description provided for @weeklyReportNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Weekly Brain Report is ready!'**
  String get weeklyReportNotificationTitle;

  /// No description provided for @weeklyReportNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'AI has looked back on your week. Tap to see it.'**
  String get weeklyReportNotificationBody;

  /// No description provided for @weeklyReportNotificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Weekly report notifications'**
  String get weeklyReportNotificationChannelName;

  /// No description provided for @weeklyReportNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifies you every Sunday at 8pm when your Weekly Brain Report is ready'**
  String get weeklyReportNotificationChannelDescription;

  /// No description provided for @weeklyReportHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Past reports'**
  String get weeklyReportHistoryTooltip;

  /// No description provided for @weeklyReportHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report History'**
  String get weeklyReportHistoryTitle;

  /// No description provided for @weeklyReportHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved reports yet'**
  String get weeklyReportHistoryEmpty;

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

  /// No description provided for @knowledgeBaseProLockedDescription.
  ///
  /// In en, this message translates to:
  /// **'Chatting across all your entries is a Pro feature. Upgrade to unlock it.'**
  String get knowledgeBaseProLockedDescription;

  /// No description provided for @weeklyReportSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Brain Report'**
  String get weeklyReportSettingsTitle;

  /// No description provided for @weeklyReportSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delivered every week'**
  String get weeklyReportSettingsSubtitle;

  /// No description provided for @weeklyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Brain Report'**
  String get weeklyReportTitle;

  /// No description provided for @weeklyReportProLockedDescription.
  ///
  /// In en, this message translates to:
  /// **'The Weekly Brain Report is a Pro feature. Upgrade to unlock it.'**
  String get weeklyReportProLockedDescription;

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

  /// No description provided for @weeklyReportCalendarSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Emotion calendar'**
  String get weeklyReportCalendarSectionTitle;

  /// No description provided for @weeklyReportCategorySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Category mix'**
  String get weeklyReportCategorySectionTitle;

  /// No description provided for @weeklyReportNoCategoryData.
  ///
  /// In en, this message translates to:
  /// **'No entries yet this week'**
  String get weeklyReportNoCategoryData;

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

  /// No description provided for @weeklyReportHighlightSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'This week\'s highlight'**
  String get weeklyReportHighlightSectionTitle;

  /// No description provided for @weeklyReportNoHighlight.
  ///
  /// In en, this message translates to:
  /// **'No diary entries yet this week'**
  String get weeklyReportNoHighlight;

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

  /// No description provided for @weeklyReportShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get weeklyReportShareTooltip;

  /// No description provided for @weeklyReportShareCaption.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what my week looked like 📝 #VoiceJournal'**
  String get weeklyReportShareCaption;
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
