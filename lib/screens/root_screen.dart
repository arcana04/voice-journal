import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/deep_link_service.dart';
import '../state/record_trigger_store.dart';
import '../widgets/floating_nav_bar.dart';
import 'diary_screen.dart';
import 'home_screen.dart';
import 'idea_screen.dart';
import 'knowledge_base_screen.dart';
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
    KnowledgeBaseScreen(),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          FloatingNavDestination(
            icon: Icons.mic_none,
            selectedIcon: Icons.mic,
            label: l10n.navRecord,
          ),
          FloatingNavDestination(
            icon: Icons.menu_book_outlined,
            selectedIcon: Icons.menu_book,
            label: l10n.navDiary,
          ),
          FloatingNavDestination(
            icon: Icons.lightbulb_outline,
            selectedIcon: Icons.lightbulb,
            label: l10n.navIdea,
          ),
          FloatingNavDestination(
            icon: Icons.checklist_outlined,
            selectedIcon: Icons.checklist,
            label: l10n.navTask,
          ),
          FloatingNavDestination(
            icon: Icons.psychology_outlined,
            selectedIcon: Icons.psychology,
            label: l10n.navKnowledgeBase,
          ),
        ],
      ),
    );
  }
}
