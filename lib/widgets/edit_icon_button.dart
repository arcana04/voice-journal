import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'icon_button_style.dart';

/// アプリ全体で共通の「編集（鉛筆）」ボタン。押した瞬間がわかりやすいスタイルにしている。
class EditIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;
  final String? tooltip;

  const EditIconButton({
    super.key,
    required this.onPressed,
    this.size = 20,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip ?? AppLocalizations.of(context)!.editTooltip,
      icon: Icon(Icons.edit_outlined, size: size),
      visualDensity: VisualDensity.compact,
      style: pressableIconButtonStyle(context),
    );
  }
}
