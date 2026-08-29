import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// 背景イラストのグリッド選択で使うタイル。画像を見て選ぶ形式にするため、
/// 見出しテキストは表示しない（読み上げ用のラベルとしてのみ[label]を使う）。
class DiaryBackgroundTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const DiaryBackgroundTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: selected ? 2 : 1,
                ),
              ),
              child: child,
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 背景グリッドの末尾に置く「自分の画像を追加」タイル（Pro限定機能）。
/// [isPro]がfalseなら鍵アイコンを重ねて非Pro向けであることを示す。
class AddCustomBackgroundTile extends StatelessWidget {
  final bool isPro;
  final VoidCallback onTap;

  const AddCustomBackgroundTile({
    super.key,
    required this.isPro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.addCustomBackgroundTile,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              style: BorderStyle.solid,
            ),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
          ),
          alignment: Alignment.center,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                    if (!isPro) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Pro',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isPro)
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      Icons.lock,
                      size: 13,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
