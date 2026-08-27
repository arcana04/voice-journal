import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
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

  /// 表示するタスクの絞り込み結果。未指定なら[entry.tasks]をそのまま表示する
  /// （タスク画面の絞り込みボタンで、該当するタスクだけをカード内に表示するため）。
  final List<TaskItem>? visibleTasks;

  const TaskEntryCard({
    super.key,
    required this.entry,
    required this.onToggleTask,
    required this.onEdit,
    required this.onDelete,
    this.visibleTasks,
  });

  Future<void> _confirmDelete(BuildContext context) async {
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
    if (confirmed == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final timeLabel =
        '${DateFormat.MMMd(locale).format(entry.createdAt)} ${DateFormat.Hm(locale).format(entry.createdAt)}';
    final tasks = visibleTasks ?? entry.tasks;

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
            ...tasks.map(
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
                            _buildTaskMeta(theme, task, locale, l10n),
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

  /// カレンダーに同期される「開始・終了時間」の表示ラベル。
  String _scheduleLabel(TaskItem task, String locale, AppLocalizations l10n) {
    final start = task.reminderAt!;
    final startDate = DateFormat.MMMd(locale).format(start);
    if (task.isAllDay) return '$startDate (${l10n.allDayLabel})';

    final end = task.reminderEndAt;
    final startTime = DateFormat.Hm(locale).format(start);
    if (end == null) return '$startDate $startTime';

    final sameDay =
        start.year == end.year && start.month == end.month && start.day == end.day;
    final endTime = DateFormat.Hm(locale).format(end);
    if (sameDay) return '$startDate $startTime-$endTime';

    final endDate = DateFormat.MMMd(locale).format(end);
    return '$startDate $startTime → $endDate $endTime';
  }

  /// プッシュ通知が発火する時刻の表示ラベル（開始・終了時間とは独立）。
  String _notifyLabel(TaskItem task, String locale) {
    final at = task.notifyAt!;
    return '${DateFormat.MMMd(locale).format(at)} ${DateFormat.Hm(locale).format(at)}';
  }

  Widget _buildTaskMeta(
    ThemeData theme,
    TaskItem task,
    String locale,
    AppLocalizations l10n,
  ) {
    final dueLabel = taskDueLabel(task, locale: locale);
    final reminderAt = task.reminderAt;
    final notifyAt = task.notifyAt;

    if (dueLabel == null && reminderAt == null && notifyAt == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (dueLabel != null)
          Text(
            dueLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        // 開始・終了時間（カレンダー同期）
        if (reminderAt != null)
          _MetaChip(
            icon: Icons.event_outlined,
            label: _scheduleLabel(task, locale, l10n),
            color: theme.colorScheme.primary,
          ),
        // 通知の発火時刻（開始・終了時間とは独立）
        if (notifyAt != null)
          _MetaChip(
            icon: Icons.notifications_active_outlined,
            label: _notifyLabel(task, locale),
            color: theme.colorScheme.tertiary,
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
