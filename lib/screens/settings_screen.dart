import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ダークモード'),
            value: settings.darkMode,
            onChanged: (value) => settings.setDarkMode(value),
          ),
        ],
      ),
    );
  }
}
