import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_store.dart';

/// Top-left pill showing which tab is currently active (日記/アイデア/タスク),
/// so a screenshot or a quick glance makes the screen identifiable on its own.
class ScreenLabelBadge extends StatelessWidget {
  const ScreenLabelBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsStore>().accentColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, Color.lerp(accent, Colors.black, 0.25)!],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
