import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';
import '../utils/media_type.dart';

/// 日記画面の一覧に出す、タップで詳細画面を開くための読み取り専用プレビューカード。
class DiaryEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;

  const DiaryEntryCard({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final day = DateFormat('d', locale).format(entry.createdAt);
    final monthLabel = DateFormat.MMM(locale).format(entry.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      day,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        monthLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: 48,
                  height: 3,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                for (final note in entry.notes.where(
                  (n) => n.category == kNoteCategoryFeeling,
                ))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((note.title ?? '').isNotEmpty)
                          Text(
                            note.title!,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (entry.imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildMediaPreview(theme),
                ],
              ],
            ),
            if (entry.emotion != null)
              Positioned(
                top: -14,
                right: -14,
                child: _EmotionBadge(
                  emotion: entry.emotion!,
                  label: entry.emotion!.labelFor(AppLocalizations.of(context)!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(ThemeData theme) {
    const maxShown = 4;
    final shown = entry.imagePaths.take(maxShown).toList();
    final remaining = entry.imagePaths.length - shown.length;
    const thumbSize = 68.0;

    return SizedBox(
      height: thumbSize,
      child: Row(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: thumbSize,
                height: thumbSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    isVideoPath(shown[i])
                        ? const ColoredBox(
                            color: Colors.black87,
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 26,
                            ),
                          )
                        : Image.file(File(shown[i]), fit: BoxFit.cover),
                    if (i == shown.length - 1 && remaining > 0)
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: Text(
                          '+$remaining',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 感情タグを表す絵文字バッジ。カードの角に載せるステッカー風のUI。
class _EmotionBadge extends StatelessWidget {
  final EmotionTag emotion;
  final String label;

  const _EmotionBadge({required this.emotion, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(emotion.emoji, style: const TextStyle(fontSize: 34)),
      ),
    );
  }
}
