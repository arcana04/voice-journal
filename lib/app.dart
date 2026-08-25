import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/root_screen.dart';
import 'state/journal_store.dart';
import 'state/settings_store.dart';

class VoiceJournalApp extends StatelessWidget {
  const VoiceJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsStore()..load()),
        ChangeNotifierProvider(create: (_) => JournalStore()..load()),
      ],
      child: Consumer<SettingsStore>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'VoiceJournal',
            debugShowCheckedModeBanner: false,
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
              useMaterial3: true,
            ),
            home: const RootScreen(),
          );
        },
      ),
    );
  }
}
