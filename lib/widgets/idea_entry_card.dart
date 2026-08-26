import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import 'edit_icon_button.dart';

/// アイデア画面用のカード。ある録音から生まれた「アイデア」だけを表示する（読み取り専用）。
/// タイトル・本文の変更は鉛筆アイコンから編集画面で行う。
class IdeaEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final List<NoteItem> ideas;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const IdeaEntryCard({
    super.key,
    required this.entry,
    required this.ideas,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final timeLabel =
        '${DateFormat.MMMd(locale).format(entry.createdAt)} ${DateFormat.Hm(locale).format(entry.createdAt)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    timeLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                EditIconButton(onPressed: onEdit),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            for (final idea in ideas)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((idea.title ?? '').isNotEmpty)
                      Text(
                        idea.title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(idea.content, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
