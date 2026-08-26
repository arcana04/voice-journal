import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usage_status.dart';
import '../services/backend_service.dart';
import '../services/reminder_service.dart';
import '../state/settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackendService _backend = BackendService();
  final ReminderService _reminders = ReminderService.instance;

  late Future<UsageStatus> _usageFuture = _backend.fetchUsageStatus();
  late Future<bool> _notificationFuture = _reminders
      .hasNotificationPermission();

  void _refreshUsage() {
    setState(() => _usageFuture = _backend.fetchUsageStatus());
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await _reminders.requestNotificationPermission();
    if (!granted && mounted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('通知が許可されていません'),
          content: const Text('リマインダーを届けるには通知を許可してください。設定アプリから変更できます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('設定を開く'),
            ),
          ],
        ),
      );
      if (open == true) {
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
      }
    }
    if (mounted) {
      setState(
        () => _notificationFuture = _reminders.hasNotificationPermission(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ダークモード'),
              value: settings.darkMode,
              onChanged: (value) => settings.setDarkMode(value),
            ),
            const Divider(height: 32),
            Text('無料枠', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            FutureBuilder<UsageStatus>(
              future: _usageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.error_outline),
                    title: const Text('利用状況を取得できませんでした'),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshUsage,
                    ),
                  );
                }
                final usage = snapshot.data!;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mic_none),
                  title: Text('本日の録音回数: ${usage.used} / ${usage.limit}回'),
                  subtitle: Text('残り${usage.remaining}回（日本時間の日付で毎日リセット）'),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshUsage,
                  ),
                );
              },
            ),
            const Divider(height: 32),
            Text('通知', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            FutureBuilder<bool>(
              future: _notificationFuture,
              builder: (context, snapshot) {
                final granted = snapshot.data ?? false;
                final loading =
                    snapshot.connectionState == ConnectionState.waiting;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    granted
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                  ),
                  title: const Text('リマインダー通知'),
                  subtitle: Text(
                    loading
                        ? '確認中…'
                        : granted
                        ? '許可されています'
                        : '許可されていません（リマインダーが届きません）',
                  ),
                  trailing: loading || granted
                      ? null
                      : TextButton(
                          onPressed: _requestNotificationPermission,
                          child: const Text('許可する'),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
