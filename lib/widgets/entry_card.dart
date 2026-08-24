import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/journal_entry.dart';

class EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final ValueChanged<TaskItem> onToggleTask;
  final VoidCallback onDelete;

  const EntryCard({
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
            ],
            if (entry.tasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('ToDo', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
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
                  subtitle: _dueLabel(task) != null ? Text(_dueLabel(task)!) : null,
                ),
              ),
            ],
            ..._buildNoteSection(
              theme,
              title: 'アイデア',
              notes: entry.notes.where((n) => n.category == kNoteCategoryIdea).toList(),
            ),
            ..._buildNoteSection(
              theme,
              title: '感情ログ',
              notes: entry.notes.where((n) => n.category == kNoteCategoryFeeling).toList(),
            ),
            if (entry.comfortMessage != null && entry.comfortMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.favorite_border, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.comfortMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _weekdayKanji = ['月', '火', '水', '木', '金', '土', '日'];

  String? _dueLabel(TaskItem task) {
    final dueDate = task.dueDate;
    if (dueDate != null) {
      final weekday = _weekdayKanji[dueDate.weekday - 1];
      return '${DateFormat('M月d日').format(dueDate)}($weekday)';
    }
    if (task.dueHint != null && task.dueHint!.isNotEmpty) {
      return task.dueHint;
    }
    return null;
  }

  List<Widget> _buildNoteSection(
    ThemeData theme, {
    required String title,
    required List<NoteItem> notes,
  }) {
    if (notes.isEmpty) return const [];
    return [
      const SizedBox(height: 8),
      Text(title, style: theme.textTheme.labelLarge),
      const SizedBox(height: 4),
      ...notes.map(
        (note) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(note.content, style: theme.textTheme.bodyMedium),
        ),
      ),
    ];
  }
}
