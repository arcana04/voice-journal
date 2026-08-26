import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/deep_link_service.dart';
import '../state/record_trigger_store.dart';
import '../widgets/floating_nav_bar.dart';
import 'diary_screen.dart';
import 'home_screen.dart';
import 'idea_screen.dart';
import 'task_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;
  final DeepLinkService _deepLinks = DeepLinkService();

  static const _screens = [
    HomeScreen(),
    DiaryScreen(),
    IdeaScreen(),
    TaskScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _deepLinks.init(onRecordRequested: _handleRecordRequested);
  }

  @override
  void dispose() {
    _deepLinks.dispose();
    super.dispose();
  }

  void _handleRecordRequested() {
    if (!mounted) return;
    setState(() => _index = 0);
    context.read<RecordTriggerStore>().requestRecordNow();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          FloatingNavDestination(
            icon: Icons.mic_none,
            selectedIcon: Icons.mic,
            label: '録音',
          ),
          FloatingNavDestination(
            icon: Icons.menu_book_outlined,
            selectedIcon: Icons.menu_book,
            label: '日記',
          ),
          FloatingNavDestination(
            icon: Icons.lightbulb_outline,
            selectedIcon: Icons.lightbulb,
            label: 'アイデア',
          ),
          FloatingNavDestination(
            icon: Icons.checklist_outlined,
            selectedIcon: Icons.checklist,
            label: 'タスク',
          ),
        ],
      ),
    );
  }
}
