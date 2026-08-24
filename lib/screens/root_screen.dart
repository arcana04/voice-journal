import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'settings_screen.dart';
import 'timeline_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    TimelineScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.mic_none), label: '録音'),
          NavigationDestination(icon: Icon(Icons.view_agenda_outlined), label: 'タイムライン'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '設定'),
        ],
      ),
    );
  }
}
