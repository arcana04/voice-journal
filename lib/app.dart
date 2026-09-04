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
            title: 'Voice Brain',
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

/// ネイティブスプラッシュ（起動直後、Flutterの初回フレームが描画されるまで
/// OS側が表示するもの）が消えた瞬間に、そのまま`_SplashView`へ引き継いで
/// アニメーションさせる。設定の読み込みが一瞬で終わっても、意図した
/// アニメーションを最後まで見せるため最短表示時間を設ける（一瞬で切り替わる
/// と「読み込めていないだけ」に見えてしまうため）。
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _minDurationElapsed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _minDurationElapsed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    final ready = settings.loaded && _minDurationElapsed;

    final Widget child;
    if (!ready) {
      child = const _SplashView(key: ValueKey('splash'));
    } else if (!settings.hasSeenOnboarding) {
      child = OnboardingScreen(
        key: const ValueKey('onboarding'),
        onFinished: settings.completeOnboarding,
      );
    } else {
      child = const RootScreen(key: ValueKey('root'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child,
    );
  }
}

/// ネイティブスプラッシュ（`flutter_native_splash`が生成した、白背景+
/// アイコンのみの静止画）と同じ見た目からスタートし、フェード+拡大の
/// アニメーションでロゴを軽く弾ませて見せる。ネイティブ→Flutter切り替え時の
/// 見た目の継ぎ目をできるだけ感じさせない狙い。
class _SplashView extends StatefulWidget {
  const _SplashView({super.key});

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _opacity.value,
            child: Transform.scale(scale: _scale.value, child: child),
          ),
          child: Image.asset(
            'assets/icon/app_icon_foreground.png',
            width: 168,
            height: 168,
          ),
        ),
      ),
    );
  }
}
