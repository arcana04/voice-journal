import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/watch_pairing_service.dart';
import '../state/account_store.dart';
import '../widgets/require_sign_in_sheet.dart';

/// アカウント画面から独立させたApple Watch連携専用画面。ペアリング実行ボタンと、
/// 未ログイン(匿名)ユーザー向けの案内を持つ（設定画面「連携」セクションの
/// カレンダー・リマインダーと同じ導線パターン）。
class WatchPairingScreen extends StatefulWidget {
  const WatchPairingScreen({super.key});

  @override
  State<WatchPairingScreen> createState() => _WatchPairingScreenState();
}

class _WatchPairingScreenState extends State<WatchPairingScreen> {
  final WatchPairingService _service = WatchPairingService();
  bool _busy = false;

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

  Future<void> _pairWatch() async {
    final l10n = AppLocalizations.of(context)!;

    // 匿名のままペアリングすると、再インストール等でアカウントがリセットされた際に
    // Watchとの連携がやり直しになる（BuyMinutesScreen/PaywallScreenの購入前
    // ログイン必須化と同じ理由）。ボタンを押した時点で未ログインならまずここで
    // サインインを促す。
    if (!context.read<AccountStore>().isSignedIn) {
      final signedIn = await showRequireSignInSheet(
        context,
        title: l10n.watchSignInRequiredTitle,
        description: l10n.watchSignInRequiredDescription,
      );
      if (!mounted || !signedIn) return;
    }

    setState(() => _busy = true);
    try {
      final locale = Localizations.localeOf(context).languageCode;
      await _service.pairWatch(locale: locale);
      if (!mounted) return;
      await _showMessage(l10n.watchPairingSuccessTitle, l10n.watchPairingSuccessMessage);
    } on WatchPairingException catch (e) {
      if (!mounted) return;
      await _showMessage(l10n.accountErrorTitle, e.message);
    } catch (_) {
      if (!mounted) return;
      await _showMessage(l10n.accountErrorTitle, l10n.genericProcessingError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSignedIn = context.watch<AccountStore>().isSignedIn;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.watchScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.watchScreenDescription,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            if (!isSignedIn) ...[
              const SizedBox(height: 16),
              _SignInRequiredNotice(message: l10n.watchSignInRequiredNotice),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pairWatch,
              icon: const Icon(Icons.watch_outlined),
              label: Text(l10n.watchPairingButton),
            ),
            if (_busy) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignInRequiredNotice extends StatelessWidget {
  final String message;

  const _SignInRequiredNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
