import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';

class _IdeaDraft {
  final NoteItem note;
  final TextEditingController titleController;
  final TextEditingController contentController;

  _IdeaDraft(this.note)
    : titleController = TextEditingController(text: note.title ?? ''),
      contentController = TextEditingController(text: note.content);

  void dispose() {
    titleController.dispose();
    contentController.dispose();
  }
}

/// アイデア（notes category="アイデア"）の編集画面。見出しと本文を変更できる。
class IdeaEditScreen extends StatefulWidget {
  final int entryId;

  const IdeaEditScreen({super.key, required this.entryId});

  @override
  State<IdeaEditScreen> createState() => _IdeaEditScreenState();
}

class _IdeaEditScreenState extends State<IdeaEditScreen> {
  List<_IdeaDraft>? _drafts;

  List<_IdeaDraft> _ensureDrafts(JournalEntry entry) {
    return _drafts ??= entry.notes
        .where((n) => n.category == kNoteCategoryIdea)
        .map((n) => _IdeaDraft(n))
        .toList();
  }

  @override
  void dispose() {
    for (final d in _drafts ?? const <_IdeaDraft>[]) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _save(JournalStore store, JournalEntry entry) async {
    for (final d in _drafts ?? const <_IdeaDraft>[]) {
      final title = d.titleController.text.trim();
      var content = d.contentController.text.trim();
      if (content.isEmpty) content = d.note.content;
      await store.updateNoteText(
        entry,
        d.note,
        title: title.isEmpty ? null : title,
        content: content,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalStore>(
      builder: (context, store, _) {
        final entry = store.findById(widget.entryId);
        if (entry == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final drafts = _ensureDrafts(entry);

        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.editIdeaTitle),
            actions: [
              TextButton(
                onPressed: () => _save(store, entry),
                child: Text(l10n.save),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [for (final d in drafts) _buildIdeaBlock(context, d)],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdeaBlock(BuildContext context, _IdeaDraft draft) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: draft.titleController,
            style: theme.textTheme.titleMedium,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: l10n.ideaTitleHint,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.contentController,
            minLines: 2,
            maxLines: 8,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: l10n.ideaContentHint,
            ),
          ),
        ],
      ),
    );
  }
}
