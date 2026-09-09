import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'icon_button_style.dart';

/// 「Notionへ送る」アイコンボタン。送信中はスピナー、送信済み(該当アイテムに
/// [notionPageUrl]がある状態)はチェックアイコンになり、押すたびの分岐
/// (非Pro/未接続/送信/再送不要で開くだけ)は呼び出し元(編集画面)が持つ。
class NotionSendIconButton extends StatelessWidget {
  final bool sending;
  final bool sent;
  final VoidCallback onPressed;
  final double size;

  const NotionSendIconButton({
    super.key,
    required this.sending,
    required this.sent,
    required this.onPressed,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (sending) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      onPressed: onPressed,
      tooltip: sent ? l10n.notionAlreadySentTooltip : l10n.notionSendTooltip,
      icon: Icon(
        sent ? Icons.check_circle_outline : Icons.send_outlined,
        size: size,
      ),
      visualDensity: VisualDensity.compact,
      style: pressableIconButtonStyle(context),
    );
  }
}
