import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import '../widgets/edit_icon_button.dart';
import '../widgets/media_gallery.dart';
import 'diary_edit_screen.dart';

/// 日記の閲覧画面（読み取り専用）。右上の鉛筆から編集画面へ横スワイプで遷移する。
class DiaryViewScreen extends StatelessWidget {
  final int entryId;

  const DiaryViewScreen({super.key, required this.entryId});

  JournalEntry? _findEntry(JournalStore store) {
    for (final e in store.entries) {
      if (e.id == entryId) return e;
    }
    return null;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    JournalStore store,
    JournalEntry entry,
  ) async {
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
    if (confirmed != true) return;
    await store.deleteEntry(entry);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalStore>(
      builder: (context, store, _) {
        final entry = _findEntry(store);
        if (entry == null) {
          // 編集画面から削除された場合など。
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final theme = Theme.of(context);
        final locale = Localizations.localeOf(context).toString();
        final day = DateFormat('d', locale).format(entry.createdAt);
        final monthYearLabel = DateFormat.yMMMM(locale).format(entry.createdAt);

        return Scaffold(
          appBar: AppBar(
            actions: [
              EditIconButton(
                size: 24,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DiaryEditScreen(entryId: entryId),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, store, entry),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
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
                          monthYearLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (entry.emotion != null) ...[
                        const Spacer(),
                        Text(
                          entry.emotion!.emoji,
                          style: const TextStyle(fontSize: 28),
                          semanticsLabel: entry.emotion!.labelFor(
                            AppLocalizations.of(context)!,
                          ),
                        ),
                      ],
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
                  if (entry.comfortMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.comfortMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  for (final note in entry.notes.where(
                    (n) => n.category == kNoteCategoryFeeling,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((note.title ?? '').isNotEmpty)
                            Text(
                              note.title!,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(note.content, style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  if (entry.imagePaths.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    MediaGallery(paths: entry.imagePaths),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
