import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../state/account_store.dart';
import '../state/journal_store.dart';
import '../state/subscription_store.dart';

/// 購入直前に匿名ユーザーへログインを促すボトムシート。ログイン成功で`true`を
/// 返して閉じ、シートを閉じた/キャンセルした場合は`false`を返す。
/// PaywallScreen・BuyMinutesScreenの購入直前チェックから呼ばれる — 匿名のまま
/// 課金すると、TestFlight等で端末が再インストールされ匿名uidがリセットされた際に
/// 購入を復元する手段が無くなるため、購入前にアカウントへ紐付けさせる。
Future<bool> showRequireSignInSheet(
  BuildContext context, {
  String? title,
  String? description,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RequireSignInSheet(title: title, description: description),
  );
  return result ?? false;
}

class _RequireSignInSheet extends StatefulWidget {
  final String? title;
  final String? description;

  const _RequireSignInSheet({this.title, this.description});

  @override
  State<_RequireSignInSheet> createState() => _RequireSignInSheetState();
}

class _RequireSignInSheetState extends State<_RequireSignInSheet> {
  bool _busy = false;

  Future<void> _signIn(
    Future<AuthCredential> Function() credentialProvider,
  ) async {
    setState(() => _busy = true);
    try {
      final accountStore = context.read<AccountStore>();
      final subscriptionStore = context.read<SubscriptionStore>();
      final journalStore = context.read<JournalStore>();
      final uid = await accountStore.signInWithCredential(credentialProvider);
      // サインインで別の既存アカウントに切り替わった場合、
      // AccountStore._guardAccountSwitchが端末ローカルのSQLiteを消して
      // いるが、メモリ上のJournalStore/RevenueCatの識別子はまだ古いuid
      // のまま——ここで揃えておかないと、あとで何かがfullSync等を呼んだ
      // 際に前のアカウントの内容が新アカウントのFirestoreへ誤って
      // 送信されてしまう（account_screen.dartの_afterAuthSuccessと
      // 同じ手順をここでも踏む）。
      await subscriptionStore.switchUser(uid);
      await journalStore.load();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on SignInCancelledException {
      // ユーザーがピッカー/認証をキャンセルしただけなので何もしない。
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.accountErrorUnknown)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accountStore = context.read<AccountStore>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Icon(
              Icons.lock_outline_rounded,
              size: 36,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              widget.title ?? l10n.paywallSignInRequiredTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.description ?? l10n.paywallSignInRequiredDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _signIn(accountStore.googleCredential),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: Text(l10n.accountSignInWithGoogle),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _signIn(accountStore.appleCredential),
                icon: const Icon(Icons.apple, size: 22),
                label: Text(l10n.accountSignInWithApple),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
