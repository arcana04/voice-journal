import 'package:flutter/material.dart';

/// ローカルの写真・動画ファイルが読み込めない（削除された、iOSのコンテナID変更で
/// パスが無効になった等）場合のフォールバック表示。以前は`Image.file`に
/// `errorBuilder`が無く、ファイルが見つからないと素のデフォルトのエラー表示に
/// なるだけで、ユーザーには「なぜ写真が消えたのか」が一切伝わらなかった。
/// アプリ内の全ての`Image.file(File(ローカルパス))`はこれを`errorBuilder`に
/// 渡すこと。
Widget missingMediaPlaceholder(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
) {
  final theme = Theme.of(context);
  return ColoredBox(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: theme.colorScheme.outline,
      ),
    ),
  );
}
