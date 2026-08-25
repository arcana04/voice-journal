import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/journal_entry.dart';
import '../utils/task_format.dart';

/// タスク画面用のカード。ある録音から生まれた「ToDo」だけを表示する。
class TaskEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final ValueChanged<TaskItem> onToggleTask;
  final VoidCallback onDelete;
  final void Function(TaskItem task, String title) onUpdateTaskTitle;
  final void Function(TaskItem task, DateTime? reminderAt) onUpdateTaskReminder;

  const TaskEntryCard({
    super.key,
    required this.entry,
    required this.onToggleTask,
    required this.onDelete,
    required this.onUpdateTaskTitle,
    required this.onUpdateTaskReminder,
  });

  Future<void> _pickReminderTime(BuildContext context, TaskItem task) async {
    final now = DateTime.now();
    final initial =
        task.reminderAt != null ? TimeOfDay.fromDateTime(task.reminderAt!) : TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    var target = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    onUpdateTaskReminder(task, target);
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
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
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
                            _EditableTaskTitle(
                              key: ValueKey(task.id),
                              task: task,
                              onCommit: (title) => onUpdateTaskTitle(task, title),
                            ),
                            const SizedBox(height: 2),
                            _buildTaskMeta(context, theme, task),
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

  Widget _buildTaskMeta(BuildContext context, ThemeData theme, TaskItem task) {
    final dueLabel = taskDueLabel(task);
    final reminderAt = task.reminderAt;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dueLabel != null) ...[
          Text(
            dueLabel,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(width: 8),
        ],
        if (reminderAt != null)
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _pickReminderTime(context, task),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_active_outlined,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 2),
                Text(
                  DateFormat('HH:mm').format(reminderAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  onTap: () => onUpdateTaskReminder(task, null),
                  child: Icon(Icons.close, size: 14, color: theme.colorScheme.primary),
                ),
              ],
            ),
          )
        else
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _pickReminderTime(context, task),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 2),
                Text(
                  'リマインダーを設定',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// タスクのタイトルを、フォーカスが外れたタイミングでコミットする編集可能テキスト。
class _EditableTaskTitle extends StatefulWidget {
  final TaskItem task;
  final ValueChanged<String> onCommit;

  const _EditableTaskTitle({super.key, required this.task, required this.onCommit});

  @override
  State<_EditableTaskTitle> createState() => _EditableTaskTitleState();
}

class _EditableTaskTitleState extends State<_EditableTaskTitle> {
  late final TextEditingController _controller = TextEditingController(text: widget.task.title);
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _controller.text = widget.task.title;
      return;
    }
    if (text != widget.task.title) {
      widget.onCommit(text);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: widget.task.done
          ? theme.textTheme.bodyMedium?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.outline,
            )
          : theme.textTheme.bodyMedium,
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
