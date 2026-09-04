import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root_screen.dart';
import 'state/account_store.dart';
import 'state/apple_reminders_store.dart';
import 'state/calendar_store.dart';
import 'state/custom_words_store.dart';
import 'state/journal_store.dart';
import 'state/record_trigger_store.dart';
import 'state/settings_store.dart';
import 'state/subscription_store.dart';
import 'state/text_style_store.dart';

DatePickerThemeData _datePickerTheme(ColorScheme scheme, Color accent) {
  Color onSelected(Set<WidgetState> states, Color unselected) =>
      states.contains(WidgetState.selected) ? Colors.white : unselected;
  Color bgSelected(Set<WidgetState> states) =>
      states.contains(WidgetState.selected) ? accent : Colors.transparent;

  return DatePickerThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    headerBackgroundColor: Colors.transparent,
    headerForegroundColor: scheme.onSurface,
    todayBorder: BorderSide(color: accent, width: 1.5),
    todayForegroundColor: WidgetStateProperty.resolveWith(
      (states) => onSelected(states, accent),
    ),
    todayBackgroundColor: WidgetStateProperty.resolveWith(bgSelected),
    dayForegroundColor: WidgetStateProperty.resolveWith(
      (states) => onSelected(states, scheme.onSurface),
    ),
    dayBackgroundColor: WidgetStateProperty.resolveWith(bgSelected),
    dayOverlayColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.1)),
    yearForegroundColor: WidgetStateProperty.resolveWith(
      (states) => onSelected(states, scheme.onSurface),
    ),
    yearBackgroundColor: WidgetStateProperty.resolveWith(bgSelected),
    weekdayStyle: TextStyle(color: scheme.outline, fontWeight: FontWeight.w700),
    confirmButtonStyle: FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    cancelButtonStyle: OutlinedButton.styleFrom(
      foregroundColor: accent,
      side: BorderSide(color: accent.withValues(alpha: 0.4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

ThemeData _buildTheme(
  Color scaffoldBackgroundColor,
  Brightness brightness,
  Color accent,
) {
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
    ),
    datePickerTheme: _datePickerTheme(scheme, accent),
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
            theme: _buildTheme(Colors.white, Brightness.light, settings.accentColor),
            darkTheme: _buildTheme(Colors.black, Brightness.dark, settings.accentColor),
            // homeにsettings.loaded等で分岐する条件式を直接渡すと、
            // MaterialAppのNavigatorがルート遷移として扱ってしまい、
            // 古い方の画面がOffstageで生き残ったまま新しい画面と同時に
            // マウントされ続ける不具合が実機・シミュレータの両方で確認された
            // （RootScreen/HomeScreenが2つ同時に存在し、ロック画面ウィジェット
            // からの録音開始が二重に走ってネイティブ側で衝突していた）。
            // homeは常にこの1つのAppGateウィジェットに固定し、ロード状態による
            // 出し分けはその内側の通常のbuild()に任せることで回避する。
            home: const _AppGate(),
          );
        },
      ),
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    if (!settings.loaded) return const SizedBox.shrink();
    if (!settings.hasSeenOnboarding) {
      return OnboardingScreen(onFinished: settings.completeOnboarding);
    }
    return const RootScreen();
  }
}
