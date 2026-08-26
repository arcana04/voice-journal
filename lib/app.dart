import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/root_screen.dart';
import 'state/background_store.dart';
import 'state/calendar_store.dart';
import 'state/custom_words_store.dart';
import 'state/journal_store.dart';
import 'state/record_trigger_store.dart';
import 'state/settings_store.dart';
import 'state/text_style_store.dart';

class VoiceJournalApp extends StatelessWidget {
  const VoiceJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsStore()..load()),
        ChangeNotifierProvider(create: (_) => BackgroundStore()..load()),
        ChangeNotifierProvider(create: (_) => CalendarStore()..load()),
        ChangeNotifierProvider(create: (_) => JournalStore()..load()),
        ChangeNotifierProvider(create: (_) => CustomWordsStore()..load()),
        ChangeNotifierProvider(create: (_) => TextStyleStore()..load()),
        ChangeNotifierProvider(create: (_) => RecordTriggerStore()),
      ],
      child: Consumer<SettingsStore>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'VoiceJournal',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              scaffoldBackgroundColor: Colors.white,
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: Colors.black,
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                surfaceTintColor: Colors.transparent,
              ),
            ),
            home: const RootScreen(),
          );
        },
      ),
    );
  }
}
