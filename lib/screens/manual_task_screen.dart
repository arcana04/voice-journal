import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../models/task_schedule_draft.dart';
import '../state/journal_store.dart';
import '../widgets/task_schedule_editor.dart';

/// AIの解析を経ずに、手動で1件だけタスクを作成する画面。買い物や単純な用事など、
/// 録音・AI解析するまでもない内容を無料枠を消費せずすぐに登録できるようにする。
class ManualTaskScreen extends StatefulWidget {
  const ManualTaskScreen({super.key});

  @override
  State<ManualTaskScreen> createState() => _ManualTaskScreenState();
}

class _ManualTaskScreenState extends State<ManualTaskScreen> {
  final _titleController = TextEditingController();
  final _schedule = TaskScheduleDraft();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.manualTaskTitleRequiredError)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final startAt = _schedule.startAt;
      final task = TaskItem(
        title: title,
        dueDate: startAt != null
            ? DateTime(startAt.year, startAt.month, startAt.day)
            : null,
        reminderAt: startAt,
        reminderEndAt: _schedule.endAt,
        isAllDay: _schedule.isAllDay,
        notifyAt: _schedule.notifyAt,
      );
      final entry = JournalEntry(
        createdAt: DateTime.now(),
        summary: title,
        tasks: [task],
        notes: const [],
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
        title: Text(l10n.manualTaskScreenTitle),
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
              autofocus: true,
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                labelText: l10n.manualTaskTitleHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TaskScheduleEditor(
              draft: _schedule,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}
