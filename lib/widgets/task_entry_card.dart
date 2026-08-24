import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/journal_entry.dart';
import '../utils/task_format.dart';

/// タスク画面用のカード。ある録音から生まれた「ToDo」だけを表示する。
class TaskEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final ValueChanged<TaskItem> onToggleTask;
  final VoidCallback onDelete;

  const TaskEntryCard({
    super.key,
    required this.entry,
    required this.onToggleTask,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = DateFormat('M月d日 HH:mm').format(entry.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    timeLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (entry.summary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(entry.summary, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
            ],
            ...entry.tasks.map(
              (task) => CheckboxListTile(
                value: task.done,
                onChanged: (_) => onToggleTask(task),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  task.title,
                  style: task.done
                      ? theme.textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: theme.colorScheme.outline,
                        )
                      : theme.textTheme.bodyMedium,
                ),
                subtitle: _buildTaskSubtitle(theme, task),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildTaskSubtitle(ThemeData theme, TaskItem task) {
    final dueLabel = taskDueLabel(task);
    final reminderAt = task.reminderAt;

    if (dueLabel == null && reminderAt == null) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dueLabel != null) Text(dueLabel),
        if (dueLabel != null && reminderAt != null) const SizedBox(width: 8),
        if (reminderAt != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 2),
              Text(
                DateFormat('HH:mm').format(reminderAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
