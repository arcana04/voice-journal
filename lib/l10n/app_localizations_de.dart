// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navRecord => 'Aufnahme';

  @override
  String get navDiary => 'Tagebuch';

  @override
  String get navIdea => 'Idee';

  @override
  String get navTask => 'Aufgabe';

  @override
  String get navKnowledgeBase => 'Fragen';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingGetStarted => 'Loslegen';

  @override
  String get onboardingCreateAccount =>
      'Konto erstellen (kannst du auch später in den Einstellungen tun)';

  @override
  String get onboardingPage1Title =>
      'Sobald dir etwas einfällt,\nsag es einfach laut';

  @override
  String get onboardingPage1Body =>
      'Tippe auf den Aufnahmeknopf und sprich — Voice Brain kümmert sich um den Rest';

  @override
  String get onboardingPage2Title => 'Die KI sortiert es für dich';

  @override
  String get onboardingPage2Body =>
      'Was du sagst, wird von der KI transkribiert und automatisch in einen Tagebucheintrag, eine Idee oder eine Aufgabe einsortiert. Deine Stimme wird sicher behandelt, als Daten, die nur dir gehören.';

  @override
  String get onboardingFreeTierTitle => 'Kostenlos sofort nutzbar';

  @override
  String get onboardingFreeTierBody =>
      'Der kostenlose Plan umfasst 3 Aufnahmen pro Tag, je bis zu 60 Sekunden. Möchtest du mehr? Schau dir den Pro-Plan für längere, häufigere Aufnahmen an.';

  @override
  String get onboardingMicTitle => 'Wir brauchen Mikrofonzugriff';

  @override
  String get onboardingMicBody =>
      'Voice Brain nutzt dein Mikrofon zum Aufnehmen. Wenn als Nächstes die Berechtigungsabfrage erscheint, tippe bitte auf \"Erlauben\".';

  @override
  String get onboardingPage3Title => 'Los geht\'s';

  @override
  String get onboardingPage3Body =>
      'Wann immer dir etwas durch den Kopf geht, tippe einfach und sprich';

  @override
  String get emotionFatigue => 'Müdigkeit';

  @override
  String get emotionLove => 'Liebe';

  @override
  String get emotionAnxious => 'Ängstlich';

  @override
  String get emotionExcited => 'Aufgeregt';

  @override
  String get emotionJoy => 'Freude';

  @override
  String get emotionSadness => 'Traurigkeit';

  @override
  String get emotionAnger => 'Wut';

  @override
  String get emotionSatisfaction => 'Zufriedenheit';

  @override
  String get emotionNeutral => 'Neutral';

  @override
  String get emotionGratitude => 'Dankbarkeit';

  @override
  String get emotionHappy => 'Glücklich';

  @override
  String get emotionFunny => 'Amüsiert';

  @override
  String get emotionRelief => 'Erleichterung';

  @override
  String get emotionCalm => 'Ruhig';

  @override
  String get emotionBoredom => 'Gelangweilt';

  @override
  String get emotionRegret => 'Bedauern';

  @override
  String get emotionDislike => 'Abneigung';

  @override
  String get confirmDeleteTitle => 'Das löschen?';

  @override
  String get confirmDeleteMessage =>
      'Das Löschen dieses Eintrags kann nicht rückgängig gemacht werden.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get editTooltip => 'Bearbeiten';

  @override
  String get micPermissionDenied => 'Mikrofonzugriff ist nicht erlaubt';

  @override
  String get recordingStopFailedTitle =>
      'Aufnahme konnte nicht gestoppt werden';

  @override
  String get recordingErrorTitle => 'Aufnahmefehler';

  @override
  String get recordingSaveFailed => 'Aufnahme konnte nicht gespeichert werden';

  @override
  String get processingErrorTitle =>
      'Beim Verarbeiten ist ein Fehler aufgetreten';

  @override
  String statusError(String message) {
    return 'Fehler: $message';
  }

  @override
  String statusOrganized(String summary) {
    return 'Organisiert: $summary';
  }

  @override
  String get statusTapToRecord => 'Zum Aufnehmen tippen';

  @override
  String get statusRecording => 'Aufnahme läuft… nochmal tippen zum Stoppen';

  @override
  String get statusProcessing => 'Die KI analysiert…';

  @override
  String get statusProcessingSorting =>
      'Wird in Tagebuch, Ideen und Aufgaben sortiert…';

  @override
  String get statusProcessingFinishing => 'Wird fertiggestellt…';

  @override
  String maxRecordingSeconds(int seconds) {
    return 'Jede Aufnahme kann bis zu $seconds Sekunden dauern';
  }

  @override
  String maxRecordingMinutes(int minutes) {
    return 'Jede Aufnahme kann bis zu $minutes Minuten dauern';
  }

  @override
  String streakTooltip(int days) {
    return '$days-Tage-Serie';
  }

  @override
  String get textComposeTooltip => 'Als Text eingeben';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String get menuCustomDictionary => 'Eigenes Wörterbuch';

  @override
  String get menuSummaryLevel => 'KI-Zusammenfassungsstufe';

  @override
  String get textComposerTitle => 'Als Text eingeben';

  @override
  String get textComposerDescription =>
      'Verwende dies, wenn du nicht sprechen kannst. Die KI sortiert es genau wie eine Aufnahme in einen Tagebucheintrag, eine Aufgabe oder eine Idee ein.';

  @override
  String get textComposerHint =>
      'z. B. Morgen um 15 Uhr Zahnarzttermin vereinbaren';

  @override
  String get textComposerSubmit => 'Von der KI analysieren lassen';

  @override
  String get summaryLevelSheetTitle => 'KI-Zusammenfassungsstufe';

  @override
  String get summaryLevelSheetDescription =>
      'Wähle, wie stark die KI den Tagebuchinhalt aus Aufnahmen oder Text kürzt. Dies wirkt sich nicht darauf aus, wie prägnant Aufgaben sind.';

  @override
  String get summaryLevelPreserveLabel => 'Bewahren';

  @override
  String get summaryLevelStandardLabel => 'Standard';

  @override
  String get summaryLevelCompactLabel => 'Kompakt';

  @override
  String get summaryLevelPreserveDescription =>
      'Behält Gefühle, Formulierungen und Namen genau so, wie sie gesprochen wurden, ohne zusammenzufassen.';

  @override
  String get summaryLevelStandardDescription =>
      'Ordnet redundante Wiederholungen, während eine natürliche Tagebuchlänge erhalten bleibt.';

  @override
  String get summaryLevelCompactDescription =>
      'Verdichtet alles auf das Wesentliche in 1-2 Sätzen.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get displaySectionTitle => 'Anzeige';

  @override
  String get darkModeTitle => 'Dunkler Modus';

  @override
  String get darkModeSubtitle => 'Zu einem augenschonenderen Look wechseln';

  @override
  String get themeColorTitle => 'Designfarbe';

  @override
  String get themeColorSubtitle => 'Die allgemeine Akzentfarbe der App ändern';

  @override
  String get themeColorSheetTitle => 'Eine Designfarbe wählen';

  @override
  String get settingsProBadge => 'Nur Pro';

  @override
  String get integrationsSettingsTitle => 'Integrationen';

  @override
  String get integrationsCalendarRowTitle => 'Kalenderintegration';

  @override
  String get integrationsScreenTitle => 'Integrationen';

  @override
  String get integrationsDescription =>
      'Wähle einen bereits auf diesem Gerät eingerichteten Kalender (wie iOS-Kalender oder ein in den Systemeinstellungen hinzugefügtes Google-Konto). Sobald aktiviert, wird jede Aufgabe mit einem bestimmten Datum und einer Uhrzeit automatisch dort als Ereignis hinzugefügt.';

  @override
  String get integrationsOff => 'Aus';

  @override
  String get integrationsPermissionDenied =>
      'Kalenderzugriff wurde nicht gewährt. Du kannst ihn in der Systemeinstellungen-App erlauben.';

  @override
  String get integrationsNoCalendars =>
      'Auf diesem Gerät wurden keine beschreibbaren Kalender gefunden. Füge in der Systemeinstellungen-App einen Kalender (wie ein Google-Konto) hinzu und aktualisiere dann.';

  @override
  String get integrationsRefresh => 'Aktualisieren';

  @override
  String get appleRemindersSettingsTitle => 'Erinnerungen';

  @override
  String get appleRemindersScreenTitle => 'Erinnerungen-Integration';

  @override
  String get appleRemindersDescription =>
      'Wähle eine Liste aus der Erinnerungen-App des Geräts. Sobald aktiviert, wird jede Aufgabe mit Fälligkeitsdatum automatisch dort hinzugefügt, und das Erledigen in der App markiert sie auch in Erinnerungen als erledigt.';

  @override
  String get appleRemindersPermissionDenied =>
      'Erinnerungen-Zugriff wurde nicht gewährt. Du kannst ihn in der Systemeinstellungen-App erlauben.';

  @override
  String get appleRemindersNoLists =>
      'Es wurden keine beschreibbaren Erinnerungslisten gefunden. Erstelle eine Liste in der Erinnerungen-App und aktualisiere dann.';

  @override
  String get accountSectionTitle => 'Konto';

  @override
  String accountSignedInAs(String email) {
    return 'Angemeldet als $email';
  }

  @override
  String get accountNotSignedIn => 'Nicht angemeldet';

  @override
  String get accountNotSignedInDescription =>
      'Melde dich mit Google oder Apple an, um deine Tagebuchdaten auf andere Geräte zu übertragen';

  @override
  String get accountScreenTitle => 'Konto';

  @override
  String get accountSignInWithGoogle => 'Mit Google anmelden';

  @override
  String get accountSignInWithApple => 'Mit Apple anmelden';

  @override
  String get accountSignOutButton => 'Abmelden';

  @override
  String get accountRestoreButton => 'Aus der Cloud wiederherstellen';

  @override
  String get watchPairingButton => 'Apple Watch koppeln';

  @override
  String get watchPairingSuccessTitle => 'Gekoppelt';

  @override
  String get watchPairingSuccessMessage =>
      'Deine Apple Watch ist gekoppelt. Du kannst jetzt allein auf der Watch aufnehmen.';

  @override
  String get syncErrorBannerMessage =>
      'Einige Daten konnten nicht synchronisiert werden';

  @override
  String get syncErrorBannerAction => 'Prüfen';

  @override
  String get loadErrorBannerMessage =>
      'Deine Daten konnten nicht geladen werden';

  @override
  String get loadErrorBannerAction => 'Erneut versuchen';

  @override
  String get mediaStorageWarningBannerMessage =>
      'Dein Foto-/Video-Cloud-Speicher ist fast voll';

  @override
  String get mediaStorageFullBannerMessage =>
      'Foto-/Video-Cloud-Speicher ist voll. Neue Fotos und Videos werden nicht synchronisiert';

  @override
  String get mediaStorageBannerAction => 'Aufräumen';

  @override
  String get accountSyncingMessage => 'Synchronisiere…';

  @override
  String get accountSyncCompleteTitle => 'Fertig';

  @override
  String get accountSyncCompleteMessage => 'Synchronisierung abgeschlossen.';

  @override
  String get accountErrorTitle => 'Fehler';

  @override
  String get accountErrorNetwork =>
      'Ein Netzwerkfehler ist aufgetreten. Bitte versuche es in Kürze erneut.';

  @override
  String get accountErrorUnknown =>
      'Etwas ist schiefgelaufen. Bitte versuche es in Kürze erneut.';

  @override
  String get accountSignOutConfirmTitle => 'Abmelden?';

  @override
  String get accountSignOutConfirmMessage =>
      'Deine Daten auf diesem Gerät werden nicht gelöscht. Melde dich jederzeit wieder an, um die Synchronisierung fortzusetzen.';

  @override
  String get accountDeleteButton => 'Konto löschen';

  @override
  String get accountDeleteConfirmTitle => 'Dein Konto löschen?';

  @override
  String get accountDeleteConfirmMessage =>
      'Dies kann nicht rückgängig gemacht werden. Deine Tagebucheinträge, Ideen und Aufgaben in der Cloud, deine Fotos und Videos sowie alles auf diesem Gerät werden dauerhaft gelöscht.';

  @override
  String get accountDeleteConfirmButton => 'Löschen';

  @override
  String get accountDeleteCompleteTitle => 'Gelöscht';

  @override
  String get accountDeleteCompleteMessage =>
      'Dein Konto und alle zugehörigen Daten wurden gelöscht.';

  @override
  String get accountMediaSyncFreeNote =>
      'Es wird nur Text (Tagebucheinträge, Ideen und Aufgaben) gesichert. Fotos und Videos werden nicht mit der Cloud synchronisiert — das ist den monatlichen/jährlichen Plänen vorbehalten (nicht im Lebenszeit-Plan enthalten).';

  @override
  String get accountMediaSyncProNote =>
      'Fotos und Videos werden ebenfalls in der Cloud gesichert.';

  @override
  String get supportSectionTitle => 'Support';

  @override
  String get contactSupportTitle => 'Kontaktiere uns';

  @override
  String get contactSupportEmailSubject => 'Voice Brain Support';

  @override
  String get planSectionTitle => 'Plan';

  @override
  String get planCurrentTitle => 'Aktueller Plan';

  @override
  String get planProTitle => 'Pro-Plan';

  @override
  String get planFreeTitle => 'Kostenloser Plan';

  @override
  String get planProSubtitle =>
      'Bis zu 15 Minuten pro Aufnahme, 30 Aufnahmen pro Tag';

  @override
  String get planFreeSubtitle =>
      'Bis zu 60 Sekunden pro Aufnahme, 3 kostenlose Aufnahmen pro Tag';

  @override
  String get planManage => 'Verwalten';

  @override
  String get planUpgrade => 'Upgrade';

  @override
  String get paywallTitle => 'Pro-Plan';

  @override
  String get paywallSectionTitle => 'Was Pro freischaltet';

  @override
  String get paywallSectionSubtitle =>
      'Unbegrenzter Zugriff auf alle Pro-Funktionen';

  @override
  String get paywallBenefitDurationTitle => 'Längere Aufnahmen';

  @override
  String get paywallBenefitDurationBefore => '60 Sek.';

  @override
  String get paywallBenefitDurationAfter => '15 Min.';

  @override
  String get paywallBenefitDurationDesc =>
      'Sprich so lange du brauchst, ohne Details zu verlieren';

  @override
  String get paywallBenefitCountTitle => 'Mehr Nutzungen pro Tag';

  @override
  String get paywallBenefitCountBefore => '3 / Tag';

  @override
  String get paywallBenefitCountAfter => '30 / Tag';

  @override
  String get paywallBenefitCountDesc =>
      'Halte jeden Gedanken fest, wann immer er dir kommt';

  @override
  String get paywallMonthlyCapNote =>
      '* Die gesamte Aufnahmezeit ist auf 240 Minuten pro Monat begrenzt. Wenn du das Limit erreichst, kannst du ein zusätzliches Minutenpaket kaufen, um weiterzumachen.';

  @override
  String get paywallBenefitCustomBackgroundTitle => 'Füge ';

  @override
  String get paywallBenefitCustomBackgroundHighlight => 'dein eigenes Foto';

  @override
  String get paywallBenefitCustomBackgroundDesc =>
      'Lass jeden Eintrag wie deinen eigenen wirken';

  @override
  String get paywallBenefitImageLayoutTitle => 'Fotos frei anordnen';

  @override
  String get paywallBenefitImageLayoutDesc =>
      'Ziehen zum Verschieben und Größe mit einem Schieberegler auf jedem Eintrag ändern';

  @override
  String get paywallBenefitKnowledgeBaseHighlight => 'Fragen (zweites Gehirn)';

  @override
  String get paywallBenefitKnowledgeBaseSuffix => ' ist freigeschaltet';

  @override
  String get paywallBenefitKnowledgeBaseDesc =>
      'Die KI durchsucht alles, was du aufgenommen hast, um zu helfen';

  @override
  String get paywallBenefitWeeklyReportTitle => 'Wöchentlicher Gehirnbericht';

  @override
  String get paywallBenefitWeeklyReportDesc =>
      'Die KI liest deine Woche und liefert die Highlights';

  @override
  String get paywallBenefitMediaSyncTitle =>
      'Cloud-Synchronisierung für Fotos & Videos';

  @override
  String get paywallBenefitMediaSyncDesc =>
      'Halte deine Erinnerungen sicher gesichert';

  @override
  String get paywallBenefitMediaSyncBadge => 'Nur monatliche/jährliche Pläne';

  @override
  String get paywallUnavailable =>
      'Pläne konnten gerade nicht geladen werden. Bitte versuche es später erneut.';

  @override
  String get paywallRestore => 'Käufe wiederherstellen';

  @override
  String get paywallTerms => 'Nutzungsbedingungen';

  @override
  String get paywallPrivacy => 'Datenschutzerklärung';

  @override
  String get paywallPurchaseFailed =>
      'Etwas ist schiefgelaufen. Bitte versuche es später erneut.';

  @override
  String get paywallRestoreNotFound =>
      'Kein wiederherstellbarer Kauf gefunden.';

  @override
  String get paywallPlanMonthly => 'Monatlich';

  @override
  String get paywallPlanAnnual => 'Jährlich';

  @override
  String get paywallPlanLifetime => 'Lebenszeit';

  @override
  String get paywallPlanRecommended => 'Empfohlen';

  @override
  String get paywallPlanLifetimeCaption =>
      'Cloud-Synchronisierung für Fotos/Videos nicht enthalten';

  @override
  String get paywallPlanComingSoon => 'Demnächst';

  @override
  String get paywallContinueButton => 'Weiter';

  @override
  String homeUsageToday(int used, int limit) {
    return 'Heute $used / $limit';
  }

  @override
  String homeUsageMonth(int usedMinutes, int limitMinutes) {
    return 'Diesen Monat $usedMinutes / $limitMinutes Min.';
  }

  @override
  String get buyMinutesCta => 'Mehr Minuten kaufen';

  @override
  String get buyMinutesTitle => 'Zusätzliche Minuten kaufen';

  @override
  String get buyMinutesDescription =>
      'Du hast das Aufnahmezeitlimit für diesen Monat erreicht. Kaufe ein zusätzliches Minutenpaket, um sofort weiter aufzunehmen, ohne auf den nächsten Monat zu warten.';

  @override
  String get buyMinutesDescriptionProactive =>
      'Pro- und Lebenszeit-Pläne beinhalten 240 Minuten Aufnahmezeit pro Monat. Du kannst auch im Voraus ein zusätzliches 60-Minuten-Paket kaufen, für den Fall, dass du dieses Limit erreichst.';

  @override
  String get buyMinutesUnavailable =>
      'Das zusätzliche Minutenpaket ist gerade nicht verfügbar. Bitte versuche es später erneut.';

  @override
  String get buyMinutesPurchaseFailed =>
      'Der Kauf ist fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get buyMinutesPurchaseSuccess =>
      'Zusätzliche Minuten hinzugefügt. Du kannst jetzt weiter aufnehmen.';

  @override
  String buyMinutesPurchaseButton(String price) {
    return '+60 Min. kaufen ($price)';
  }

  @override
  String get notificationSectionTitle => 'Benachrichtigungen';

  @override
  String get reminderNotificationsTitle => 'Erinnerungsbenachrichtigungen';

  @override
  String get notificationCheckingStatus => 'Wird geprüft…';

  @override
  String get notificationGranted => 'Erlaubt';

  @override
  String get notificationDenied =>
      'Nicht erlaubt (Erinnerungen werden nicht zugestellt)';

  @override
  String get allow => 'Erlauben';

  @override
  String get notificationPermissionDialogTitle =>
      'Benachrichtigungen sind nicht erlaubt';

  @override
  String get notificationPermissionDialogMessage =>
      'Erlaube Benachrichtigungen, um Erinnerungen zu erhalten. Du kannst dies in der Einstellungen-App ändern.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get customDictionaryTitle => 'Eigenes Wörterbuch';

  @override
  String get customDictionaryDescription =>
      'Registriere Namen von Freunden, Gruppen oder Fachbegriffen, damit sie bei der Spracherkennung bevorzugt werden. Das Hinzufügen einer Notiz hilft der KI auch dabei, Rechtschreibfehler zu erkennen und zu korrigieren.';

  @override
  String get wordLabel => 'Wort';

  @override
  String get wordHint => 'z. B. Max Mustermann';

  @override
  String get descriptionLabelOptional => 'Beschreibung (optional)';

  @override
  String get descriptionHint => 'z. B. Ein Freund von der Universität';

  @override
  String get add => 'Hinzufügen';

  @override
  String get customDictionaryEmpty => 'Noch keine Wörter registriert';

  @override
  String get diaryDayEmpty => 'Keine Tagebucheinträge an diesem Tag';

  @override
  String get diaryPickDateTooltip => 'Datum auswählen';

  @override
  String get diaryPreviousWeekTooltip => 'Vorherige Woche';

  @override
  String get diaryNextWeekTooltip => 'Nächste Woche';

  @override
  String get fontStandard => 'Standard';

  @override
  String get fontMincho => 'Serif';

  @override
  String get fontHandwriting => 'Handschrift';

  @override
  String get fontPop => 'Pop';

  @override
  String get fontMonospace => 'Monospace';

  @override
  String get fontGothic => 'Gothic';

  @override
  String get fontRoundGothic => 'Rund';

  @override
  String get fontThinMincho => 'Dünne Serif';

  @override
  String get fontBrush => 'Pinsel';

  @override
  String get fontRetro => 'Retro';

  @override
  String get fontImpact => 'Impact';

  @override
  String get fontCute => 'Niedlich';

  @override
  String mediaPickFailed(String error) {
    return 'Foto/Video konnte nicht ausgewählt werden: $error';
  }

  @override
  String get pickPhotosFromLibrary => 'Fotos auswählen';

  @override
  String get pickPhotosFromLibrarySubtitle =>
      'Wähle Fotos aus deiner Mediathek zum Hinzufügen';

  @override
  String get pickVideoFromLibrary => 'Video auswählen';

  @override
  String get pickVideoFromLibrarySubtitle =>
      'Wähle ein Video aus deiner Mediathek zum Hinzufügen';

  @override
  String get backgroundSheetTitle => 'Hintergrund';

  @override
  String get backgroundNone => 'Kein';

  @override
  String get emotionSheetTitle => 'Emotion';

  @override
  String get emotionNone => 'Keine';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get diaryBgFruit => 'Obst';

  @override
  String get diaryBgMintPlant => 'Botanische Notizen';

  @override
  String get diaryBgCoffee => 'Kaffee';

  @override
  String get diaryBgCake => 'Kuchen';

  @override
  String get diaryBgPicnic => 'Brotkorb';

  @override
  String get diaryBgHeartBalloon => 'Herzballons';

  @override
  String get diaryBgParkDay => 'Löwenzahnwiese';

  @override
  String get diaryBgNightSky => 'Nachthimmel';

  @override
  String get diaryBgSleepingCat => 'Schlafende Katze';

  @override
  String get diaryBgBlueCheckBouquet => 'Blau kariertes Blumensträußchen';

  @override
  String get diaryBgVintageCamera => 'Vintage-Kamera';

  @override
  String get diaryBgShopping => 'Einkaufen';

  @override
  String get diaryBgNewYork => 'New York';

  @override
  String get diaryBgBeach => 'Strand';

  @override
  String get diaryBgPalmTree => 'Palme';

  @override
  String get diaryBgEuropeanStreet => 'Europäische Straße';

  @override
  String get diaryBgRunning => 'Laufen';

  @override
  String get diaryBgLivingRoom => 'Wohnzimmer';

  @override
  String get diaryBgMusicNote => 'Musiknote';

  @override
  String get diaryBgLetter => 'Brief';

  @override
  String get diaryBgDeepSea => 'Tiefsee';

  @override
  String get diaryBgSnow => 'Schnee';

  @override
  String get diaryBgSoccerBall => 'Fußball';

  @override
  String get diaryBgLuxuryFrame => 'Luxusrahmen';

  @override
  String get diaryBgClock => 'Uhr';

  @override
  String get fontSheetTitle => 'Schriftart';

  @override
  String get fontSheetSizeLabel => 'Überschriftgröße';

  @override
  String get fontSheetColorLabel => 'Textfarbe';

  @override
  String get fontSheetStyleLabel => 'Schriftstil';

  @override
  String get closeTooltip => 'Schließen';

  @override
  String get favoriteSettingsTooltip => 'Bevorzugte Einstellungen';

  @override
  String get favoriteSettingsSheetTitle => 'Bevorzugte Einstellungen';

  @override
  String get favoriteSettingsDescription =>
      'Der Standard-Textstil und -Hintergrund für neu erstellte Tagebucheinträge';

  @override
  String get addCustomBackgroundTile => 'Eigenes Foto hinzufügen';

  @override
  String get toolbarMedia => 'Foto/Video';

  @override
  String get toolbarBackground => 'Hintergrund';

  @override
  String get toolbarText => 'Text';

  @override
  String get titleHint => 'Titel';

  @override
  String get bodyHint => 'Schreibe hier mehr…';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterToday => 'Heute';

  @override
  String get filterThisWeek => 'Diese Woche';

  @override
  String get filterWithinMonth => 'Innerhalb eines Monats';

  @override
  String get filterCompleted => 'Erledigt';

  @override
  String get tasksEmpty => 'Noch keine Aufgaben\nVersuch es mit \"Ich muss…\"';

  @override
  String get tasksFilterEmpty => 'Keine Aufgaben entsprechen diesem Filter';

  @override
  String get reminderLabel => 'Benachrichtigungserinnerung';

  @override
  String get removeReminderTooltip => 'Erinnerung entfernen';

  @override
  String get addReminder => 'Erinnerung hinzufügen';

  @override
  String get taskContentHint => 'Aufgabeninhalt';

  @override
  String get allDayLabel => 'Ganztägig';

  @override
  String get taskScheduleLabel => 'Start- und Endzeit';

  @override
  String get startTimeCaption => 'Start';

  @override
  String get endTimeCaption => 'Ende';

  @override
  String get addStartTime => 'Startzeit festlegen';

  @override
  String get removeStartTimeTooltip => 'Startzeit entfernen';

  @override
  String get addEndTime => 'Endzeit hinzufügen';

  @override
  String get removeEndTimeTooltip => 'Endzeit entfernen';

  @override
  String get manualTaskFabTooltip => 'Aufgabe hinzufügen';

  @override
  String get manualTaskScreenTitle => 'Aufgabe hinzufügen';

  @override
  String get manualTaskTitleHint => 'Aufgabe (z. B. Milch kaufen)';

  @override
  String get manualTaskTitleRequiredError => 'Bitte gib eine Aufgabe ein';

  @override
  String get manualDiaryFabTooltip => 'Tagebucheintrag hinzufügen';

  @override
  String get manualDiaryScreenTitle => 'Tagebucheintrag hinzufügen';

  @override
  String get manualDiaryTitleHint => 'Überschrift (optional)';

  @override
  String get manualDiaryContentHint => 'Wie war dein Tag?';

  @override
  String get manualDiaryContentRequiredError => 'Bitte gib einen Inhalt ein';

  @override
  String get manualIdeaFabTooltip => 'Idee hinzufügen';

  @override
  String get manualIdeaScreenTitle => 'Idee hinzufügen';

  @override
  String get manualIdeaTitleHint => 'Überschrift (optional)';

  @override
  String get manualIdeaContentHint => 'Ideeninhalt';

  @override
  String get manualIdeaContentRequiredError => 'Bitte gib einen Inhalt ein';

  @override
  String get ideasEmpty =>
      'Noch keine Ideen\nVersuch zu sagen, was dir einfällt';

  @override
  String get editIdeaTitle => 'Idee bearbeiten';

  @override
  String get ideaTitleHint => 'Überschrift (optional)';

  @override
  String get ideaContentHint => 'Ideeninhalt';

  @override
  String get ideaStatusConsidering => 'Wird erwogen';

  @override
  String get ideaStatusAdopted => 'Übernommen';

  @override
  String get ideaStatusRejected => 'Abgelehnt';

  @override
  String get ideaStatusNone => 'Kein Status';

  @override
  String get ideaStatusLabel => 'Status';

  @override
  String get ideaTagLabel => 'Tag';

  @override
  String get ideaTagHint => 'Tag (optional)';

  @override
  String get ideaSearchHint => 'Ideen durchsuchen';

  @override
  String get ideaPinTooltip => 'Anheften';

  @override
  String get ideaUnpinTooltip => 'Loslösen';

  @override
  String get ideaSortNewestFirstTooltip =>
      'Neueste zuerst sortiert (tippen für älteste zuerst)';

  @override
  String get ideaSortOldestFirstTooltip =>
      'Älteste zuerst sortiert (tippen für neueste zuerst)';

  @override
  String get ideasFilterEmpty => 'Keine Ideen entsprechen diesem Filter';

  @override
  String get reviewTitle => 'Inhalt überprüfen';

  @override
  String get reviewDescription =>
      'Bearbeite den Text, falls er nicht stimmt. Ziehe eine Karte, um sie zwischen Tagebuch, Idee und Aufgabe zu verschieben.';

  @override
  String get reviewDescriptionNoDrag =>
      'Bearbeite den Text, falls er nicht stimmt';

  @override
  String get sectionDiary => 'Tagebuch';

  @override
  String get sectionIdea => 'Idee';

  @override
  String get sectionTask => 'Aufgabe';

  @override
  String get sectionEmptyPlaceholder => 'Noch kein Inhalt';

  @override
  String get discard => 'Verwerfen';

  @override
  String get dragCardHere => 'Ziehe eine Karte hierher';

  @override
  String get addCardButton => 'Karte hinzufügen';

  @override
  String get genericProcessingError =>
      'Beim Verarbeiten ist ein Fehler aufgetreten';

  @override
  String get usageFetchError => 'Nutzungsstatus konnte nicht geladen werden';

  @override
  String get watchNotPairedMessage =>
      'Deine Apple Watch ist nicht gekoppelt. Halte sie in der Nähe und schließe die Kopplung zuerst in Apples Watch-App ab.';

  @override
  String get backgroundRecordingChannelName => 'Hintergrundaufnahme';

  @override
  String get backgroundRecordingChannelDescription =>
      'Hält die Aufnahme aktiv, während die App im Hintergrund ist oder der Bildschirm aus ist';

  @override
  String get backgroundRecordingNotificationTitle => 'Aufnahme läuft…';

  @override
  String get backgroundRecordingNotificationText =>
      'Tippen, um zur App zurückzukehren';

  @override
  String get reminderNotificationTitle => 'Erinnerung';

  @override
  String get reminderNotificationChannelName => 'Aufgabenerinnerungen';

  @override
  String get reminderNotificationChannelDescription =>
      'Zeitbasierte Erinnerungen für Aufgaben, die aus deinen Sprachnotizen erstellt wurden';

  @override
  String get weeklyReportNotificationTitle =>
      'Dein wöchentlicher Gehirnbericht ist fertig!';

  @override
  String get weeklyReportNotificationBody =>
      'Die KI hat auf deine Woche zurückgeblickt. Tippen, um ihn anzusehen.';

  @override
  String get weeklyReportNotificationChannelName =>
      'Benachrichtigungen zum Wochenbericht';

  @override
  String get weeklyReportNotificationChannelDescription =>
      'Benachrichtigt dich jeden Sonntag um 20 Uhr, wenn dein wöchentlicher Gehirnbericht fertig ist';

  @override
  String get weeklyReportHistoryTooltip => 'Frühere Berichte';

  @override
  String get weeklyReportHistoryTitle => 'Verlauf der Wochenberichte';

  @override
  String get weeklyReportHistoryEmpty => 'Noch keine gespeicherten Berichte';

  @override
  String get knowledgeBaseTitle => 'Zweites Gehirn';

  @override
  String get knowledgeBaseDescription =>
      'Die KI durchsucht all deine Tagebucheinträge, Ideen und Aufgaben, um dir zu antworten.';

  @override
  String get knowledgeBaseInputHint =>
      'z. B. Wie hieß nochmal die App-Idee, die ich letzten Monat erwähnt habe?';

  @override
  String get knowledgeBaseSend => 'Senden';

  @override
  String get knowledgeBaseThinking => 'Durchsucht deine früheren Einträge…';

  @override
  String get knowledgeBaseEmpty =>
      'Es ist noch nichts aufgenommen. Nimm etwas auf und frage dann erneut.';

  @override
  String get knowledgeBaseErrorTitle => 'Antwort konnte nicht abgerufen werden';

  @override
  String get knowledgeBaseProLockedDescription =>
      'Der Chat über alle deine Einträge ist eine Pro-Funktion. Upgrade, um ihn freizuschalten.';

  @override
  String get knowledgeBaseSourcesLabel => 'Referenzierte Einträge';

  @override
  String get knowledgeBaseSourceSheetTitle =>
      'Für diese Antwort referenzierter Eintrag';

  @override
  String get knowledgeBaseSourceNotFound =>
      'Dieser Eintrag konnte nicht gefunden werden';

  @override
  String get knowledgeBaseSignInNudgeText =>
      'Verknüpfe ein Konto, damit Antworten für genauere Ergebnisse auf deine früheren Einträge verweisen können.';

  @override
  String get knowledgeBaseSignInNudgeCta => 'Konto verknüpfen';

  @override
  String get knowledgeBaseVoiceQuestion => 'Per Sprache fragen';

  @override
  String get knowledgeBaseRecordingQuestion => 'Deine Frage wird aufgenommen…';

  @override
  String get knowledgeBaseTranscribing => 'Wird transkribiert…';

  @override
  String get knowledgeBasePlayAnswer => 'Antwort abspielen';

  @override
  String get knowledgeBaseStopAnswer => 'Wiedergabe stoppen';

  @override
  String get weeklyReportSettingsTitle => 'Wöchentlicher Gehirnbericht';

  @override
  String get weeklyReportSettingsSubtitle => 'Wird jede Woche zugestellt';

  @override
  String get weeklyReportTitle => 'Wöchentlicher Gehirnbericht';

  @override
  String get weeklyReportProLockedDescription =>
      'Der wöchentliche Gehirnbericht ist eine Pro-Funktion. Upgrade, um ihn freizuschalten.';

  @override
  String get weeklyReportRetry => 'Erneut versuchen';

  @override
  String get weeklyReportLoadingInsights =>
      'Die KI denkt über deine Woche nach…';

  @override
  String get weeklyReportErrorTitle => 'Bericht konnte nicht geladen werden';

  @override
  String get weeklyReportEmotionSectionTitle => 'Emotionale Trends';

  @override
  String get weeklyReportNoEmotionData =>
      'Diese Woche noch keine emotionalen Einträge';

  @override
  String get weeklyReportConstellationSectionTitle => 'Emotionsdiagramm';

  @override
  String get weeklyReportCategorySectionTitle => 'Kategorienmix';

  @override
  String get weeklyReportNoCategoryData => 'Diese Woche noch keine Einträge';

  @override
  String get weeklyReportKeywordsSectionTitle => 'Gehirnkarte';

  @override
  String get weeklyReportBrainMapSubtitle =>
      'Wie sich deine Woche auf positive, normale und negative Stimmungen aufteilte';

  @override
  String get weeklyReportWordsSectionTitle => 'Wörter der Woche';

  @override
  String get weeklyReportWordsEmpty => 'Noch keine herausragenden Wörter';

  @override
  String get weeklyReportWordDetailEmpty =>
      'Keine Einträge gefunden, die dieses Wort erwähnen';

  @override
  String get emotionCategoryPositive => 'Positiv';

  @override
  String get emotionCategoryNormal => 'Normal';

  @override
  String get emotionCategoryNegative => 'Negativ';

  @override
  String get weeklyReportIdeasSectionTitle => 'Ideen, die geglänzt haben';

  @override
  String get weeklyReportNoIdeas => 'Diese Woche noch keine Ideen erfasst';

  @override
  String get weeklyReportHighlightSectionTitle => 'Highlight der Woche';

  @override
  String get weeklyReportNoHighlight =>
      'Diese Woche noch keine Tagebucheinträge';

  @override
  String get weeklyReportAchievementSectionTitle => 'Erfolge dieser Woche';

  @override
  String weeklyReportTasksCompleted(int count) {
    return '$count Aufgaben erledigt';
  }

  @override
  String weeklyReportDiaryCount(int count) {
    return '$count Tagebucheinträge';
  }

  @override
  String get weeklyReportEncouragement =>
      'Du hast diese Woche großartig gemacht!';

  @override
  String get weeklyReportAdviceSectionTitle => 'Ratschlag für nächste Woche';

  @override
  String get weeklyReportLetterSectionTitle => 'Dein Wochenbrief';

  @override
  String get weeklyReportLetterLocked =>
      'Der Brief dieser Woche kommt am Sonntag um 20:00 Uhr an. Bis dahin bleibt er ein kleines Geheimnis.';

  @override
  String get weeklyReportShareTooltip => 'Als Bild teilen';

  @override
  String get weeklyReportShareCaption =>
      'So sah meine Woche aus 📝 #VoiceBrain';
}
