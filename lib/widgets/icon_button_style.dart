import 'package:flutter/material.dart';

/// アプリ全体で使う「押した瞬間がわかりやすい」アイコンボタンの共通スタイル。
/// 背景画像の上に置かれても埋もれないよう、常時はっきりした不透明気味の背景を
/// 敷いてタップ対象だと分かるようにし、押している間はさらに濃い色に変わるので、
/// 画面遷移やメニュー表示が一瞬でも「押せた」実感が残る。
ButtonStyle pressableIconButtonStyle(BuildContext context) {
  final theme = Theme.of(context);
  return IconButton.styleFrom(
    backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.85),
    foregroundColor: theme.colorScheme.primary,
    highlightColor: theme.colorScheme.primary.withValues(alpha: 0.3),
    splashFactory: InkRipple.splashFactory,
    shadowColor: Colors.black.withValues(alpha: 0.2),
    elevation: 2,
  );
}
