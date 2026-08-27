import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/account_store.dart';
import '../state/journal_store.dart';
import '../state/subscription_store.dart';

enum _AuthMode { signUp, signIn }

/// メールアカウントのサインアップ/サインイン/管理画面。
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  _AuthMode _mode = _AuthMode.signUp;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _messageFor(AppLocalizations l10n, AccountErrorReason reason) {
    return switch (reason) {
      AccountErrorReason.emailAlreadyInUse => l10n.accountErrorEmailAlreadyInUse,
      AccountErrorReason.invalidEmail => l10n.accountErrorInvalidEmail,
      AccountErrorReason.weakPassword => l10n.accountErrorWeakPassword,
      AccountErrorReason.invalidCredential => l10n.accountErrorInvalidCredential,
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
    await context.read<JournalStore>().fullSync();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await _showMessage(l10n.accountSyncCompleteTitle, l10n.accountSyncCompleteMessage);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    setState(() => _busy = true);
    try {
      final accountStore = context.read<AccountStore>();
      final uid = _mode == _AuthMode.signUp
          ? await accountStore.signUp(email, password)
          : await accountStore.signIn(email, password);
      await _afterAuthSuccess(uid);
    } catch (e) {
      await _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _busy = true);
    try {
      await context.read<AccountStore>().sendPasswordReset(email);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      await _showMessage(
        l10n.accountPasswordResetSentTitle,
        l10n.accountPasswordResetSentMessage,
      );
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

  Future<void> _fullSync() async {
    setState(() => _busy = true);
    try {
      await context.read<JournalStore>().fullSync();
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(accountStore.email ?? ''),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _fullSync,
          icon: const Icon(Icons.cloud_sync_outlined),
          label: Text(l10n.accountRestoreButton),
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }

  Widget _buildSignedOut(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.accountNotSignedInDescription,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        SegmentedButton<_AuthMode>(
          segments: [
            ButtonSegment(
              value: _AuthMode.signUp,
              label: Text(l10n.accountSignUpTab),
            ),
            ButtonSegment(
              value: _AuthMode.signIn,
              label: Text(l10n.accountSignInTab),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (selection) =>
              setState(() => _mode = selection.first),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.accountEmailLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.accountPasswordLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(
              _mode == _AuthMode.signUp
                  ? l10n.accountSignUpButton
                  : l10n.accountSignInButton,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _busy ? null : _forgotPassword,
            child: Text(l10n.accountForgotPassword),
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}
