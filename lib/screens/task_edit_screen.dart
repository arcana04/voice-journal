import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';

String _dateLabel(DateTime date, String locale) =>
    '${DateFormat.MMMd(locale).format(date)}(${DateFormat.E(locale).format(date)})';

class _TaskDraft {
  final TaskItem task;
  final TextEditingController titleController;
  DateTime? reminderAt;

  _TaskDraft(this.task)
      : titleController = TextEditingController(text: task.title),
        reminderAt = task.reminderAt;

  void dispose() => titleController.dispose();
}

/// タスクの編集画面。タイトルと、リマインダーの日付・時刻を変更できる。
class TaskEditScreen extends StatefulWidget {
  final int entryId;

  const TaskEditScreen({super.key, required this.entryId});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  List<_TaskDraft>? _drafts;

  JournalEntry? _findEntry(JournalStore store) {
    for (final e in store.entries) {
      if (e.id == widget.entryId) return e;
    }
    return null;
  }

  List<_TaskDraft> _ensureDrafts(JournalEntry entry) {
    return _drafts ??= entry.tasks.map((t) => _TaskDraft(t)).toList();
  }

  @override
  void dispose() {
    for (final d in _drafts ?? const <_TaskDraft>[]) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _pickReminderDate(_TaskDraft draft) async {
    final base = draft.reminderAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      draft.reminderAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        base.hour,
        base.minute,
      );
    });
  }

  Future<void> _pickReminderTime(_TaskDraft draft) async {
    final base = draft.reminderAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    setState(() {
      draft.reminderAt = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _addReminder(_TaskDraft draft) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() {
      draft.reminderAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _clearReminder(_TaskDraft draft) {
    setState(() => draft.reminderAt = null);
  }

  Future<void> _save(JournalStore store, JournalEntry entry) async {
    for (final d in _drafts ?? const <_TaskDraft>[]) {
      final title = d.titleController.text.trim();
      if (title.isNotEmpty && title != d.task.title) {
        await store.updateTaskTitle(entry, d.task, title);
      }
      if (d.reminderAt != d.task.reminderAt) {
        await store.updateTaskReminder(entry, d.task, d.reminderAt);
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalStore>(
      builder: (context, store, _) {
        final entry = _findEntry(store);
        if (entry == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final drafts = _ensureDrafts(entry);

        return Scaffold(
          appBar: AppBar(
            actions: [
              TextButton(
                onPressed: () => _save(store, entry),
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [for (final d in drafts) _buildTaskBlock(context, d)],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskBlock(BuildContext context, _TaskDraft draft) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final reminderAt = draft.reminderAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
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
              hintText: l10n.taskContentHint,
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.reminderLabel, style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              )),
          const SizedBox(height: 6),
          if (reminderAt != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickReminderDate(draft),
                  icon: const Icon(Icons.event_outlined, size: 16),
                  label: Text(_dateLabel(reminderAt, locale)),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickReminderTime(draft),
                  icon: const Icon(Icons.schedule_outlined, size: 16),
                  label: Text(DateFormat('HH:mm').format(reminderAt)),
                ),
                IconButton(
                  onPressed: () => _clearReminder(draft),
                  icon: const Icon(Icons.close),
                  tooltip: l10n.removeReminderTooltip,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: () => _addReminder(draft),
              icon: const Icon(Icons.add_alarm_outlined, size: 16),
              label: Text(l10n.addReminder),
            ),
        ],
      ),
    );
  }
}
