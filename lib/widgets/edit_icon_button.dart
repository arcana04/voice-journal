import 'package:flutter/material.dart';

import 'icon_button_style.dart';

/// アプリ全体で共通の「編集（鉛筆）」ボタン。押した瞬間がわかりやすいスタイルにしている。
class EditIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;
  final String tooltip;

  const EditIconButton({
    super.key,
    required this.onPressed,
    this.size = 20,
    this.tooltip = '編集',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(Icons.edit_outlined, size: size),
      visualDensity: VisualDensity.compact,
      style: pressableIconButtonStyle(context),
    );
  }
}
