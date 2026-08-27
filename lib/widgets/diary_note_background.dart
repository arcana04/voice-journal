import 'package:flutter/material.dart';

import '../models/diary_background.dart';

/// [backgroundId]に対応する[DiaryBackground]が設定されていれば、そのイラストを
/// 敷いた上に[child]を薄めのスクリムで読みやすく重ねる。未設定（null）ならchildを
/// そのまま返す。イラストを選んだ意味が無くならないよう、[ScrimText]（アプリ全体の
/// 背景画像用、alpha 0.85）より薄い alpha にしている。
class DiaryNoteBackground extends StatelessWidget {
  final String? backgroundId;
  final Widget child;

  const DiaryNoteBackground({
    super.key,
    required this.backgroundId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final background = DiaryBackground.fromId(backgroundId);
    if (background == null) return child;

    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              background.asset,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: theme.colorScheme.surface.withValues(alpha: 0.45),
            child: child,
          ),
        ],
      ),
    );
  }
}
