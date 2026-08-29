import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import '../state/subscription_store.dart';
import '../state/text_style_store.dart';
import '../utils/note_text_style.dart';
import '../widgets/diary_screen_background.dart';
import '../widgets/edit_icon_button.dart';
import '../widgets/media_gallery.dart';
import '../widgets/scrim_text.dart';
import 'diary_edit_screen.dart';

/// 日記の閲覧画面（読み取り専用）。右上の鉛筆から編集画面へ横スワイプで遷移する。
class DiaryViewScreen extends StatelessWidget {
  final int entryId;

  const DiaryViewScreen({super.key, required this.entryId});

  Future<void> _confirmDelete(
    BuildContext context,
    JournalStore store,
    JournalEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final canSyncMedia = context.read<SubscriptionStore>().isProWithMediaSync;
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
    // このentryにアイデア・タスクの内容も混ざっている場合はそれらを残し、
    // 日記（感情ログ）のnoteと写真・動画（日記編集画面からしか付けられない
    // ため日記側の付属物として扱う）だけを削除する。
    final feelingNotes = entry.notes
        .where((n) => n.category == kNoteCategoryFeeling)
        .toList();
    await store.deleteNotesFromEntry(
      entry,
      feelingNotes,
      alsoDeleteImages: true,
      canSyncMedia: canSyncMedia,
    );
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalStore>(
      builder: (context, store, _) {
        final entry = store.findById(entryId);
        if (entry == null) {
          // 編集画面から削除された場合など。
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final theme = Theme.of(context);
        final textStyleDefaults = context.watch<TextStyleStore>();
        final locale = Localizations.localeOf(context).toString();
        final day = DateFormat('d', locale).format(entry.createdAt);
        final monthYearLabel = DateFormat.yMMMM(locale).format(entry.createdAt);
        final feelingNotes = entry.notes
            .where((n) => n.category == kNoteCategoryFeeling)
            .toList();
        final entryBackgroundId =
            (feelingNotes.isNotEmpty ? feelingNotes.first.backgroundId : null) ??
            textStyleDefaults.backgroundId;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
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
          body: Stack(
            children: [
              Positioned.fill(
                child: DiaryScreenBackground(backgroundId: entryBackgroundId),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ScrimText(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    day,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
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
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                  if (entry.emotion != null) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      entry.emotion!.emoji,
                                      style: const TextStyle(fontSize: 40),
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final note in feelingNotes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((note.title ?? '').isNotEmpty)
                                  Text(
                                    note.title!,
                                    style: applyNoteStyle(
                                      theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      note: note,
                                      defaults: textStyleDefaults,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  note.content,
                                  style: applyNoteStyle(
                                    theme.textTheme.bodyLarge,
                                    note: note,
                                    defaults: textStyleDefaults,
                                  ),
                                ),
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
              ),
            ],
          ),
        );
      },
    );
  }
}
