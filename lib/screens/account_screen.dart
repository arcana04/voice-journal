import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/watch_pairing_service.dart';
import '../state/account_store.dart';
import '../state/journal_store.dart';
import '../state/subscription_store.dart';

/// Google/Appleサインイン・アカウント管理画面。
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _busy = false;

  String _messageFor(AppLocalizations l10n, AccountErrorReason reason) {
    return switch (reason) {
      AccountErrorReason.networkError => l10n.accountErrorNetwork,
      AccountErrorReason.unknown => l10n.accountErrorUnknown,
    };
  }

  Future<void> _showMessage(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showError(Object error) async {
    final l10n = AppLocalizations.of(context)!;
    final message = error is AccountException
        ? _messageFor(l10n, error.reason)
        : l10n.accountErrorUnknown;
    if (!mounted) return;
    await _showMessage(l10n.accountErrorTitle, message);
  }

  Future<void> _afterAuthSuccess(String uid) async {
    if (!mounted) return;
    await context.read<SubscriptionStore>().switchUser(uid);
    if (!mounted) return;
    final canSyncMedia = context.read<SubscriptionStore>().isProWithMediaSync;
    await context.read<JournalStore>().fullSync(canSyncMedia: canSyncMedia);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await _showMessage(l10n.accountSyncCompleteTitle, l10n.accountSyncCompleteMessage);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    try {
      final accountStore = context.read<AccountStore>();
      final credential = await accountStore.googleCredential();
      final uid = await accountStore.signInWithCredential(credential);
      await _afterAuthSuccess(uid);
    } on SignInCancelledException {
      // ユーザーがピッカーを閉じただけなのでエラー表示はしない。
    } catch (e) {
      await _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _busy = true);
    try {
      final accountStore = context.read<AccountStore>();
      final credential = await accountStore.appleCredential();
      final uid = await accountStore.signInWithCredential(credential);
      await _afterAuthSuccess(uid);
    } on SignInCancelledException {
      // ユーザーが認証をキャンセルしただけなのでエラー表示はしない。
    } catch (e) {
      await _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountSignOutConfirmTitle),
        content: Text(l10n.accountSignOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.accountSignOutButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final uid = await context.read<AccountStore>().signOut();
      if (!mounted) return;
      await context.read<SubscriptionStore>().switchUser(uid);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountDeleteConfirmTitle),
        content: Text(l10n.accountDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.accountDeleteConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final uid = await context.read<AccountStore>().deleteAccount();
      if (!mounted) return;
      await context.read<SubscriptionStore>().switchUser(uid);
      if (!mounted) return;
      await context.read<JournalStore>().load();
      if (!mounted) return;
      await _showMessage(l10n.accountDeleteCompleteTitle, l10n.accountDeleteCompleteMessage);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      await _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pairWatch() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final locale = Localizations.localeOf(context).languageCode;
      await WatchPairingService().pairWatch(locale: locale);
      if (!mounted) return;
      await _showMessage(l10n.watchPairingSuccessTitle, l10n.watchPairingSuccessMessage);
    } on WatchPairingException catch (e) {
      if (!mounted) return;
      await _showMessage(l10n.accountErrorTitle, e.message);
    } catch (e) {
      await _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fullSync() async {
    setState(() => _busy = true);
    try {
      final canSyncMedia = context.read<SubscriptionStore>().isProWithMediaSync;
      await context.read<JournalStore>().fullSync(canSyncMedia: canSyncMedia);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.accountSyncCompleteMessage)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accountStore = context.watch<AccountStore>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountScreenTitle)),
      body: SafeArea(
        child: accountStore.isSignedIn
            ? _buildSignedIn(l10n, accountStore)
            : _buildSignedOut(l10n),
      ),
    );
  }

  Widget _buildSignedIn(AppLocalizations l10n, AccountStore accountStore) {
    final theme = Theme.of(context);
    final canSyncMedia = context.watch<SubscriptionStore>().isProWithMediaSync;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(accountStore.displayLabel),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _fullSync,
          icon: const Icon(Icons.cloud_sync_outlined),
          label: Text(l10n.accountRestoreButton),
        ),
        const SizedBox(height: 12),
        _MediaSyncNotice(canSyncMedia: canSyncMedia, l10n: l10n),
        const SizedBox(height: 12),
        if (Platform.isIOS) ...[
          OutlinedButton.icon(
            onPressed: _busy ? null : _pairWatch,
            icon: const Icon(Icons.watch_outlined),
            label: Text(l10n.watchPairingButton),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          onPressed: _busy ? null : _signOut,
          child: Text(l10n.accountSignOutButton),
        ),
        if (_busy) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator()),
        ],
        const SizedBox(height: 24),
        Text(
          l10n.accountNotSignedInDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: TextButton(
            onPressed: _busy ? null : _deleteAccount,
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: Text(l10n.accountDeleteButton),
          ),
        ),
      ],
    );
  }

  Widget _buildSignedOut(AppLocalizations l10n) {
    final canSyncMedia = context.watch<SubscriptionStore>().isProWithMediaSync;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.accountNotSignedInDescription,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _MediaSyncNotice(canSyncMedia: canSyncMedia, l10n: l10n),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _signInWithGoogle,
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: Text(l10n.accountSignInWithGoogle),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (Platform.isIOS) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _signInWithApple,
              icon: const Icon(Icons.apple, size: 22),
              label: Text(l10n.accountSignInWithApple),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
        if (_busy) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

/// 写真・動画がクラウド同期の対象かどうか（サブスクプラン限定、買い切りは対象外）
/// を明示するための注記。
class _MediaSyncNotice extends StatelessWidget {
  final bool canSyncMedia;
  final AppLocalizations l10n;

  const _MediaSyncNotice({required this.canSyncMedia, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            canSyncMedia ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              canSyncMedia ? l10n.accountMediaSyncProNote : l10n.accountMediaSyncFreeNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
