import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/journal_entry.dart';
import '../utils/task_format.dart';

enum DraftItemType { diary, task }

/// 録音直後のAI仕分け結果を、ユーザーが保存前に確認・修正するための下書き。
class DraftItem {
  DraftItem({
    required this.id,
    required this.type,
    required this.text,
    this.dueHint,
    this.dueDate,
    this.reminderAt,
    this.noteCategory = kNoteCategoryIdea,
    this.noteTitle,
  });

  final String id;
  DraftItemType type;
  String text;
  final String? dueHint;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final String noteCategory;
  final String? noteTitle;
}

/// 録音結果を「日記」「タスク」の2カテゴリに分けて表示し、テキスト修正と
/// ドラッグ＆ドロップによるカテゴリの入れ替えができるレビューUI。
class EntryReview extends StatefulWidget {
  final String summary;
  final List<DraftItem> initialItems;
  final void Function(List<TaskItem> tasks, List<NoteItem> notes) onSave;
  final VoidCallback onDiscard;

  const EntryReview({
    super.key,
    required this.summary,
    required this.initialItems,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  State<EntryReview> createState() => _EntryReviewState();
}

class _EntryReviewState extends State<EntryReview> {
  late final List<DraftItem> _items = List.of(widget.initialItems);

  void _moveTo(DraftItem item, DraftItemType type) {
    if (item.type == type) return;
    setState(() => item.type = type);
  }

  void _removeItem(DraftItem item) {
    setState(() => _items.removeWhere((i) => i.id == item.id));
  }

  void _save() {
    final tasks = _items
        .where((i) => i.type == DraftItemType.task && i.text.trim().isNotEmpty)
        .map((i) => TaskItem(
              title: i.text.trim(),
              dueHint: i.dueHint,
              dueDate: i.dueDate,
              reminderAt: i.reminderAt,
            ))
        .toList();
    final notes = _items
        .where((i) => i.type == DraftItemType.diary && i.text.trim().isNotEmpty)
        .map((i) => NoteItem(
              category: i.noteCategory,
              title: i.noteTitle,
              content: i.text.trim(),
            ))
        .toList();
    widget.onSave(tasks, notes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diaryItems = _items.where((i) => i.type == DraftItemType.diary).toList();
    final taskItems = _items.where((i) => i.type == DraftItemType.task).toList();
    final hasContent = _items.any((i) => i.text.trim().isNotEmpty);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('内容を確認', style: theme.textTheme.titleMedium),
              if (widget.summary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.summary,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                '違っていればテキストを直せます。カードをドラッグすると日記⇄タスクを入れ替えられます',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              _buildSection(
                theme,
                type: DraftItemType.diary,
                title: '日記',
                icon: Icons.menu_book_outlined,
                items: diaryItems,
              ),
              const SizedBox(height: 16),
              _buildSection(
                theme,
                type: DraftItemType.task,
                title: 'タスク',
                icon: Icons.checklist_outlined,
                items: taskItems,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onDiscard,
                  child: const Text('破棄'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: hasContent ? _save : null,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required DraftItemType type,
    required String title,
    required IconData icon,
    required List<DraftItem> items,
  }) {
    return DragTarget<DraftItem>(
      onWillAcceptWithDetails: (details) => details.data.type != type,
      onAcceptWithDetails: (details) => _moveTo(details.data, type),
      builder: (context, candidateData, rejectedData) {
        final isHover = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isHover
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border.all(
              color: isHover ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              width: isHover ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(title, style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'ここにカードをドラッグ',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildCard(theme, item),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(ThemeData theme, DraftItem item) {
    final handle = Icon(Icons.drag_indicator, color: theme.colorScheme.outline);
    final cardShell = _CardShell(
      theme: theme,
      dragHandle: handle,
      item: item,
      onChanged: (value) => item.text = value,
      onRemove: () => _removeItem(item),
    );

    return LongPressDraggable<DraftItem>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 260,
          child: _CardShell(theme: theme, item: item, dragging: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: cardShell),
      child: cardShell,
    );
  }
}

class _CardShell extends StatelessWidget {
  final ThemeData theme;
  final DraftItem item;
  final Widget? dragHandle;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onRemove;
  final bool dragging;

  const _CardShell({
    required this.theme,
    required this.item,
    this.dragHandle,
    this.onChanged,
    this.onRemove,
    this.dragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final dueLabel = dueLabelFor(dueDate: item.dueDate, dueHint: item.dueHint);
    final reminderAt = item.reminderAt;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: dragging
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)]
            : null,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dragHandle != null) ...[
            Padding(padding: const EdgeInsets.only(top: 10), child: dragHandle),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dragging
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(item.text, style: theme.textTheme.bodyMedium),
                      )
                    : TextFormField(
                        initialValue: item.text,
                        minLines: 1,
                        maxLines: 3,
                        style: theme.textTheme.bodyMedium,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: onChanged,
                      ),
                if (dueLabel != null || reminderAt != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (dueLabel != null)
                          Text(
                            dueLabel,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline),
                          ),
                        if (dueLabel != null && reminderAt != null) const SizedBox(width: 8),
                        if (reminderAt != null) ...[
                          Icon(Icons.notifications_active_outlined,
                              size: 13, color: theme.colorScheme.primary),
                          const SizedBox(width: 2),
                          Text(
                            DateFormat('HH:mm').format(reminderAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
