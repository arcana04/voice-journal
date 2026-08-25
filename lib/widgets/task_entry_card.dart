import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/journal_entry.dart';
import '../utils/task_format.dart';
import 'edit_icon_button.dart';

/// タスク画面用のカード。ある録音から生まれた「ToDo」だけを表示する（読み取り専用）。
/// タイトル・リマインダーの変更は鉛筆アイコンから編集画面で行う。
class TaskEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final ValueChanged<TaskItem> onToggleTask;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskEntryCard({
    super.key,
    required this.entry,
    required this.onToggleTask,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('この記録を削除すると元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }

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
                EditIconButton(onPressed: onEdit),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            ...entry.tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: task.done,
                      onChanged: (_) => onToggleTask(task),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: task.done
                                  ? theme.textTheme.bodyMedium?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: theme.colorScheme.outline,
                                    )
                                  : theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 2),
                            _buildTaskMeta(theme, task),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskMeta(ThemeData theme, TaskItem task) {
    final dueLabel = taskDueLabel(task);
    final reminderAt = task.reminderAt;

    if (dueLabel == null && reminderAt == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dueLabel != null)
          Text(
            dueLabel,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        if (dueLabel != null && reminderAt != null) const SizedBox(width: 8),
        if (reminderAt != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_active_outlined,
                  size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 2),
              Text(
                DateFormat('M月d日 HH:mm').format(reminderAt),
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
