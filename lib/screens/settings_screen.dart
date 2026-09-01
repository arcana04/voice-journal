import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_links.dart';
import '../config/theme_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/reminder_service.dart';
import '../state/account_store.dart';
import '../state/apple_reminders_store.dart';
import '../state/calendar_store.dart';
import '../state/settings_store.dart';
import '../state/subscription_store.dart';
import 'account_screen.dart';
import 'apple_reminders_select_screen.dart';
import 'integration_select_screen.dart';
import 'paywall_screen.dart';
import 'weekly_report_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ReminderService _reminders = ReminderService.instance;

  late Future<bool> _notificationFuture = _reminders
      .hasNotificationPermission();

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

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// サブスクリプション管理画面を開く。app_settingsパッケージの
  /// AppSettingsType.subscriptionsはiOS側にしか実装が無く、Androidで呼んでも
  /// 何も起きない（ボタンが反応しないように見える）ため、Androidでは
  /// Google PlayのサブスクリプションページをURLで直接開く。
  Future<void> _openManageSubscription() async {
    if (Platform.isIOS) {
      await AppSettings.openAppSettings(type: AppSettingsType.subscriptions);
      return;
    }
    await _openUrl(
      'https://play.google.com/store/account/subscriptions?package=com.voicejournal.voicejournal',
    );
  }

  Future<void> _contactSupport(AppLocalizations l10n) async {
    final uri = Uri(
      scheme: 'mailto',
      path: LegalLinks.supportEmail,
      query: 'subject=${Uri.encodeComponent(l10n.contactSupportEmailSubject)}',
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _SectionLabel(l10n.displaySectionTitle),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                Consumer<SettingsStore>(
                  builder: (context, settings, _) {
                    return _SettingsTile(
                      icon: settings.darkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: _SettingsColors.amber,
                      title: l10n.darkModeTitle,
                      subtitle: l10n.darkModeSubtitle,
                      trailing: Switch(
                        value: settings.darkMode,
                        onChanged: (value) =>
                            context.read<SettingsStore>().setDarkMode(value),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionLabel(l10n.integrationsSettingsTitle),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                Consumer<CalendarStore>(
                  builder: (context, calendarStore, _) {
                    final name = calendarStore.selectedCalendarName;
                    return _SettingsTile(
                      icon: Icons.event_rounded,
                      color: _SettingsColors.indigo,
                      title: l10n.integrationsCalendarRowTitle,
                      subtitle: calendarStore.selectedCalendarId == null
                          ? l10n.integrationsOff
                          : (name ?? l10n.integrationsOff),
                      trailing: const _ChevronIcon(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const IntegrationSelectScreen(),
                        ),
                      ),
                    );
                  },
                ),
                if (Platform.isIOS)
                  Consumer<AppleRemindersStore>(
                    builder: (context, remindersStore, _) {
                      final name = remindersStore.selectedListName;
                      return _SettingsTile(
                        icon: Icons.checklist_rounded,
                        color: _SettingsColors.green,
                        title: l10n.appleRemindersSettingsTitle,
                        subtitle: remindersStore.selectedListId == null
                            ? l10n.integrationsOff
                            : (name ?? l10n.integrationsOff),
                        trailing: const _ChevronIcon(),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppleRemindersSelectScreen(),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<SubscriptionStore>(
              builder: (context, subscription, _) {
                return _HighlightCard(
                  color: _SettingsColors.amber,
                  child: _SettingsTile(
                    icon: Icons.workspace_premium_rounded,
                    color: _SettingsColors.amber,
                    title: l10n.weeklyReportSettingsTitle,
                    subtitle: l10n.weeklyReportSettingsSubtitle,
                    badge: subscription.isPro
                        ? null
                        : _Pill(
                            text: l10n.settingsProBadge,
                            color: _SettingsColors.amber,
                          ),
                    trailing: subscription.isPro
                        ? const _ChevronIcon()
                        : Icon(
                            Icons.lock_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WeeklyReportScreen(),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionLabel(l10n.planSectionTitle),
            const SizedBox(height: 10),
            Consumer<SubscriptionStore>(
              builder: (context, subscription, _) {
                return _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.star_rounded,
                      color: _SettingsColors.rose,
                      title: l10n.planCurrentTitle,
                      badge: _Pill(
                        text: subscription.isPro
                            ? l10n.planProTitle
                            : l10n.planFreeTitle,
                        color: _SettingsColors.rose,
                      ),
                      subtitle: subscription.isPro
                          ? l10n.planProSubtitle
                          : l10n.planFreeSubtitle,
                      trailing: subscription.isPro
                          ? TextButton(
                              onPressed: _openManageSubscription,
                              child: Text(l10n.planManage),
                            )
                          : null,
                    ),
                    if (!subscription.isPro)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: _UpgradeButton(
                          label: l10n.planUpgrade,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PaywallScreen(),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionLabel(l10n.accountSectionTitle),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                Consumer<AccountStore>(
                  builder: (context, account, _) {
                    return _SettingsTile(
                      icon: account.isSignedIn
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      color: _SettingsColors.blue,
                      title: account.isSignedIn
                          ? l10n.accountSignedInAs(account.displayLabel)
                          : l10n.accountNotSignedIn,
                      subtitle: account.isSignedIn
                          ? null
                          : l10n.accountNotSignedInDescription,
                      trailing: const _ChevronIcon(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AccountScreen()),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionLabel(l10n.notificationSectionTitle),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                FutureBuilder<bool>(
                  future: _notificationFuture,
                  builder: (context, snapshot) {
                    final granted = snapshot.data ?? false;
                    final loading =
                        snapshot.connectionState == ConnectionState.waiting;
                    return _SettingsTile(
                      icon: granted
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      color: _SettingsColors.amber,
                      title: l10n.reminderNotificationsTitle,
                      subtitle: loading
                          ? l10n.notificationCheckingStatus
                          : granted
                          ? l10n.notificationGranted
                          : l10n.notificationDenied,
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
            const SizedBox(height: 24),
            _SectionLabel(l10n.supportSectionTitle),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.description_rounded,
                  color: _SettingsColors.blue,
                  title: l10n.paywallTerms,
                  trailing: const _ChevronIcon(),
                  onTap: () => _openUrl(LegalLinks.termsOfServiceUrl),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  color: _SettingsColors.green,
                  title: l10n.paywallPrivacy,
                  trailing: const _ChevronIcon(),
                  onTap: () => _openUrl(LegalLinks.privacyPolicyUrl),
                ),
                _SettingsTile(
                  icon: Icons.mail_rounded,
                  color: _SettingsColors.indigo,
                  title: l10n.contactSupportTitle,
                  trailing: const _ChevronIcon(),
                  onTap: () => _contactSupport(l10n),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 設定画面の各カード内で使うアクセントカラー。indigoはアプリ全体のブランド
/// カラー（[kAppAccentColor]）そのもので、他の色は[_BenefitColors]
/// （paywall_screen.dart）と同系統にしてProプラン画面との統一感を持たせている。
class _SettingsColors {
  static const indigo = kAppAccentColor;
  static const green = Color(0xFF13A67D);
  static const blue = Color(0xFF3B82F6);
  static const amber = Color(0xFFE2952F);
  static const rose = Color(0xFFE84393);
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _SettingsColors.indigo,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// 設定項目をまとめる白背景の角丸カード。子要素の間に薄い区切り線を自動で入れる。
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 74,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// [WeeklyReportScreen]への導線をProの目玉機能として目立たせるための、
/// アクセントカラーのうっすらした縁取り＋グロー付きカード。
class _HighlightCard extends StatelessWidget {
  final Color color;
  final Widget child;

  const _HighlightCard({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ChevronIcon extends StatelessWidget {
  const _ChevronIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 設定カード1行分。アイコンチップ＋タイトル（＋任意のバッジ）＋説明文＋trailingの形。
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.badge,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          badge!,
                        ],
                      ],
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// プラン行の下に表示する、グラデーション付きの全幅アップグレードボタン。
class _UpgradeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _UpgradeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_SettingsColors.indigo, Color(0xFF8B5CF6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
