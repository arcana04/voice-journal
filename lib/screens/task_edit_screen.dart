import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../models/task_schedule_draft.dart';
import '../state/journal_store.dart';
import '../widgets/task_schedule_editor.dart';

class _TaskDraft {
  final TaskItem task;
  final TextEditingController titleController;

  /// カレンダー同期用の開始・終了時間とプッシュ通知の発火時刻（完全に独立）。
  final TaskScheduleDraft schedule;

  _TaskDraft(this.task)
    : titleController = TextEditingController(text: task.title),
      schedule = TaskScheduleDraft(
        startAt: task.reminderAt,
        endAt: task.reminderEndAt,
        isAllDay: task.isAllDay,
        notifyAt: task.notifyAt,
      );

  void dispose() => titleController.dispose();
}

/// タスクの編集画面。タイトル、カレンダー同期用の開始・終了時間、プッシュ通知の
/// リマインダー時刻を変更できる。開始・終了時間とリマインダー時刻は完全に独立して
/// おり、一方を変更してももう一方（およびカレンダー予定/通知）には影響しない。
class TaskEditScreen extends StatefulWidget {
  final int entryId;

  const TaskEditScreen({super.key, required this.entryId});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  List<_TaskDraft>? _drafts;

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

  Future<void> _save(JournalStore store, JournalEntry entry) async {
    for (final d in _drafts ?? const <_TaskDraft>[]) {
      final title = d.titleController.text.trim();
      if (title.isNotEmpty && title != d.task.title) {
        await store.updateTaskTitle(entry, d.task, title);
      }
      final schedule = d.schedule;
      if (schedule.startAt != d.task.reminderAt ||
          schedule.endAt != d.task.reminderEndAt ||
          schedule.isAllDay != d.task.isAllDay) {
        await store.updateTaskSchedule(
          entry,
          d.task,
          startAt: schedule.startAt,
          endAt: schedule.endAt,
          isAllDay: schedule.isAllDay,
        );
      }
      if (schedule.notifyAt != d.task.notifyAt) {
        await store.updateTaskNotifyAt(entry, d.task, schedule.notifyAt);
      }
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
              hintText: l10n.taskContentHint,
            ),
          ),
          const SizedBox(height: 16),
          TaskScheduleEditor(
            draft: draft.schedule,
            onChanged: () => setState(() {}),
          ),
        ],
      ),
    );
  }
}
