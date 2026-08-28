import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/usage_status.dart';
import '../services/backend_service.dart';
import '../services/reminder_service.dart';
import '../state/account_store.dart';
import '../state/background_store.dart';
import '../state/calendar_store.dart';
import '../state/settings_store.dart';
import '../state/subscription_store.dart';
import 'account_screen.dart';
import 'background_select_screen.dart';
import 'integration_select_screen.dart';
import 'paywall_screen.dart';
import 'weekly_report_screen.dart';

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
      final l10n = AppLocalizations.of(context)!;
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.notificationPermissionDialogTitle),
          content: Text(l10n.notificationPermissionDialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.openSettings),
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(l10n.displaySectionTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Consumer<SettingsStore>(
              builder: (context, settings, _) {
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    settings.darkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                  ),
                  title: Text(l10n.darkModeTitle),
                  value: settings.darkMode,
                  onChanged: (value) =>
                      context.read<SettingsStore>().setDarkMode(value),
                );
              },
            ),
            Consumer<BackgroundStore>(
              builder: (context, backgroundStore, _) {
                final selected = backgroundStore.selected;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      selected.asset,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(l10n.appBackgroundSettingsTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BackgroundSelectScreen(),
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 32),
            Text(
              l10n.integrationsSettingsTitle,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Consumer<CalendarStore>(
              builder: (context, calendarStore, _) {
                final name = calendarStore.selectedCalendarName;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l10n.integrationsSettingsTitle),
                  subtitle: Text(
                    calendarStore.selectedCalendarId == null
                        ? l10n.integrationsOff
                        : (name ?? l10n.integrationsOff),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const IntegrationSelectScreen(),
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 32),
            Consumer<SubscriptionStore>(
              builder: (context, subscription, _) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insights_outlined),
                  title: Text(l10n.weeklyReportSettingsTitle),
                  trailing: subscription.isPro
                      ? const Icon(Icons.chevron_right)
                      : const Icon(Icons.lock_outline, size: 18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
                  ),
                );
              },
            ),
            const Divider(height: 32),
            Text(l10n.planSectionTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Consumer<SubscriptionStore>(
              builder: (context, subscription, _) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    subscription.isPro
                        ? Icons.workspace_premium
                        : Icons.workspace_premium_outlined,
                  ),
                  title: Text(
                    subscription.isPro ? l10n.planProTitle : l10n.planFreeTitle,
                  ),
                  subtitle: Text(
                    subscription.isPro
                        ? l10n.planProSubtitle
                        : l10n.planFreeSubtitle,
                  ),
                  trailing: subscription.isPro
                      ? TextButton(
                          onPressed: () => AppSettings.openAppSettings(
                            type: AppSettingsType.subscriptions,
                          ),
                          child: Text(l10n.planManage),
                        )
                      : FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PaywallScreen(),
                            ),
                          ),
                          child: Text(l10n.planUpgrade),
                        ),
                );
              },
            ),
            const Divider(height: 32),
            Text(l10n.accountSectionTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Consumer<AccountStore>(
              builder: (context, account, _) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    account.isSignedIn
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                  ),
                  title: Text(
                    account.isSignedIn
                        ? l10n.accountSignedInAs(account.email ?? '')
                        : l10n.accountNotSignedIn,
                  ),
                  subtitle: account.isSignedIn
                      ? null
                      : Text(l10n.accountNotSignedInDescription),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  ),
                );
              },
            ),
            const Divider(height: 32),
            Text(l10n.freeTierSectionTitle, style: theme.textTheme.labelLarge),
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
                    title: Text(l10n.freeTierFetchFailed),
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
                  title: Text(l10n.freeTierUsage(usage.used, usage.limit)),
                  subtitle: Text(l10n.freeTierRemaining(usage.remaining)),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshUsage,
                  ),
                );
              },
            ),
            const Divider(height: 32),
            Text(
              l10n.notificationSectionTitle,
              style: theme.textTheme.labelLarge,
            ),
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
                  title: Text(l10n.reminderNotificationsTitle),
                  subtitle: Text(
                    loading
                        ? l10n.notificationCheckingStatus
                        : granted
                        ? l10n.notificationGranted
                        : l10n.notificationDenied,
                  ),
                  trailing: loading || granted
                      ? null
                      : TextButton(
                          onPressed: _requestNotificationPermission,
                          child: Text(l10n.allow),
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
