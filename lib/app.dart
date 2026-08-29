import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root_screen.dart';
import 'state/account_store.dart';
import 'state/apple_reminders_store.dart';
import 'state/background_store.dart';
import 'state/calendar_store.dart';
import 'state/custom_words_store.dart';
import 'state/journal_store.dart';
import 'state/record_trigger_store.dart';
import 'state/settings_store.dart';
import 'state/subscription_store.dart';
import 'state/text_style_store.dart';

/// 日付選択ダイアログ（[showDatePicker]）に使うアクセントカラー。paywall/設定/
/// 日記編集の各画面で使っているインディゴと揃えて、アプリ全体の配色に統一感を
/// 持たせている（アプリ全体の[ColorScheme.primary]自体は青のままなので、
/// このダイアログだけ個別にテーマを与える）。
const _datePickerAccent = Color(0xFF6C5DD3);

DatePickerThemeData _datePickerTheme(ColorScheme scheme) {
  Color onSelected(Set<WidgetState> states, Color unselected) =>
      states.contains(WidgetState.selected) ? Colors.white : unselected;
  Color bgSelected(Set<WidgetState> states) =>
      states.contains(WidgetState.selected)
      ? _datePickerAccent
      : Colors.transparent;

  return DatePickerThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    headerBackgroundColor: Colors.transparent,
    headerForegroundColor: scheme.onSurface,
    todayBorder: const BorderSide(color: _datePickerAccent, width: 1.5),
    todayForegroundColor: WidgetStateProperty.resolveWith(
      (states) => onSelected(states, _datePickerAccent),
    ),
    todayBackgroundColor: WidgetStateProperty.resolveWith(bgSelected),
    dayForegroundColor: WidgetStateProperty.resolveWith(
      (states) => onSelected(states, scheme.onSurface),
    ),
    dayBackgroundColor: WidgetStateProperty.resolveWith(bgSelected),
    dayOverlayColor: WidgetStatePropertyAll(
      _datePickerAccent.withValues(alpha: 0.1),
    ),
    yearForegroundColor: WidgetStateProperty.resolveWith(
      (states) => onSelected(states, scheme.onSurface),
    ),
    yearBackgroundColor: WidgetStateProperty.resolveWith(bgSelected),
    weekdayStyle: TextStyle(color: scheme.outline, fontWeight: FontWeight.w700),
    confirmButtonStyle: FilledButton.styleFrom(
      backgroundColor: _datePickerAccent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    cancelButtonStyle: OutlinedButton.styleFrom(
      foregroundColor: _datePickerAccent,
      side: BorderSide(color: _datePickerAccent.withValues(alpha: 0.4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

ThemeData _buildTheme(Color scaffoldBackgroundColor, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
    ),
    datePickerTheme: _datePickerTheme(scheme),
  );
}

class VoiceJournalApp extends StatelessWidget {
  final String uid;

  const VoiceJournalApp({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsStore()..load()),
        ChangeNotifierProvider(create: (_) => BackgroundStore()..load()),
        ChangeNotifierProvider(create: (_) => CalendarStore()..load()),
        ChangeNotifierProvider(create: (_) => AppleRemindersStore()..load()),
        ChangeNotifierProvider(create: (_) => JournalStore()..load()),
        ChangeNotifierProvider(create: (_) => CustomWordsStore()..load()),
        ChangeNotifierProvider(create: (_) => TextStyleStore()..load()),
        ChangeNotifierProvider(create: (_) => RecordTriggerStore()),
        ChangeNotifierProvider(create: (_) => SubscriptionStore()..initialize(uid)),
        ChangeNotifierProvider(create: (_) => AccountStore()),
      ],
      child: Consumer<SettingsStore>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'VoiceJournal',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            theme: _buildTheme(Colors.white, Brightness.light),
            darkTheme: _buildTheme(Colors.black, Brightness.dark),
            home: !settings.loaded
                ? const SizedBox.shrink()
                : settings.hasSeenOnboarding
                ? const RootScreen()
                : OnboardingScreen(onFinished: settings.completeOnboarding),
          );
        },
      ),
    );
  }
}
