import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';

/// AIの解析を経ずに、手動で1件だけ日記を作成する画面。録音するまでもない
/// 一言を、無料枠を消費せずすぐに書き留められるようにする。
class ManualDiaryScreen extends StatefulWidget {
  const ManualDiaryScreen({super.key});

  @override
  State<ManualDiaryScreen> createState() => _ManualDiaryScreenState();
}

class _ManualDiaryScreenState extends State<ManualDiaryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.manualDiaryContentRequiredError)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final note = NoteItem(
        category: kNoteCategoryFeeling,
        title: title.isEmpty ? null : title,
        content: content,
      );
      final entry = JournalEntry(
        createdAt: DateTime.now(),
        summary: title.isEmpty ? content : title,
        tasks: const [],
        notes: [note],
      );
      await context.read<JournalStore>().addEntry(entry);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manualDiaryScreenTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.add),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            TextField(
              controller: _titleController,
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                labelText: l10n.manualDiaryTitleHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              autofocus: true,
              minLines: 6,
              maxLines: 16,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: l10n.manualDiaryContentHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
