// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navRecord => 'Grabar';

  @override
  String get navDiary => 'Diario';

  @override
  String get navIdea => 'Idea';

  @override
  String get navTask => 'Tarea';

  @override
  String get navKnowledgeBase => 'Preguntar';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingGetStarted => 'Empezar';

  @override
  String get onboardingCreateAccount =>
      'Crear una cuenta (también puedes hacerlo más tarde en Ajustes)';

  @override
  String get onboardingPage1Title =>
      'En el momento en que se te ocurra,\nsolo dilo en voz alta';

  @override
  String get onboardingPage1Body =>
      'Toca el botón de grabar y habla — Voice Brain se encarga del resto';

  @override
  String get onboardingPage2Title => 'La IA lo organiza por ti';

  @override
  String get onboardingPage2Body =>
      'Lo que dices se transcribe con IA y se organiza automáticamente en una entrada de diario, una idea o una tarea. Tu voz se maneja de forma segura, como datos que solo te pertenecen a ti.';

  @override
  String get onboardingFreeTierTitle =>
      'Gratis para empezar a usar ahora mismo';

  @override
  String get onboardingFreeTierBody =>
      'El plan gratuito incluye 3 grabaciones al día, de hasta 60 segundos cada una. ¿Quieres más? Echa un vistazo al plan Pro para grabaciones más largas y frecuentes.';

  @override
  String get onboardingMicTitle => 'Necesitaremos acceso al micrófono';

  @override
  String get onboardingMicBody =>
      'Voice Brain usa tu micrófono para grabar. Cuando aparezca el aviso de permiso, toca \"Permitir\".';

  @override
  String get onboardingPage3Title => 'Empecemos';

  @override
  String get onboardingPage3Body =>
      'Cuando se te ocurra algo, simplemente toca y habla';

  @override
  String get emotionFatigue => 'Cansancio';

  @override
  String get emotionLove => 'Amor';

  @override
  String get emotionAnxious => 'Ansioso';

  @override
  String get emotionExcited => 'Emocionado';

  @override
  String get emotionJoy => 'Alegría';

  @override
  String get emotionSadness => 'Tristeza';

  @override
  String get emotionAnger => 'Enojo';

  @override
  String get emotionSatisfaction => 'Satisfacción';

  @override
  String get emotionNeutral => 'Neutral';

  @override
  String get emotionGratitude => 'Gratitud';

  @override
  String get emotionHappy => 'Feliz';

  @override
  String get emotionFunny => 'Divertido';

  @override
  String get emotionRelief => 'Alivio';

  @override
  String get emotionCalm => 'Tranquilo';

  @override
  String get emotionBoredom => 'Aburrido';

  @override
  String get emotionRegret => 'Arrepentimiento';

  @override
  String get emotionDislike => 'Disgusto';

  @override
  String get confirmDeleteTitle => '¿Eliminar esto?';

  @override
  String get confirmDeleteMessage =>
      'Eliminar esta entrada no se puede deshacer.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get editTooltip => 'Editar';

  @override
  String get micPermissionDenied => 'No se ha permitido el acceso al micrófono';

  @override
  String get recordingStopFailedTitle => 'Error al detener la grabación';

  @override
  String get recordingErrorTitle => 'Error de grabación';

  @override
  String get recordingSaveFailed => 'Error al guardar la grabación';

  @override
  String get processingErrorTitle =>
      'Se produjo un error durante el procesamiento';

  @override
  String statusError(String message) {
    return 'Error: $message';
  }

  @override
  String statusOrganized(String summary) {
    return 'Organizado: $summary';
  }

  @override
  String get statusTapToRecord => 'Toca para empezar a grabar';

  @override
  String get statusRecording => 'Grabando… toca de nuevo para detener';

  @override
  String get statusProcessing => 'La IA está analizando…';

  @override
  String get statusProcessingSorting =>
      'Organizando en diario, ideas y tareas…';

  @override
  String get statusProcessingFinishing => 'Terminando…';

  @override
  String maxRecordingSeconds(int seconds) {
    return 'Cada grabación puede durar hasta $seconds segundos';
  }

  @override
  String maxRecordingMinutes(int minutes) {
    return 'Cada grabación puede durar hasta $minutes minutos';
  }

  @override
  String streakTooltip(int days) {
    return 'Racha de $days días';
  }

  @override
  String get textComposeTooltip => 'Escribir como texto';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get menuCustomDictionary => 'Diccionario personalizado';

  @override
  String get menuSummaryLevel => 'Nivel de resumen de la IA';

  @override
  String get textComposerTitle => 'Escribir como texto';

  @override
  String get textComposerDescription =>
      'Úsalo cuando no puedas hablar. La IA lo organiza en una entrada de diario, tarea o idea igual que una grabación.';

  @override
  String get textComposerHint =>
      'p. ej. Pedir cita con el dentista mañana a las 3pm';

  @override
  String get textComposerSubmit => 'Dejar que la IA lo analice';

  @override
  String get summaryLevelSheetTitle => 'Nivel de resumen de la IA';

  @override
  String get summaryLevelSheetDescription =>
      'Elige cuánto acorta la IA el contenido del diario de las grabaciones o el texto. Esto no afecta a la concisión de las tareas.';

  @override
  String get summaryLevelPreserveLabel => 'Preservar';

  @override
  String get summaryLevelStandardLabel => 'Estándar';

  @override
  String get summaryLevelCompactLabel => 'Compacto';

  @override
  String get summaryLevelPreserveDescription =>
      'Mantiene los sentimientos, la forma de hablar y los nombres exactamente como se dijeron, sin resumir.';

  @override
  String get summaryLevelStandardDescription =>
      'Ordena las repeticiones redundantes manteniendo una longitud natural de diario.';

  @override
  String get summaryLevelCompactDescription =>
      'Condensa todo a lo esencial en 1-2 frases.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get displaySectionTitle => 'Pantalla';

  @override
  String get darkModeTitle => 'Modo oscuro';

  @override
  String get darkModeSubtitle => 'Cambiar a un aspecto más suave para la vista';

  @override
  String get themeColorTitle => 'Color del tema';

  @override
  String get themeColorSubtitle =>
      'Cambiar el color de acento general de la app';

  @override
  String get themeColorSheetTitle => 'Elige un color de tema';

  @override
  String get settingsProBadge => 'Solo Pro';

  @override
  String get integrationsSettingsTitle => 'Integraciones';

  @override
  String get integrationsCalendarRowTitle => 'Integración con calendario';

  @override
  String get integrationsScreenTitle => 'Integraciones';

  @override
  String get integrationsDescription =>
      'Elige un calendario ya configurado en este dispositivo (como Calendario de iOS o una cuenta de Google añadida en los ajustes del sistema). Una vez activado, cualquier tarea con una fecha y hora específicas se añadirá allí automáticamente como un evento.';

  @override
  String get integrationsOff => 'Desactivado';

  @override
  String get integrationsPermissionDenied =>
      'No se concedió acceso al calendario. Puedes permitirlo desde la app de Ajustes del sistema.';

  @override
  String get integrationsNoCalendars =>
      'No se encontraron calendarios editables en este dispositivo. Añade un calendario (como una cuenta de Google) en la app de Ajustes del sistema y luego actualiza.';

  @override
  String get integrationsRefresh => 'Actualizar';

  @override
  String get appleRemindersSettingsTitle => 'Recordatorios';

  @override
  String get appleRemindersScreenTitle => 'Integración con Recordatorios';

  @override
  String get appleRemindersDescription =>
      'Elige una lista de la app Recordatorios del dispositivo. Una vez activado, cualquier tarea con fecha límite se añadirá allí automáticamente, y completarla en la app también la marcará como completada en Recordatorios.';

  @override
  String get appleRemindersPermissionDenied =>
      'No se concedió acceso a Recordatorios. Puedes permitirlo desde la app de Ajustes del sistema.';

  @override
  String get appleRemindersNoLists =>
      'No se encontraron listas de recordatorios editables. Crea una lista en la app Recordatorios y luego actualiza.';

  @override
  String get accountSectionTitle => 'Cuenta';

  @override
  String accountSignedInAs(String email) {
    return 'Sesión iniciada como $email';
  }

  @override
  String get accountNotSignedIn => 'Sesión no iniciada';

  @override
  String get accountNotSignedInDescription =>
      'Inicia sesión con Google o Apple para llevar tus datos de diario a otros dispositivos';

  @override
  String get accountScreenTitle => 'Cuenta';

  @override
  String get accountSignInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get accountSignInWithApple => 'Iniciar sesión con Apple';

  @override
  String get accountSignOutButton => 'Cerrar sesión';

  @override
  String get accountRestoreButton => 'Restaurar desde la nube';

  @override
  String get watchPairingButton => 'Emparejar Apple Watch';

  @override
  String get watchPairingSuccessTitle => 'Emparejado';

  @override
  String get watchPairingSuccessMessage =>
      'Tu Apple Watch está emparejado. Ahora puedes grabar desde el Watch por sí solo.';

  @override
  String get syncErrorBannerMessage =>
      'Algunos datos no se pudieron sincronizar';

  @override
  String get syncErrorBannerAction => 'Revisar';

  @override
  String get loadErrorBannerMessage => 'Error al cargar tus datos';

  @override
  String get loadErrorBannerAction => 'Reintentar';

  @override
  String get mediaStorageWarningBannerMessage =>
      'Tu almacenamiento en la nube de fotos/vídeos está casi lleno';

  @override
  String get mediaStorageFullBannerMessage =>
      'El almacenamiento en la nube de fotos/vídeos está lleno. Las fotos y vídeos nuevos no se sincronizarán';

  @override
  String get mediaStorageBannerAction => 'Limpiar';

  @override
  String get accountSyncingMessage => 'Sincronizando…';

  @override
  String get accountSyncCompleteTitle => 'Listo';

  @override
  String get accountSyncCompleteMessage => 'Sincronización completa.';

  @override
  String get accountErrorTitle => 'Error';

  @override
  String get accountErrorNetwork =>
      'Se produjo un error de red. Inténtalo de nuevo en un momento.';

  @override
  String get accountErrorUnknown =>
      'Algo salió mal. Inténtalo de nuevo en un momento.';

  @override
  String get accountSignOutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get accountSignOutConfirmMessage =>
      'Tus datos en este dispositivo no se eliminarán. Vuelve a iniciar sesión cuando quieras para reanudar la sincronización.';

  @override
  String get accountDeleteButton => 'Eliminar cuenta';

  @override
  String get accountDeleteConfirmTitle => '¿Eliminar tu cuenta?';

  @override
  String get accountDeleteConfirmMessage =>
      'Esto no se puede deshacer. Tus entradas de diario, ideas y tareas en la nube, tus fotos y vídeos, y todo lo que hay en este dispositivo se eliminarán permanentemente.';

  @override
  String get accountDeleteConfirmButton => 'Eliminar';

  @override
  String get accountDeleteCompleteTitle => 'Eliminada';

  @override
  String get accountDeleteCompleteMessage =>
      'Tu cuenta y todos sus datos han sido eliminados.';

  @override
  String get accountMediaSyncFreeNote =>
      'Solo se respalda el texto (entradas de diario, ideas y tareas). Las fotos y vídeos no se sincronizan con la nube — eso está limitado a los planes mensual/anual (no incluido en el plan de por vida).';

  @override
  String get accountMediaSyncProNote =>
      'Las fotos y vídeos también se respaldan en la nube.';

  @override
  String get supportSectionTitle => 'Soporte';

  @override
  String get contactSupportTitle => 'Contáctanos';

  @override
  String get contactSupportEmailSubject => 'Soporte de Voice Brain';

  @override
  String get planSectionTitle => 'Plan';

  @override
  String get planCurrentTitle => 'Plan actual';

  @override
  String get planProTitle => 'Plan Pro';

  @override
  String get planFreeTitle => 'Plan gratuito';

  @override
  String get planProSubtitle =>
      'Hasta 15 minutos por grabación, 30 grabaciones al día';

  @override
  String get planFreeSubtitle =>
      'Hasta 60 segundos por grabación, 3 grabaciones gratis al día';

  @override
  String get planManage => 'Gestionar';

  @override
  String get planUpgrade => 'Mejorar';

  @override
  String get paywallTitle => 'Plan Pro';

  @override
  String get paywallSectionTitle => 'Lo que desbloquea Pro';

  @override
  String get paywallSectionSubtitle =>
      'Acceso ilimitado a todas las funciones Pro';

  @override
  String get paywallBenefitDurationTitle => 'Grabaciones más largas';

  @override
  String get paywallBenefitDurationBefore => '60 seg';

  @override
  String get paywallBenefitDurationAfter => '15 min';

  @override
  String get paywallBenefitDurationDesc =>
      'Habla todo el tiempo que necesites sin perder detalles';

  @override
  String get paywallBenefitCountTitle => 'Más usos al día';

  @override
  String get paywallBenefitCountBefore => '3 / día';

  @override
  String get paywallBenefitCountAfter => '30 / día';

  @override
  String get paywallBenefitCountDesc =>
      'Captura cada pensamiento, en el momento en que surja';

  @override
  String get paywallMonthlyCapNote =>
      '* El tiempo total de grabación tiene un límite de 240 minutos al mes. Si alcanzas el límite, puedes comprar un paquete de minutos extra para seguir grabando.';

  @override
  String get paywallBenefitCustomBackgroundTitle => 'Añade ';

  @override
  String get paywallBenefitCustomBackgroundHighlight => 'tu propia foto';

  @override
  String get paywallBenefitCustomBackgroundDesc =>
      'Haz que cada entrada se sienta tuya';

  @override
  String get paywallBenefitImageLayoutTitle => 'Organiza fotos libremente';

  @override
  String get paywallBenefitImageLayoutDesc =>
      'Arrastra para reposicionar y cambia el tamaño con un control deslizante en cualquier entrada';

  @override
  String get paywallBenefitKnowledgeBaseHighlight =>
      'Preguntar (segundo cerebro)';

  @override
  String get paywallBenefitKnowledgeBaseSuffix => ' está desbloqueado';

  @override
  String get paywallBenefitKnowledgeBaseDesc =>
      'La IA busca en todo lo que has grabado para ayudarte';

  @override
  String get paywallBenefitWeeklyReportTitle => 'Informe Cerebral Semanal';

  @override
  String get paywallBenefitWeeklyReportDesc =>
      'La IA lee tu semana y te entrega lo más destacado';

  @override
  String get paywallBenefitMediaSyncTitle =>
      'Sincronización de fotos y vídeos en la nube';

  @override
  String get paywallBenefitMediaSyncDesc =>
      'Mantén tus recuerdos respaldados de forma segura';

  @override
  String get paywallBenefitMediaSyncBadge => 'Solo planes mensual / anual';

  @override
  String get paywallUnavailable =>
      'No se pudieron cargar los planes ahora mismo. Inténtalo de nuevo más tarde.';

  @override
  String get paywallRestore => 'Restaurar compras';

  @override
  String get paywallTerms => 'Términos de servicio';

  @override
  String get paywallPrivacy => 'Política de privacidad';

  @override
  String get paywallPurchaseFailed =>
      'Algo salió mal. Inténtalo de nuevo más tarde.';

  @override
  String get paywallRestoreNotFound =>
      'No se encontró ninguna compra restaurable.';

  @override
  String get paywallPlanMonthly => 'Mensual';

  @override
  String get paywallPlanAnnual => 'Anual';

  @override
  String get paywallPlanLifetime => 'De por vida';

  @override
  String get paywallPlanRecommended => 'Recomendado';

  @override
  String get paywallPlanLifetimeCaption =>
      'No incluye sincronización de fotos/vídeos en la nube';

  @override
  String get paywallPlanComingSoon => 'Próximamente';

  @override
  String get paywallContinueButton => 'Continuar';

  @override
  String homeUsageToday(int used, int limit) {
    return 'Hoy $used / $limit';
  }

  @override
  String homeUsageMonth(int usedMinutes, int limitMinutes) {
    return 'Este mes $usedMinutes / $limitMinutes min';
  }

  @override
  String get buyMinutesCta => 'Comprar más minutos';

  @override
  String get buyMinutesTitle => 'Comprar minutos extra';

  @override
  String get buyMinutesDescription =>
      'Has alcanzado el límite de tiempo de grabación de este mes. Compra un paquete de minutos extra para seguir grabando ahora mismo, sin esperar al próximo mes.';

  @override
  String get buyMinutesDescriptionProactive =>
      'Los planes Pro y De por vida incluyen 240 minutos de grabación al mes. También puedes comprar un paquete extra de 60 minutos por adelantado, para cuando alcances ese límite.';

  @override
  String get buyMinutesUnavailable =>
      'El paquete de minutos extra no está disponible ahora mismo. Inténtalo de nuevo más tarde.';

  @override
  String get buyMinutesPurchaseFailed => 'La compra falló. Inténtalo de nuevo.';

  @override
  String get buyMinutesPurchaseSuccess =>
      'Minutos extra añadidos. Ya puedes seguir grabando.';

  @override
  String buyMinutesPurchaseButton(String price) {
    return 'Comprar +60 min ($price)';
  }

  @override
  String get notificationSectionTitle => 'Notificaciones';

  @override
  String get reminderNotificationsTitle => 'Notificaciones de recordatorio';

  @override
  String get notificationCheckingStatus => 'Comprobando…';

  @override
  String get notificationGranted => 'Permitido';

  @override
  String get notificationDenied =>
      'No permitido (los recordatorios no se entregarán)';

  @override
  String get allow => 'Permitir';

  @override
  String get notificationPermissionDialogTitle =>
      'Las notificaciones no están permitidas';

  @override
  String get notificationPermissionDialogMessage =>
      'Permite las notificaciones para recibir recordatorios. Puedes cambiar esto en la app de Ajustes.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get customDictionaryTitle => 'Diccionario personalizado';

  @override
  String get customDictionaryDescription =>
      'Registra nombres de amigos, grupos o términos técnicos para que se prioricen durante el reconocimiento de voz. Añadir una nota también ayuda a la IA a detectar y corregir errores ortográficos.';

  @override
  String get wordLabel => 'Palabra';

  @override
  String get wordHint => 'p. ej. Juan Pérez';

  @override
  String get descriptionLabelOptional => 'Descripción (opcional)';

  @override
  String get descriptionHint => 'p. ej. Un amigo de la universidad';

  @override
  String get add => 'Añadir';

  @override
  String get customDictionaryEmpty => 'Aún no hay palabras registradas';

  @override
  String get diaryDayEmpty => 'No hay entradas de diario este día';

  @override
  String get diaryPickDateTooltip => 'Elegir una fecha';

  @override
  String get diaryPreviousWeekTooltip => 'Semana anterior';

  @override
  String get diaryNextWeekTooltip => 'Semana siguiente';

  @override
  String get fontStandard => 'Estándar';

  @override
  String get fontMincho => 'Serif';

  @override
  String get fontHandwriting => 'Manuscrita';

  @override
  String get fontPop => 'Pop';

  @override
  String get fontMonospace => 'Monoespaciada';

  @override
  String get fontGothic => 'Gótica';

  @override
  String get fontRoundGothic => 'Redondeada';

  @override
  String get fontThinMincho => 'Serif fina';

  @override
  String get fontBrush => 'Pincel';

  @override
  String get fontRetro => 'Retro';

  @override
  String get fontImpact => 'Impact';

  @override
  String get fontCute => 'Tierna';

  @override
  String mediaPickFailed(String error) {
    return 'Error al seleccionar la foto/vídeo: $error';
  }

  @override
  String get pickPhotosFromLibrary => 'Elegir fotos';

  @override
  String get pickPhotosFromLibrarySubtitle =>
      'Elige fotos de tu biblioteca para añadir';

  @override
  String get pickVideoFromLibrary => 'Elegir un vídeo';

  @override
  String get pickVideoFromLibrarySubtitle =>
      'Elige un vídeo de tu biblioteca para añadir';

  @override
  String get backgroundSheetTitle => 'Fondo';

  @override
  String get backgroundNone => 'Ninguno';

  @override
  String get emotionSheetTitle => 'Emoción';

  @override
  String get emotionNone => 'Ninguna';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get diaryBgFruit => 'Fruta';

  @override
  String get diaryBgMintPlant => 'Notas botánicas';

  @override
  String get diaryBgCoffee => 'Café';

  @override
  String get diaryBgCake => 'Pastel';

  @override
  String get diaryBgPicnic => 'Cesta de pan';

  @override
  String get diaryBgHeartBalloon => 'Globos de corazón';

  @override
  String get diaryBgParkDay => 'Campo de dientes de león';

  @override
  String get diaryBgNightSky => 'Cielo nocturno';

  @override
  String get diaryBgSleepingCat => 'Gato dormido';

  @override
  String get diaryBgBlueCheckBouquet => 'Ramo a cuadros azules';

  @override
  String get diaryBgVintageCamera => 'Cámara vintage';

  @override
  String get diaryBgShopping => 'Compras';

  @override
  String get diaryBgNewYork => 'Nueva York';

  @override
  String get diaryBgBeach => 'Playa';

  @override
  String get diaryBgPalmTree => 'Palmera';

  @override
  String get diaryBgEuropeanStreet => 'Calle europea';

  @override
  String get diaryBgRunning => 'Corriendo';

  @override
  String get diaryBgLivingRoom => 'Salón';

  @override
  String get diaryBgMusicNote => 'Nota musical';

  @override
  String get diaryBgLetter => 'Carta';

  @override
  String get diaryBgDeepSea => 'Mar profundo';

  @override
  String get diaryBgSnow => 'Nieve';

  @override
  String get diaryBgSoccerBall => 'Balón de fútbol';

  @override
  String get diaryBgLuxuryFrame => 'Marco de lujo';

  @override
  String get diaryBgClock => 'Reloj';

  @override
  String get fontSheetTitle => 'Fuente';

  @override
  String get fontSheetSizeLabel => 'Tamaño del título';

  @override
  String get fontSheetColorLabel => 'Color del texto';

  @override
  String get fontSheetStyleLabel => 'Estilo de fuente';

  @override
  String get closeTooltip => 'Cerrar';

  @override
  String get favoriteSettingsTooltip => 'Ajustes favoritos';

  @override
  String get favoriteSettingsSheetTitle => 'Ajustes favoritos';

  @override
  String get favoriteSettingsDescription =>
      'El estilo de texto y fondo predeterminados usados para las entradas de diario nuevas';

  @override
  String get addCustomBackgroundTile => 'Añadir tu propia foto';

  @override
  String get toolbarMedia => 'Foto/Vídeo';

  @override
  String get toolbarBackground => 'Fondo';

  @override
  String get toolbarText => 'Texto';

  @override
  String get titleHint => 'Título';

  @override
  String get bodyHint => 'Escribe más aquí…';

  @override
  String get filterAll => 'Todo';

  @override
  String get filterToday => 'Hoy';

  @override
  String get filterThisWeek => 'Esta semana';

  @override
  String get filterWithinMonth => 'En un mes';

  @override
  String get filterCompleted => 'Completadas';

  @override
  String get tasksEmpty => 'Aún no hay tareas\nPrueba a decir \"Tengo que…\"';

  @override
  String get tasksFilterEmpty => 'Ninguna tarea coincide con este filtro';

  @override
  String get reminderLabel => 'Recordatorio de notificación';

  @override
  String get removeReminderTooltip => 'Quitar recordatorio';

  @override
  String get addReminder => 'Añadir recordatorio';

  @override
  String get taskContentHint => 'Contenido de la tarea';

  @override
  String get allDayLabel => 'Todo el día';

  @override
  String get taskScheduleLabel => 'Hora de inicio y fin';

  @override
  String get startTimeCaption => 'Inicio';

  @override
  String get endTimeCaption => 'Fin';

  @override
  String get addStartTime => 'Fijar hora de inicio';

  @override
  String get removeStartTimeTooltip => 'Quitar hora de inicio';

  @override
  String get addEndTime => 'Añadir hora de fin';

  @override
  String get removeEndTimeTooltip => 'Quitar hora de fin';

  @override
  String get manualTaskFabTooltip => 'Añadir tarea';

  @override
  String get manualTaskScreenTitle => 'Añadir tarea';

  @override
  String get manualTaskTitleHint => 'Tarea (p. ej. Comprar leche)';

  @override
  String get manualTaskTitleRequiredError => 'Introduce una tarea';

  @override
  String get manualDiaryFabTooltip => 'Añadir entrada de diario';

  @override
  String get manualDiaryScreenTitle => 'Añadir entrada de diario';

  @override
  String get manualDiaryTitleHint => 'Título (opcional)';

  @override
  String get manualDiaryContentHint => '¿Qué tal tu día?';

  @override
  String get manualDiaryContentRequiredError => 'Introduce algo de contenido';

  @override
  String get manualIdeaFabTooltip => 'Añadir idea';

  @override
  String get manualIdeaScreenTitle => 'Añadir idea';

  @override
  String get manualIdeaTitleHint => 'Título (opcional)';

  @override
  String get manualIdeaContentHint => 'Contenido de la idea';

  @override
  String get manualIdeaContentRequiredError => 'Introduce algo de contenido';

  @override
  String get ideasEmpty =>
      'Aún no hay ideas\nPrueba a decir lo que se te ocurra';

  @override
  String get editIdeaTitle => 'Editar idea';

  @override
  String get ideaTitleHint => 'Título (opcional)';

  @override
  String get ideaContentHint => 'Contenido de la idea';

  @override
  String get ideaStatusConsidering => 'Considerando';

  @override
  String get ideaStatusAdopted => 'Adoptada';

  @override
  String get ideaStatusRejected => 'Rechazada';

  @override
  String get ideaStatusNone => 'Sin estado';

  @override
  String get ideaStatusLabel => 'Estado';

  @override
  String get ideaTagLabel => 'Etiqueta';

  @override
  String get ideaTagHint => 'Etiqueta (opcional)';

  @override
  String get ideaSearchHint => 'Buscar ideas';

  @override
  String get ideaPinTooltip => 'Fijar';

  @override
  String get ideaUnpinTooltip => 'Desfijar';

  @override
  String get ideaSortNewestFirstTooltip =>
      'Ordenado de más reciente a más antiguo (toca para invertir)';

  @override
  String get ideaSortOldestFirstTooltip =>
      'Ordenado de más antiguo a más reciente (toca para invertir)';

  @override
  String get ideasFilterEmpty => 'Ninguna idea coincide con este filtro';

  @override
  String get reviewTitle => 'Revisar contenido';

  @override
  String get reviewDescription =>
      'Edita el texto si no es correcto. Arrastra una tarjeta para moverla entre diario, idea y tarea.';

  @override
  String get reviewDescriptionNoDrag => 'Edita el texto si no es correcto';

  @override
  String get sectionDiary => 'Diario';

  @override
  String get sectionIdea => 'Idea';

  @override
  String get sectionTask => 'Tarea';

  @override
  String get sectionEmptyPlaceholder => 'Aún no hay contenido';

  @override
  String get discard => 'Descartar';

  @override
  String get dragCardHere => 'Arrastra una tarjeta aquí';

  @override
  String get addCardButton => 'Añadir tarjeta';

  @override
  String get genericProcessingError =>
      'Se produjo un error durante el procesamiento';

  @override
  String get usageFetchError => 'Error al cargar el estado de uso';

  @override
  String get watchNotPairedMessage =>
      'Tu Apple Watch no está emparejado. Manténlo cerca y termina el emparejamiento primero en la app Watch de Apple.';

  @override
  String get backgroundRecordingChannelName => 'Grabación en segundo plano';

  @override
  String get backgroundRecordingChannelDescription =>
      'Mantiene la grabación activa mientras la app está en segundo plano o la pantalla apagada';

  @override
  String get backgroundRecordingNotificationTitle => 'Grabando…';

  @override
  String get backgroundRecordingNotificationText => 'Toca para volver a la app';

  @override
  String get reminderNotificationTitle => 'Recordatorio';

  @override
  String get reminderNotificationChannelName => 'Recordatorios de tareas';

  @override
  String get reminderNotificationChannelDescription =>
      'Recordatorios con hora para las tareas creadas a partir de tus notas de voz';

  @override
  String get weeklyReportNotificationTitle =>
      '¡Tu Informe Cerebral Semanal está listo!';

  @override
  String get weeklyReportNotificationBody =>
      'La IA ha repasado tu semana. Toca para verlo.';

  @override
  String get weeklyReportNotificationChannelName =>
      'Notificaciones del informe semanal';

  @override
  String get weeklyReportNotificationChannelDescription =>
      'Te avisa cada domingo a las 8pm cuando tu Informe Cerebral Semanal está listo';

  @override
  String get weeklyReportHistoryTooltip => 'Informes anteriores';

  @override
  String get weeklyReportHistoryTitle => 'Historial de informes semanales';

  @override
  String get weeklyReportHistoryEmpty => 'Aún no hay informes guardados';

  @override
  String get knowledgeBaseTitle => 'Segundo cerebro';

  @override
  String get knowledgeBaseDescription =>
      'La IA repasa todas tus entradas de diario, ideas y tareas para responderte.';

  @override
  String get knowledgeBaseInputHint =>
      'p. ej. ¿Cuál era esa idea de app que mencioné el mes pasado?';

  @override
  String get knowledgeBaseSend => 'Enviar';

  @override
  String get knowledgeBaseThinking => 'Repasando tus entradas anteriores…';

  @override
  String get knowledgeBaseEmpty =>
      'Aún no hay nada grabado. Graba algo y luego vuelve a preguntar.';

  @override
  String get knowledgeBaseErrorTitle => 'No se pudo obtener una respuesta';

  @override
  String get knowledgeBaseProLockedDescription =>
      'Chatear con todas tus entradas es una función Pro. Mejora tu plan para desbloquearla.';

  @override
  String get knowledgeBaseSourcesLabel => 'Entradas referenciadas';

  @override
  String get knowledgeBaseSourceSheetTitle =>
      'Entrada referenciada para esta respuesta';

  @override
  String get knowledgeBaseSourceNotFound => 'No se pudo encontrar esta entrada';

  @override
  String get knowledgeBaseSignInNudgeText =>
      'Vincula una cuenta para que las respuestas puedan citar tus entradas anteriores con resultados más precisos.';

  @override
  String get knowledgeBaseSignInNudgeCta => 'Vincular cuenta';

  @override
  String get knowledgeBaseVoiceQuestion => 'Preguntar por voz';

  @override
  String get knowledgeBaseRecordingQuestion => 'Grabando tu pregunta…';

  @override
  String get knowledgeBaseTranscribing => 'Transcribiendo…';

  @override
  String get knowledgeBasePlayAnswer => 'Reproducir respuesta';

  @override
  String get knowledgeBaseStopAnswer => 'Detener reproducción';

  @override
  String get weeklyReportSettingsTitle => 'Informe Cerebral Semanal';

  @override
  String get weeklyReportSettingsSubtitle => 'Entregado cada semana';

  @override
  String get weeklyReportTitle => 'Informe Cerebral Semanal';

  @override
  String get weeklyReportProLockedDescription =>
      'El Informe Cerebral Semanal es una función Pro. Mejora tu plan para desbloquearla.';

  @override
  String get weeklyReportRetry => 'Reintentar';

  @override
  String get weeklyReportLoadingInsights =>
      'La IA está reflexionando sobre tu semana…';

  @override
  String get weeklyReportErrorTitle => 'No se pudo cargar el informe';

  @override
  String get weeklyReportEmotionSectionTitle => 'Tendencias emocionales';

  @override
  String get weeklyReportNoEmotionData =>
      'Aún no hay entradas emocionales esta semana';

  @override
  String get weeklyReportConstellationSectionTitle => 'Gráfico de emociones';

  @override
  String get weeklyReportCategorySectionTitle => 'Mezcla de categorías';

  @override
  String get weeklyReportNoCategoryData => 'Aún no hay entradas esta semana';

  @override
  String get weeklyReportKeywordsSectionTitle => 'Mapa cerebral';

  @override
  String get weeklyReportBrainMapSubtitle =>
      'Cómo se repartió tu semana entre estados de ánimo positivos, normales y negativos';

  @override
  String get weeklyReportWordsSectionTitle => 'Palabras de la semana';

  @override
  String get weeklyReportWordsEmpty => 'Aún no hay palabras destacadas';

  @override
  String get weeklyReportWordDetailEmpty =>
      'No se encontraron entradas que mencionen esta palabra';

  @override
  String get emotionCategoryPositive => 'Positivo';

  @override
  String get emotionCategoryNormal => 'Normal';

  @override
  String get emotionCategoryNegative => 'Negativo';

  @override
  String get weeklyReportIdeasSectionTitle => 'Ideas que brillaron';

  @override
  String get weeklyReportNoIdeas => 'Aún no hay ideas registradas esta semana';

  @override
  String get weeklyReportHighlightSectionTitle =>
      'Lo más destacado de la semana';

  @override
  String get weeklyReportNoHighlight =>
      'Aún no hay entradas de diario esta semana';

  @override
  String get weeklyReportAchievementSectionTitle => 'Logros de esta semana';

  @override
  String weeklyReportTasksCompleted(int count) {
    return '$count tareas completadas';
  }

  @override
  String weeklyReportDiaryCount(int count) {
    return '$count entradas de diario';
  }

  @override
  String get weeklyReportEncouragement => '¡Lo has hecho genial esta semana!';

  @override
  String get weeklyReportAdviceSectionTitle => 'Consejo para la próxima semana';

  @override
  String get weeklyReportLetterSectionTitle => 'Tu carta semanal';

  @override
  String get weeklyReportLetterLocked =>
      'La carta de esta semana llega el domingo a las 8:00 PM. La mantendremos en secreto hasta entonces.';

  @override
  String get weeklyReportShareTooltip => 'Compartir como imagen';

  @override
  String get weeklyReportShareCaption => 'Así fue mi semana 📝 #VoiceBrain';
}
