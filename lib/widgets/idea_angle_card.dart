import 'package:flutter/material.dart';

import '../models/idea_brainstorm.dart';

/// 「アイデアを深掘り」機能がAIから返す1つの切り口を表示するカード。
/// 相談タブのチャット内で、通常のテキスト吹き出しの代わりに3枚並べて使う。
class IdeaAngleCard extends StatelessWidget {
  final IdeaAngle angle;

  const IdeaAngleCard({super.key, required this.angle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  angle.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (angle.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(angle.description, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
