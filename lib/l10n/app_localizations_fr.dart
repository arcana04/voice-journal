// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navRecord => 'Enregistrer';

  @override
  String get navDiary => 'Journal';

  @override
  String get navIdea => 'Idée';

  @override
  String get navTask => 'Tâche';

  @override
  String get navKnowledgeBase => 'Demander';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get onboardingCreateAccount =>
      'Créer un compte (tu peux aussi le faire plus tard dans les réglages)';

  @override
  String get onboardingPage1Title =>
      'Dès qu\'une idée te traverse l\'esprit,\ndis-la simplement à voix haute';

  @override
  String get onboardingPage1Body =>
      'Appuie sur le bouton d\'enregistrement et parle — Voice Brain s\'occupe du reste';

  @override
  String get onboardingPage2Title => 'L\'IA trie tout pour toi';

  @override
  String get onboardingPage2Body =>
      'Ce que tu dis est transcrit par l\'IA et automatiquement classé en entrée de journal, idée ou tâche. Ta voix est traitée en toute sécurité, comme des données qui n\'appartiennent qu\'à toi.';

  @override
  String get onboardingFreeTierTitle => 'Gratuit pour commencer tout de suite';

  @override
  String get onboardingFreeTierBody =>
      'Le plan gratuit inclut 3 enregistrements par jour, jusqu\'à 60 secondes chacun. Tu veux plus ? Découvre le plan Pro pour des enregistrements plus longs et plus fréquents.';

  @override
  String get onboardingMicTitle => 'Nous aurons besoin d\'accéder au micro';

  @override
  String get onboardingMicBody =>
      'Voice Brain utilise ton micro pour enregistrer. Quand la demande d\'autorisation apparaîtra, appuie sur \"Autoriser\".';

  @override
  String get onboardingPage3Title => 'C\'est parti';

  @override
  String get onboardingPage3Body =>
      'Dès qu\'une idée te traverse l\'esprit, appuie et parle';

  @override
  String get emotionFatigue => 'Fatigue';

  @override
  String get emotionLove => 'Amour';

  @override
  String get emotionAnxious => 'Anxieux';

  @override
  String get emotionExcited => 'Excité';

  @override
  String get emotionJoy => 'Joie';

  @override
  String get emotionSadness => 'Tristesse';

  @override
  String get emotionAnger => 'Colère';

  @override
  String get emotionSatisfaction => 'Satisfaction';

  @override
  String get emotionNeutral => 'Neutre';

  @override
  String get emotionGratitude => 'Gratitude';

  @override
  String get emotionHappy => 'Content';

  @override
  String get emotionFunny => 'Amusé';

  @override
  String get emotionRelief => 'Soulagement';

  @override
  String get emotionCalm => 'Calme';

  @override
  String get emotionBoredom => 'Ennui';

  @override
  String get emotionRegret => 'Regret';

  @override
  String get emotionDislike => 'Aversion';

  @override
  String get confirmDeleteTitle => 'Supprimer ceci ?';

  @override
  String get confirmDeleteMessage =>
      'La suppression de cette entrée est irréversible.';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get editTooltip => 'Modifier';

  @override
  String get micPermissionDenied =>
      'L\'accès au microphone n\'est pas autorisé';

  @override
  String get recordingStopFailedTitle =>
      'Échec de l\'arrêt de l\'enregistrement';

  @override
  String get recordingErrorTitle => 'Erreur d\'enregistrement';

  @override
  String get recordingSaveFailed => 'Échec de l\'enregistrement de la prise';

  @override
  String get processingErrorTitle =>
      'Une erreur s\'est produite pendant le traitement';

  @override
  String statusError(String message) {
    return 'Erreur : $message';
  }

  @override
  String statusOrganized(String summary) {
    return 'Organisé : $summary';
  }

  @override
  String get statusTapToRecord => 'Appuyer pour commencer l\'enregistrement';

  @override
  String get recordPromptQuestion1 =>
      'Qu\'est-ce qui t\'a fait sourire ou t\'a rendu heureux aujourd\'hui ?';

  @override
  String get recordPromptQuestion2 =>
      'Sois honnête : comment se sentent ton corps et ton esprit aujourd\'hui ?';

  @override
  String get recordPromptQuestion3 =>
      'Si tu pouvais dire \"merci\" à quelqu\'un (ou à toi-même) aujourd\'hui, à qui serait-ce ?';

  @override
  String get recordPromptQuestion4 =>
      'Que dirais-tu à toi-même cette semaine ?';

  @override
  String get recordPromptQuestion5 =>
      'Reste-t-il quelque chose que tu dois absolument faire aujourd\'hui ?';

  @override
  String get statusRecording =>
      'Enregistrement… appuyer à nouveau pour arrêter';

  @override
  String get statusProcessing => 'L\'IA analyse…';

  @override
  String get statusProcessingSorting => 'Tri en journal, idées et tâches…';

  @override
  String get statusProcessingFinishing => 'Finalisation…';

  @override
  String maxRecordingSeconds(int seconds) {
    return 'Chaque enregistrement peut durer jusqu\'à $seconds secondes';
  }

  @override
  String maxRecordingMinutes(int minutes) {
    return 'Chaque enregistrement peut durer jusqu\'à $minutes minutes';
  }

  @override
  String streakTooltip(int days) {
    return 'Série de $days jours';
  }

  @override
  String get textComposeTooltip => 'Saisir en texte';

  @override
  String get settingsTooltip => 'Réglages';

  @override
  String get menuCustomDictionary => 'Dictionnaire personnalisé';

  @override
  String get menuSummaryLevel => 'Niveau de résumé de l\'IA';

  @override
  String get textComposerTitle => 'Saisir en texte';

  @override
  String get textComposerDescription =>
      'Utilise ceci quand tu ne peux pas parler. L\'IA le classe en entrée de journal, tâche ou idée, tout comme un enregistrement.';

  @override
  String get textComposerHint =>
      'p. ex. Prendre rendez-vous chez le dentiste demain à 15h';

  @override
  String get textComposerSubmit => 'Laisser l\'IA analyser';

  @override
  String get summaryLevelSheetTitle => 'Niveau de résumé de l\'IA';

  @override
  String get summaryLevelSheetDescription =>
      'Choisis à quel point l\'IA raccourcit le contenu du journal issu des enregistrements ou du texte. Cela n\'affecte pas la concision des tâches.';

  @override
  String get summaryLevelPreserveLabel => 'Préserver';

  @override
  String get summaryLevelStandardLabel => 'Standard';

  @override
  String get summaryLevelCompactLabel => 'Compact';

  @override
  String get summaryLevelPreserveDescription =>
      'Conserve les sentiments, les formulations et les noms exactement tels qu\'ils ont été dits, sans résumer.';

  @override
  String get summaryLevelStandardDescription =>
      'Élimine les répétitions redondantes tout en gardant une longueur naturelle de journal.';

  @override
  String get summaryLevelCompactDescription =>
      'Condense tout à l\'essentiel en 1-2 phrases.';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get displaySectionTitle => 'Affichage';

  @override
  String get darkModeTitle => 'Mode sombre';

  @override
  String get darkModeSubtitle =>
      'Passer à une apparence plus douce pour les yeux';

  @override
  String get themeColorTitle => 'Couleur du thème';

  @override
  String get themeColorSubtitle =>
      'Changer la couleur d\'accent générale de l\'application';

  @override
  String get themeColorSheetTitle => 'Choisir une couleur de thème';

  @override
  String get languageTitle => 'Langue';

  @override
  String get languageSubtitle =>
      'Choisir la langue d\'affichage de l\'application';

  @override
  String get languageSheetTitle => 'Choisir une langue';

  @override
  String get languageSystemDefault => 'Suivre la langue de l\'appareil';

  @override
  String get settingsProBadge => 'Pro uniquement';

  @override
  String get integrationsSettingsTitle => 'Intégrations';

  @override
  String get integrationsCalendarRowTitle => 'Intégration du calendrier';

  @override
  String get integrationsScreenTitle => 'Intégrations';

  @override
  String get integrationsDescription =>
      'Choisis un calendrier déjà configuré sur cet appareil (comme le Calendrier iOS ou un compte Google ajouté dans les réglages système). Une fois activé, toute tâche avec une date et une heure précises y sera automatiquement ajoutée comme événement.';

  @override
  String get integrationsOff => 'Désactivé';

  @override
  String get integrationsPermissionDenied =>
      'L\'accès au calendrier n\'a pas été accordé. Tu peux l\'autoriser depuis l\'application Réglages du système.';

  @override
  String get integrationsNoCalendars =>
      'Aucun calendrier modifiable n\'a été trouvé sur cet appareil. Ajoute un calendrier (comme un compte Google) dans l\'application Réglages du système, puis actualise.';

  @override
  String get integrationsRefresh => 'Actualiser';

  @override
  String get appleRemindersSettingsTitle => 'Rappels';

  @override
  String get appleRemindersScreenTitle => 'Intégration des Rappels';

  @override
  String get appleRemindersDescription =>
      'Choisis une liste depuis l\'application Rappels de l\'appareil. Une fois activé, toute tâche avec une date d\'échéance y sera automatiquement ajoutée, et la marquer comme terminée dans l\'application la marquera aussi comme terminée dans Rappels.';

  @override
  String get appleRemindersPermissionDenied =>
      'L\'accès à Rappels n\'a pas été accordé. Tu peux l\'autoriser depuis l\'application Réglages du système.';

  @override
  String get appleRemindersNoLists =>
      'Aucune liste de rappels modifiable n\'a été trouvée. Crée une liste dans l\'application Rappels, puis actualise.';

  @override
  String get notionSettingsRowTitle => 'Notion';

  @override
  String get notionScreenTitle => 'Intégration Notion';

  @override
  String get notionIntroDescription =>
      'Envoie tes tâches, entrées de journal et idées vers une base de données Notion en un geste. Crée d\'abord une intégration sur Notion, puis partage avec elle la page que tu veux utiliser.';

  @override
  String get notionTokenFieldLabel => 'Jeton d\'intégration';

  @override
  String get notionTokenFieldHint => 'Colle un jeton commençant par secret_';

  @override
  String get notionTokenHelpText =>
      'Crée une nouvelle intégration sur notion.so/my-integrations, puis colle le jeton ici. Partage ensuite avec cette intégration la page où créer la base de données.';

  @override
  String get notionConnectButton => 'Connecter';

  @override
  String get notionSelectPageTitle =>
      'Choisis une page où créer la base de données';

  @override
  String get notionNoPagesFound =>
      'Aucune page partagée trouvée. Partage une page avec cette intégration dans Notion, puis actualise.';

  @override
  String get notionCreateDatabaseButton => 'Créer dans cette page';

  @override
  String get notionConnectedStatusLabel => 'Connecté';

  @override
  String get notionDisconnectButton => 'Déconnecter';

  @override
  String get notionDisconnectConfirmTitle => 'Déconnecter Notion ?';

  @override
  String get notionDisconnectConfirmMessage =>
      'La base de données créée dans Notion restera intacte.';

  @override
  String get notionSendTooltip => 'Envoyer à Notion';

  @override
  String get notionSendSuccessMessage => 'Envoyé à Notion';

  @override
  String get notionOpenAction => 'Ouvrir';

  @override
  String get notionSendErrorMessage => 'Échec de l\'envoi à Notion';

  @override
  String get notionCopiedFreeMessage =>
      'Copié dans le presse-papiers. L\'envoi direct à Notion est réservé au plan Pro';

  @override
  String get notionNotConnectedMessage =>
      'Notion n\'est pas connecté. Connecte-le depuis les Réglages';

  @override
  String get notionConnectAction => 'Connecter';

  @override
  String get notionAlreadySentTooltip => 'Ouvrir dans Notion';

  @override
  String get notionProLockedDescription =>
      'L\'intégration Notion est réservée au plan Pro.';

  @override
  String get accountSectionTitle => 'Compte';

  @override
  String accountSignedInAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get accountNotSignedIn => 'Non connecté';

  @override
  String get accountNotSignedInDescription =>
      'Connecte-toi avec Google ou Apple pour transférer tes données de journal vers d\'autres appareils';

  @override
  String get accountScreenTitle => 'Compte';

  @override
  String get accountSignInWithGoogle => 'Se connecter avec Google';

  @override
  String get accountSignInWithApple => 'Se connecter avec Apple';

  @override
  String get accountSignOutButton => 'Se déconnecter';

  @override
  String get accountRestoreButton => 'Restaurer depuis le cloud';

  @override
  String get watchPairingButton => 'Coupler l\'Apple Watch';

  @override
  String get watchPairingSuccessTitle => 'Couplée';

  @override
  String get watchPairingSuccessMessage =>
      'Ton Apple Watch est couplée. Tu peux maintenant enregistrer directement depuis la Watch.';

  @override
  String get syncErrorBannerMessage =>
      'Certaines données n\'ont pas pu être synchronisées';

  @override
  String get syncErrorBannerAction => 'Vérifier';

  @override
  String get loadErrorBannerMessage => 'Échec du chargement de tes données';

  @override
  String get loadErrorBannerAction => 'Réessayer';

  @override
  String get mediaStorageWarningBannerMessage =>
      'Ton espace de stockage cloud pour photos/vidéos est presque plein';

  @override
  String get mediaStorageFullBannerMessage =>
      'L\'espace de stockage cloud pour photos/vidéos est plein. Les nouvelles photos et vidéos ne seront pas synchronisées';

  @override
  String get mediaStorageBannerAction => 'Nettoyer';

  @override
  String get accountSyncingMessage => 'Synchronisation…';

  @override
  String get accountSyncCompleteTitle => 'Terminé';

  @override
  String get accountSyncCompleteMessage => 'Synchronisation terminée.';

  @override
  String get accountErrorTitle => 'Erreur';

  @override
  String get accountErrorNetwork =>
      'Une erreur réseau s\'est produite. Réessaie dans un instant.';

  @override
  String get accountErrorUnknown =>
      'Un problème est survenu. Réessaie dans un instant.';

  @override
  String get accountSignOutConfirmTitle => 'Se déconnecter ?';

  @override
  String get accountSignOutConfirmMessage =>
      'Tes données sur cet appareil ne seront pas supprimées. Reconnecte-toi à tout moment pour reprendre la synchronisation.';

  @override
  String get accountDeleteButton => 'Supprimer le compte';

  @override
  String get accountDeleteConfirmTitle => 'Supprimer ton compte ?';

  @override
  String get accountDeleteConfirmMessage =>
      'Ceci est irréversible. Tes entrées de journal, idées et tâches dans le cloud, tes photos et vidéos, ainsi que tout ce qui se trouve sur cet appareil seront définitivement supprimés.';

  @override
  String get accountDeleteConfirmButton => 'Supprimer';

  @override
  String get accountDeleteCompleteTitle => 'Supprimé';

  @override
  String get accountDeleteCompleteMessage =>
      'Ton compte et toutes ses données ont été supprimés.';

  @override
  String get accountMediaSyncFreeNote =>
      'Seul le texte (entrées de journal, idées et tâches) est sauvegardé. Les photos et vidéos ne sont pas synchronisées avec le cloud — cela est réservé aux plans mensuel/annuel (non inclus dans le plan à vie).';

  @override
  String get accountMediaSyncProNote =>
      'Les photos et vidéos sont aussi sauvegardées dans le cloud.';

  @override
  String get supportSectionTitle => 'Assistance';

  @override
  String get contactSupportTitle => 'Nous contacter';

  @override
  String get contactSupportEmailSubject => 'Assistance Voice Brain';

  @override
  String get planSectionTitle => 'Plan';

  @override
  String get planCurrentTitle => 'Plan actuel';

  @override
  String get planProTitle => 'Plan Pro';

  @override
  String get planFreeTitle => 'Plan gratuit';

  @override
  String get planProSubtitle =>
      'Jusqu\'à 15 minutes par enregistrement, 30 enregistrements par jour';

  @override
  String get planFreeSubtitle =>
      'Jusqu\'à 60 secondes par enregistrement, 3 enregistrements gratuits par jour';

  @override
  String get planManage => 'Gérer';

  @override
  String get planUpgrade => 'Passer à Pro';

  @override
  String get paywallTitle => 'Plan Pro';

  @override
  String get paywallSectionTitle => 'Ce que Pro débloque';

  @override
  String get paywallSectionSubtitle =>
      'Accès illimité à toutes les fonctionnalités Pro';

  @override
  String get paywallBenefitDurationTitle => 'Enregistrements plus longs';

  @override
  String get paywallBenefitDurationBefore => '60 sec';

  @override
  String get paywallBenefitDurationAfter => '15 min';

  @override
  String get paywallBenefitDurationDesc =>
      'Parle aussi longtemps que nécessaire sans perdre les détails';

  @override
  String get paywallBenefitCountTitle => 'Plus d\'utilisations par jour';

  @override
  String get paywallBenefitCountBefore => '3 / jour';

  @override
  String get paywallBenefitCountAfter => '30 / jour';

  @override
  String get paywallBenefitCountDesc =>
      'Capture chaque pensée, dès qu\'elle survient';

  @override
  String get paywallMonthlyCapNote =>
      '* Le temps total d\'enregistrement est plafonné à 240 minutes par mois. Si tu atteins la limite, tu peux acheter un pack de minutes supplémentaires pour continuer.';

  @override
  String get paywallBenefitCustomBackgroundTitle => 'Ajoute ';

  @override
  String get paywallBenefitCustomBackgroundHighlight => 'ta propre photo';

  @override
  String get paywallBenefitCustomBackgroundDesc =>
      'Fais que chaque entrée te ressemble';

  @override
  String get paywallBenefitImageLayoutTitle => 'Organise librement les photos';

  @override
  String get paywallBenefitImageLayoutDesc =>
      'Fais glisser pour repositionner et redimensionne avec un curseur sur n\'importe quelle entrée';

  @override
  String get paywallBenefitKnowledgeBaseHighlight =>
      'Demander (deuxième cerveau)';

  @override
  String get paywallBenefitKnowledgeBaseSuffix => ' est débloqué';

  @override
  String get paywallBenefitKnowledgeBaseDesc =>
      'L\'IA fouille dans tout ce que tu as enregistré pour t\'aider';

  @override
  String get paywallBenefitWeeklyReportTitle => 'Rapport cérébral hebdomadaire';

  @override
  String get paywallBenefitWeeklyReportDesc =>
      'L\'IA lit ta semaine et t\'en livre les points forts';

  @override
  String get paywallBenefitMediaSyncTitle =>
      'Synchronisation cloud des photos et vidéos';

  @override
  String get paywallBenefitMediaSyncDesc =>
      'Garde tes souvenirs sauvegardés en toute sécurité';

  @override
  String get paywallBenefitMediaSyncBadge =>
      'Plans mensuel / annuel uniquement';

  @override
  String get paywallUnavailable =>
      'Impossible de charger les plans pour le moment. Réessaie plus tard.';

  @override
  String get paywallRestore => 'Restaurer les achats';

  @override
  String get paywallTerms => 'Conditions d\'utilisation';

  @override
  String get paywallPrivacy => 'Politique de confidentialité';

  @override
  String get paywallPurchaseFailed =>
      'Un problème est survenu. Réessaie plus tard.';

  @override
  String get paywallRestoreNotFound =>
      'Aucun achat restaurable n\'a été trouvé.';

  @override
  String get paywallPlanMonthly => 'Mensuel';

  @override
  String get paywallPlanAnnual => 'Annuel';

  @override
  String get paywallPlanLifetime => 'À vie';

  @override
  String get paywallPlanRecommended => 'Recommandé';

  @override
  String paywallLifetimeRemaining(Object count) {
    return 'Il en reste $count';
  }

  @override
  String get paywallPlanLifetimeCaption =>
      'Synchronisation cloud des photos/vidéos non incluse';

  @override
  String get paywallPlanComingSoon => 'Bientôt disponible';

  @override
  String get paywallContinueButton => 'Continuer';

  @override
  String get paywallTrialNote => 'Essai gratuit de 14 jours inclus';

  @override
  String get paywallStartTrialButton => 'Commencer l\'essai gratuit';

  @override
  String get paywallSignInRequiredTitle => 'Connectez-vous pour continuer';

  @override
  String get paywallSignInRequiredDescription =>
      'La connexion protège votre achat, afin de pouvoir le restaurer même après avoir réinstallé l\'application.';

  @override
  String get paywallPlanSoldOut => 'Épuisé';

  @override
  String get paywallLifetimeSoldOutMessage =>
      'Le forfait à vie n\'est plus disponible.';

  @override
  String homeUsageToday(int used, int limit) {
    return 'Aujourd\'hui $used / $limit';
  }

  @override
  String homeUsageMonth(int usedMinutes, int limitMinutes) {
    return 'Ce mois-ci $usedMinutes / $limitMinutes min';
  }

  @override
  String get buyMinutesCta => 'Acheter plus de minutes';

  @override
  String get buyMinutesTitle => 'Acheter des minutes supplémentaires';

  @override
  String get buyMinutesDescription =>
      'Tu as atteint la limite de temps d\'enregistrement de ce mois. Achète un pack de minutes supplémentaires pour continuer à enregistrer immédiatement, sans attendre le mois prochain.';

  @override
  String get buyMinutesDescriptionProactive =>
      'Les plans Pro et À vie incluent 240 minutes d\'enregistrement par mois. Tu peux aussi acheter un pack supplémentaire de 60 minutes à l\'avance, pour le jour où tu atteindras cette limite.';

  @override
  String get buyMinutesUnavailable =>
      'Le pack de minutes supplémentaires n\'est pas disponible pour le moment. Réessaie plus tard.';

  @override
  String get buyMinutesPurchaseFailed => 'L\'achat a échoué. Réessaie.';

  @override
  String get buyMinutesPurchaseSuccess =>
      'Minutes supplémentaires ajoutées. Tu peux continuer à enregistrer maintenant.';

  @override
  String buyMinutesPurchaseButton(String price) {
    return 'Acheter +60 min ($price)';
  }

  @override
  String get notificationSectionTitle => 'Notifications';

  @override
  String get reminderNotificationsTitle => 'Notifications de rappel';

  @override
  String get notificationCheckingStatus => 'Vérification…';

  @override
  String get notificationGranted => 'Autorisées';

  @override
  String get notificationDenied =>
      'Non autorisées (les rappels ne seront pas envoyés)';

  @override
  String get allow => 'Autoriser';

  @override
  String get notificationPermissionDialogTitle =>
      'Les notifications ne sont pas autorisées';

  @override
  String get notificationPermissionDialogMessage =>
      'Autorise les notifications pour recevoir des rappels. Tu peux modifier cela dans l\'application Réglages.';

  @override
  String get openSettings => 'Ouvrir les réglages';

  @override
  String get customDictionaryTitle => 'Dictionnaire personnalisé';

  @override
  String get customDictionaryDescription =>
      'Enregistre des noms d\'amis, de groupes ou des termes techniques pour qu\'ils soient prioritaires lors de la reconnaissance vocale. Ajouter une note aide aussi l\'IA à repérer et corriger les fautes d\'orthographe.';

  @override
  String get wordLabel => 'Mot';

  @override
  String get wordHint => 'p. ex. Jean Dupont';

  @override
  String get descriptionLabelOptional => 'Description (facultatif)';

  @override
  String get descriptionHint => 'p. ex. Un ami de l\'université';

  @override
  String get add => 'Ajouter';

  @override
  String get customDictionaryEmpty => 'Aucun mot enregistré pour l\'instant';

  @override
  String get diaryDayEmpty => 'Aucune entrée de journal ce jour-là';

  @override
  String get diaryPickDateTooltip => 'Choisir une date';

  @override
  String get diaryPreviousWeekTooltip => 'Semaine précédente';

  @override
  String get diaryNextWeekTooltip => 'Semaine suivante';

  @override
  String get fontStandard => 'Standard';

  @override
  String get fontMincho => 'Serif';

  @override
  String get fontHandwriting => 'Manuscrite';

  @override
  String get fontPop => 'Pop';

  @override
  String get fontMonospace => 'Monospace';

  @override
  String get fontGothic => 'Gothique';

  @override
  String get fontRoundGothic => 'Arrondie';

  @override
  String get fontThinMincho => 'Serif fine';

  @override
  String get fontBrush => 'Pinceau';

  @override
  String get fontRetro => 'Rétro';

  @override
  String get fontImpact => 'Impact';

  @override
  String get fontCute => 'Mignonne';

  @override
  String mediaPickFailed(String error) {
    return 'Échec de la sélection de la photo/vidéo : $error';
  }

  @override
  String get pickPhotosFromLibrary => 'Choisir des photos';

  @override
  String get pickPhotosFromLibrarySubtitle =>
      'Choisis des photos de ta bibliothèque à ajouter';

  @override
  String get pickVideoFromLibrary => 'Choisir une vidéo';

  @override
  String get pickVideoFromLibrarySubtitle =>
      'Choisis une vidéo de ta bibliothèque à ajouter';

  @override
  String get backgroundSheetTitle => 'Arrière-plan';

  @override
  String get backgroundNone => 'Aucun';

  @override
  String get emotionSheetTitle => 'Émotion';

  @override
  String get emotionNone => 'Aucune';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get diaryBgFruit => 'Fruits';

  @override
  String get diaryBgMintPlant => 'Notes botaniques';

  @override
  String get diaryBgCoffee => 'Café';

  @override
  String get diaryBgCake => 'Gâteau';

  @override
  String get diaryBgPicnic => 'Panier de pain';

  @override
  String get diaryBgHeartBalloon => 'Ballons cœur';

  @override
  String get diaryBgParkDay => 'Champ de pissenlits';

  @override
  String get diaryBgNightSky => 'Ciel nocturne';

  @override
  String get diaryBgSleepingCat => 'Chat endormi';

  @override
  String get diaryBgBlueCheckBouquet => 'Bouquet à carreaux bleus';

  @override
  String get diaryBgVintageCamera => 'Appareil photo vintage';

  @override
  String get diaryBgShopping => 'Shopping';

  @override
  String get diaryBgNewYork => 'New York';

  @override
  String get diaryBgBeach => 'Plage';

  @override
  String get diaryBgPalmTree => 'Palmier';

  @override
  String get diaryBgEuropeanStreet => 'Rue européenne';

  @override
  String get diaryBgRunning => 'Course à pied';

  @override
  String get diaryBgLivingRoom => 'Salon';

  @override
  String get diaryBgMusicNote => 'Note de musique';

  @override
  String get diaryBgLetter => 'Lettre';

  @override
  String get diaryBgDeepSea => 'Fond marin';

  @override
  String get diaryBgSnow => 'Neige';

  @override
  String get diaryBgSoccerBall => 'Ballon de football';

  @override
  String get diaryBgLuxuryFrame => 'Cadre de luxe';

  @override
  String get diaryBgClock => 'Horloge';

  @override
  String get fontSheetTitle => 'Police';

  @override
  String get fontSheetSizeLabel => 'Taille du titre';

  @override
  String get fontSheetColorLabel => 'Couleur du texte';

  @override
  String get fontSheetStyleLabel => 'Style de police';

  @override
  String get closeTooltip => 'Fermer';

  @override
  String get favoriteSettingsTooltip => 'Réglages favoris';

  @override
  String get favoriteSettingsSheetTitle => 'Réglages favoris';

  @override
  String get favoriteSettingsDescription =>
      'Le style de texte et l\'arrière-plan par défaut utilisés pour les nouvelles entrées de journal';

  @override
  String get addCustomBackgroundTile => 'Ajouter ta propre photo';

  @override
  String get toolbarMedia => 'Photo/Vidéo';

  @override
  String get toolbarBackground => 'Arrière-plan';

  @override
  String get toolbarText => 'Texte';

  @override
  String get titleHint => 'Titre';

  @override
  String get bodyHint => 'Écris-en plus ici…';

  @override
  String get filterAll => 'Tout';

  @override
  String get filterToday => 'Aujourd\'hui';

  @override
  String get filterThisWeek => 'Cette semaine';

  @override
  String get filterWithinMonth => 'Dans le mois';

  @override
  String get filterCompleted => 'Terminées';

  @override
  String get tasksEmpty => 'Pas encore de tâches\nEssaie de dire \"Je dois…\"';

  @override
  String get tasksFilterEmpty => 'Aucune tâche ne correspond à ce filtre';

  @override
  String get reminderLabel => 'Rappel de notification';

  @override
  String get removeReminderTooltip => 'Supprimer le rappel';

  @override
  String get addReminder => 'Ajouter un rappel';

  @override
  String get taskContentHint => 'Contenu de la tâche';

  @override
  String get allDayLabel => 'Toute la journée';

  @override
  String get taskScheduleLabel => 'Heure de début et de fin';

  @override
  String get startTimeCaption => 'Début';

  @override
  String get endTimeCaption => 'Fin';

  @override
  String get addStartTime => 'Définir l\'heure de début';

  @override
  String get removeStartTimeTooltip => 'Supprimer l\'heure de début';

  @override
  String get addEndTime => 'Ajouter une heure de fin';

  @override
  String get removeEndTimeTooltip => 'Supprimer l\'heure de fin';

  @override
  String get manualTaskFabTooltip => 'Ajouter une tâche';

  @override
  String get manualTaskScreenTitle => 'Ajouter une tâche';

  @override
  String get manualTaskTitleHint => 'Tâche (p. ex. Acheter du lait)';

  @override
  String get manualTaskTitleRequiredError => 'Merci de saisir une tâche';

  @override
  String get manualDiaryFabTooltip => 'Ajouter une entrée de journal';

  @override
  String get manualDiaryScreenTitle => 'Ajouter une entrée de journal';

  @override
  String get manualDiaryTitleHint => 'Titre (facultatif)';

  @override
  String get manualDiaryContentHint => 'Comment s\'est passée ta journée ?';

  @override
  String get manualDiaryContentRequiredError => 'Merci de saisir du contenu';

  @override
  String get manualIdeaFabTooltip => 'Ajouter une idée';

  @override
  String get manualIdeaScreenTitle => 'Ajouter une idée';

  @override
  String get manualIdeaTitleHint => 'Titre (facultatif)';

  @override
  String get manualIdeaContentHint => 'Contenu de l\'idée';

  @override
  String get manualIdeaContentRequiredError => 'Merci de saisir du contenu';

  @override
  String get ideasEmpty =>
      'Pas encore d\'idées\nEssaie de dire ce qui te vient à l\'esprit';

  @override
  String get editIdeaTitle => 'Modifier l\'idée';

  @override
  String get ideaTitleHint => 'Titre (facultatif)';

  @override
  String get ideaContentHint => 'Contenu de l\'idée';

  @override
  String get ideaStatusConsidering => 'En réflexion';

  @override
  String get ideaStatusAdopted => 'Adoptée';

  @override
  String get ideaStatusRejected => 'Rejetée';

  @override
  String get ideaStatusNone => 'Aucun statut';

  @override
  String get ideaStatusLabel => 'Statut';

  @override
  String get ideaTagLabel => 'Étiquette';

  @override
  String get ideaTagHint => 'Étiquette (facultatif)';

  @override
  String get ideaSearchHint => 'Rechercher des idées';

  @override
  String get ideaPinTooltip => 'Épingler';

  @override
  String get ideaUnpinTooltip => 'Désépingler';

  @override
  String get ideaSortNewestFirstTooltip =>
      'Triées des plus récentes aux plus anciennes (appuyer pour inverser)';

  @override
  String get ideaSortOldestFirstTooltip =>
      'Triées des plus anciennes aux plus récentes (appuyer pour inverser)';

  @override
  String get ideasFilterEmpty => 'Aucune idée ne correspond à ce filtre';

  @override
  String get reviewTitle => 'Vérifier le contenu';

  @override
  String get reviewDescription =>
      'Modifie le texte s\'il n\'est pas correct. Fais glisser une carte pour la déplacer entre journal, idée et tâche.';

  @override
  String get reviewDescriptionNoDrag =>
      'Modifie le texte s\'il n\'est pas correct';

  @override
  String get sectionDiary => 'Journal';

  @override
  String get sectionIdea => 'Idée';

  @override
  String get sectionTask => 'Tâche';

  @override
  String get sectionEmptyPlaceholder => 'Pas encore de contenu';

  @override
  String get discard => 'Annuler';

  @override
  String get dragCardHere => 'Fais glisser une carte ici';

  @override
  String get addCardButton => 'Ajouter une carte';

  @override
  String get genericProcessingError =>
      'Une erreur s\'est produite pendant le traitement';

  @override
  String get usageFetchError => 'Échec du chargement de l\'état d\'utilisation';

  @override
  String get watchNotPairedMessage =>
      'Ton Apple Watch n\'est pas couplée. Garde-la à proximité et termine d\'abord le couplage dans l\'application Watch d\'Apple.';

  @override
  String get backgroundRecordingChannelName => 'Enregistrement en arrière-plan';

  @override
  String get backgroundRecordingChannelDescription =>
      'Maintient l\'enregistrement actif pendant que l\'application est en arrière-plan ou l\'écran éteint';

  @override
  String get backgroundRecordingNotificationTitle => 'Enregistrement…';

  @override
  String get backgroundRecordingNotificationText =>
      'Appuyer pour revenir à l\'application';

  @override
  String get reminderNotificationTitle => 'Rappel';

  @override
  String get reminderNotificationChannelName => 'Rappels de tâches';

  @override
  String get reminderNotificationChannelDescription =>
      'Rappels basés sur l\'heure pour les tâches créées à partir de tes notes vocales';

  @override
  String get weeklyReportNotificationTitle =>
      'Ton rapport cérébral hebdomadaire est prêt !';

  @override
  String get weeklyReportNotificationBody =>
      'L\'IA a fait le bilan de ta semaine. Appuie pour le consulter.';

  @override
  String get weeklyReportNotificationChannelName =>
      'Notifications du rapport hebdomadaire';

  @override
  String get weeklyReportNotificationChannelDescription =>
      'Te prévient chaque dimanche à 20h quand ton rapport cérébral hebdomadaire est prêt';

  @override
  String get trialEndingNotificationTitle =>
      'Votre essai gratuit se termine bientôt';

  @override
  String get trialEndingNotificationBody =>
      'Si vous n\'avez pas annulé, la facturation commencera dans 3 jours.';

  @override
  String get trialEndingNotificationChannelName => 'Rappels de fin d\'essai';

  @override
  String get trialEndingNotificationChannelDescription =>
      'Vous avertit 3 jours avant la fin de votre essai gratuit et le début de la facturation';

  @override
  String get weeklyReportHistoryTooltip => 'Rapports précédents';

  @override
  String get weeklyReportHistoryTitle =>
      'Historique des rapports hebdomadaires';

  @override
  String get weeklyReportHistoryEmpty => 'Pas encore de rapports enregistrés';

  @override
  String get knowledgeBaseTitle => 'Deuxième cerveau';

  @override
  String get knowledgeBaseDescription =>
      'L\'IA repasse en revue toutes tes entrées de journal, idées et tâches pour te répondre.';

  @override
  String get knowledgeBaseInputHint =>
      'p. ex. C\'était quoi déjà ce restaurant que je voulais essayer ?';

  @override
  String get knowledgeBaseSend => 'Envoyer';

  @override
  String get knowledgeBaseThinking => 'Recherche dans tes entrées passées…';

  @override
  String get knowledgeBaseEmpty =>
      'Il n\'y a encore rien d\'enregistré. Enregistre quelque chose, puis redemande.';

  @override
  String get knowledgeBaseErrorTitle => 'Impossible d\'obtenir une réponse';

  @override
  String get knowledgeBaseProLockedDescription =>
      'Discuter avec toutes tes entrées est une fonctionnalité Pro. Passe à Pro pour la débloquer.';

  @override
  String get knowledgeBaseSourcesLabel => 'Entrées référencées';

  @override
  String get knowledgeBaseSourceSheetTitle =>
      'Entrée référencée pour cette réponse';

  @override
  String get knowledgeBaseSourceNotFound => 'Cette entrée est introuvable';

  @override
  String get knowledgeBaseSignInNudgeText =>
      'Associe un compte pour que les réponses puissent citer tes entrées passées avec des résultats plus précis.';

  @override
  String get knowledgeBaseSignInNudgeCta => 'Associer un compte';

  @override
  String get knowledgeBaseVoiceQuestion => 'Demander à voix haute';

  @override
  String get knowledgeBaseRecordingQuestion => 'Enregistrement de ta question…';

  @override
  String get knowledgeBaseTranscribing => 'Transcription…';

  @override
  String get weeklyReportSettingsTitle => 'Rapport cérébral hebdomadaire';

  @override
  String get weeklyReportSettingsSubtitle => 'Livré chaque semaine';

  @override
  String get weeklyReportTitle => 'Rapport cérébral hebdomadaire';

  @override
  String get weeklyReportProLockedDescription =>
      'Le rapport cérébral hebdomadaire est une fonctionnalité Pro. Passe à Pro pour la débloquer.';

  @override
  String get weeklyReportRetry => 'Réessayer';

  @override
  String get weeklyReportLoadingInsights => 'L\'IA réfléchit à ta semaine…';

  @override
  String get weeklyReportErrorTitle => 'Impossible de charger le rapport';

  @override
  String get weeklyReportEmotionSectionTitle => 'Tendances émotionnelles';

  @override
  String get weeklyReportNoEmotionData =>
      'Pas encore d\'entrées émotionnelles cette semaine';

  @override
  String get weeklyReportConstellationSectionTitle => 'Graphique des émotions';

  @override
  String get weeklyReportCategorySectionTitle => 'Répartition des catégories';

  @override
  String get weeklyReportNoCategoryData =>
      'Pas encore d\'entrées cette semaine';

  @override
  String get weeklyReportKeywordsSectionTitle => 'Carte mentale';

  @override
  String get weeklyReportBrainMapSubtitle =>
      'Comment ta semaine s\'est répartie entre humeurs positives, normales et négatives';

  @override
  String get weeklyReportWordsSectionTitle => 'Mots de la semaine';

  @override
  String get weeklyReportWordsEmpty => 'Pas encore de mots marquants';

  @override
  String get weeklyReportWordDetailEmpty =>
      'Aucune entrée mentionnant ce mot n\'a été trouvée';

  @override
  String get emotionCategoryPositive => 'Positif';

  @override
  String get emotionCategoryNormal => 'Normal';

  @override
  String get emotionCategoryNegative => 'Négatif';

  @override
  String get weeklyReportIdeasSectionTitle => 'Idées qui ont brillé';

  @override
  String get weeklyReportNoIdeas =>
      'Pas encore d\'idées enregistrées cette semaine';

  @override
  String get weeklyReportHighlightSectionTitle =>
      'Le moment fort de la semaine';

  @override
  String get weeklyReportNoHighlight =>
      'Pas encore d\'entrées de journal cette semaine';

  @override
  String get weeklyReportAchievementSectionTitle => 'Réussites de la semaine';

  @override
  String weeklyReportTasksCompleted(int count) {
    return '$count tâches terminées';
  }

  @override
  String weeklyReportDiaryCount(int count) {
    return '$count entrées de journal';
  }

  @override
  String get weeklyReportEncouragement =>
      'Tu as fait du très bon travail cette semaine !';

  @override
  String get weeklyReportAdviceSectionTitle =>
      'Conseil pour la semaine prochaine';

  @override
  String get weeklyReportLetterSectionTitle => 'Ta lettre hebdomadaire';

  @override
  String get weeklyReportLetterLocked =>
      'La lettre de cette semaine arrive dimanche à 20h00. On la gardera secrète jusque-là.';

  @override
  String get weeklyReportShareTooltip => 'Partager en image';

  @override
  String get weeklyReportShareCaption =>
      'Voici à quoi a ressemblé ma semaine 📝 #VoiceBrain';
}
