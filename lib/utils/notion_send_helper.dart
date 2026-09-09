import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../screens/notion_connect_screen.dart';
import '../screens/paywall_screen.dart';
import '../services/backend_service.dart';
import '../state/notion_store.dart';
import '../state/subscription_store.dart';

/// タスク/日記/アイデアの編集画面で共通の「Notionへ送る」ボタンの分岐ロジック。
/// 送信済み([existingPageUrl]がある)ならNotionページを開くだけ、そうでなければ
/// 非Pro(クリップボードコピー+アップグレード導線)/未接続(接続画面へ誘導)/
/// 送信(成功・失敗をSnackBarで表示)のいずれかに分岐する。
Future<void> handleNotionSendTap(
  BuildContext context, {
  required String? existingPageUrl,
  required String plainTextForClipboard,
  required Future<String> Function() doSend,
  required void Function(bool sending) onSendingChanged,
}) async {
  if (existingPageUrl != null) {
    await launchUrl(Uri.parse(existingPageUrl), mode: LaunchMode.externalApplication);
    return;
  }

  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final isPro = context.read<SubscriptionStore>().isPro;

  if (!isPro) {
    await Clipboard.setData(ClipboardData(text: plainTextForClipboard));
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.notionCopiedFreeMessage),
        action: SnackBarAction(
          label: l10n.planUpgrade,
          onPressed: () => navigator.push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          ),
        ),
      ),
    );
    return;
  }

  final isConnected = context.read<NotionStore>().isConnected;
  if (!isConnected) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.notionNotConnectedMessage),
        action: SnackBarAction(
          label: l10n.notionConnectAction,
          onPressed: () => navigator.push(
            MaterialPageRoute(builder: (_) => const NotionConnectScreen()),
          ),
        ),
      ),
    );
    return;
  }

  onSendingChanged(true);
  try {
    final pageUrl = await doSend();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.notionSendSuccessMessage),
        action: SnackBarAction(
          label: l10n.notionOpenAction,
          onPressed: () =>
              launchUrl(Uri.parse(pageUrl), mode: LaunchMode.externalApplication),
        ),
      ),
    );
  } on BackendServiceException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } finally {
    onSendingChanged(false);
  }
}
