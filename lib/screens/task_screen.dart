import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import '../widgets/app_background_image.dart';
import '../widgets/scrim_text.dart';
import '../widgets/task_entry_card.dart';
import 'task_edit_screen.dart';

enum _TaskFilter { all, today, thisWeek, withinMonth, completed }

extension on _TaskFilter {
  String labelFor(AppLocalizations l10n) => switch (this) {
    _TaskFilter.all => l10n.filterAll,
    _TaskFilter.today => l10n.filterToday,
    _TaskFilter.thisWeek => l10n.filterThisWeek,
    _TaskFilter.withinMonth => l10n.filterWithinMonth,
    _TaskFilter.completed => l10n.filterCompleted,
  };
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isThisWeek(DateTime date, DateTime now) {
  final startOfWeek = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));
  final target = DateTime(date.year, date.month, date.day);
  return !target.isBefore(startOfWeek) && !target.isAfter(endOfWeek);
}

bool _isWithinOneMonth(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final oneMonthLater = DateTime(now.year, now.month + 1, now.day);
  final target = DateTime(date.year, date.month, date.day);
  return !target.isBefore(today) && !target.isAfter(oneMonthLater);
}

List<TaskItem> _filterTasks(List<TaskItem> tasks, _TaskFilter filter) {
  final now = DateTime.now();
  switch (filter) {
    case _TaskFilter.all:
      return tasks.toList();
    case _TaskFilter.today:
      return tasks
          .where(
            (t) => !t.done && t.dueDate != null && _isSameDate(t.dueDate!, now),
          )
          .toList();
    case _TaskFilter.thisWeek:
      return tasks
          .where(
            (t) => !t.done && t.dueDate != null && _isThisWeek(t.dueDate!, now),
          )
          .toList();
    case _TaskFilter.withinMonth:
      return tasks
          .where(
            (t) =>
                !t.done &&
                t.dueDate != null &&
                _isWithinOneMonth(t.dueDate!, now),
          )
          .toList();
    case _TaskFilter.completed:
      return tasks.where((t) => t.done).toList();
  }
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  _TaskFilter _filter = _TaskFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalStore>().load();
    });
  }

  Widget _buildFilterRow(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in _TaskFilter.values) ...[
              _FilterChip(
                label: filter.labelFor(l10n),
                selected: _filter == filter,
                onTap: () => setState(() => _filter = filter),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: const AppBackgroundImage(),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterRow(theme),
                Expanded(
                  child: Consumer<JournalStore>(
                    builder: (context, store, _) {
                      if (store.loading && store.entries.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final taskEntries = store.entries
                          .where((e) => e.tasks.isNotEmpty)
                          .toList();

                      final visibleEntries =
                          <MapEntry<JournalEntry, List<TaskItem>>>[];
                      for (final entry in taskEntries) {
                        final visible = _filterTasks(entry.tasks, _filter);
                        if (visible.isNotEmpty) {
                          visibleEntries.add(MapEntry(entry, visible));
                        }
                      }

                      return taskEntries.isEmpty
                          ? Center(
                              child: ScrimText(
                                child: Text(
                                  AppLocalizations.of(context)!.tasksEmpty,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            )
                          : visibleEntries.isEmpty
                          ? Center(
                              child: ScrimText(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.tasksFilterEmpty,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: store.load,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
                                itemCount: visibleEntries.length,
                                itemBuilder: (context, index) {
                                  final entry = visibleEntries[index].key;
                                  final tasks = visibleEntries[index].value;
                                  return TaskEntryCard(
                                    entry: entry,
                                    visibleTasks: tasks,
                                    onToggleTask: (task) =>
                                        store.toggleTask(entry, task),
                                    onEdit: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TaskEditScreen(entryId: entry.id!),
                                      ),
                                    ),
                                    onDelete: () => store.deleteEntry(entry),
                                  );
                                },
                              ),
                            );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : theme.colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
