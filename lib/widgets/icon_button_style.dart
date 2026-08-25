import 'package:flutter/material.dart';

/// アプリ全体で使う「押した瞬間がわかりやすい」アイコンボタンの共通スタイル。
/// 常時薄い色の背景を敷いてタップ対象だと分かるようにし、押している間ははっきり
/// 濃い色に変わるので、画面遷移やメニュー表示が一瞬でも「押せた」実感が残る。
ButtonStyle pressableIconButtonStyle(BuildContext context) {
  final primary = Theme.of(context).colorScheme.primary;
  return IconButton.styleFrom(
    backgroundColor: primary.withValues(alpha: 0.1),
    foregroundColor: primary,
    highlightColor: primary.withValues(alpha: 0.3),
    splashFactory: InkRipple.splashFactory,
  );
}
