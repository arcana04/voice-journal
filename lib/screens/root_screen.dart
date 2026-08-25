import 'package:flutter/material.dart';

import '../widgets/floating_nav_bar.dart';
import 'diary_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'task_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    DiaryScreen(),
    TaskScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          FloatingNavDestination(icon: Icons.mic_none, selectedIcon: Icons.mic, label: '録音'),
          FloatingNavDestination(
            icon: Icons.menu_book_outlined,
            selectedIcon: Icons.menu_book,
            label: '日記',
          ),
          FloatingNavDestination(
            icon: Icons.checklist_outlined,
            selectedIcon: Icons.checklist,
            label: 'タスク',
          ),
          FloatingNavDestination(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: '設定',
          ),
        ],
      ),
    );
  }
}
