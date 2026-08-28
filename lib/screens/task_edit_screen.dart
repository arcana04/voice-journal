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

  /// カレンダーに同期される開始・終了時間（[JournalStore.updateTaskSchedule]）。
  DateTime? startAt;
  DateTime? endAt;
  bool isAllDay;

  /// プッシュ通知の発火時刻。開始・終了時間とは完全に独立
  /// （[JournalStore.updateTaskNotifyAt]）。
  DateTime? notifyAt;

  _TaskDraft(this.task)
    : titleController = TextEditingController(text: task.title),
      startAt = task.reminderAt,
      endAt = task.reminderEndAt,
      isAllDay = task.isAllDay,
      notifyAt = task.notifyAt;

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

  // --- 開始・終了時間（カレンダー同期用） ---

  Future<void> _pickStartDate(_TaskDraft draft) async {
    final base = draft.startAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      draft.startAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        base.hour,
        base.minute,
      );
      _keepEndAfterStart(draft);
    });
  }

  Future<void> _pickStartTime(_TaskDraft draft) async {
    final base = draft.startAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    setState(() {
      draft.startAt = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );
      _keepEndAfterStart(draft);
    });
  }

  Future<void> _addStart(_TaskDraft draft) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      draft.startAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _clearStart(_TaskDraft draft) {
    setState(() {
      draft.startAt = null;
      draft.endAt = null;
      draft.isAllDay = false;
    });
  }

  void _setAllDay(_TaskDraft draft, bool value) {
    setState(() {
      draft.isAllDay = value;
      final at = draft.startAt;
      if (value) {
        draft.endAt = null;
        if (at != null) {
          draft.startAt = DateTime(at.year, at.month, at.day);
          draft.notifyAt ??= TaskItem.defaultAllDayNotifyAt(draft.startAt!);
        }
      }
    });
  }

  // 開始日時を変更したとき、終了日時がそれより前になっていたら消す
  // （意味のない範囲が残らないようにする）。
  void _keepEndAfterStart(_TaskDraft draft) {
    final start = draft.startAt;
    final end = draft.endAt;
    if (start != null && end != null && end.isBefore(start)) {
      draft.endAt = null;
    }
  }

  Future<void> _addEndTime(_TaskDraft draft) async {
    final base = draft.startAt ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: draft.startAt ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;
    setState(() {
      draft.endAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickEndDate(_TaskDraft draft) async {
    final base = draft.endAt ?? draft.startAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: draft.startAt ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      draft.endAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        base.hour,
        base.minute,
      );
    });
  }

  Future<void> _pickEndTime(_TaskDraft draft) async {
    final base = draft.endAt ?? draft.startAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    setState(() {
      draft.endAt = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _clearEndTime(_TaskDraft draft) {
    setState(() => draft.endAt = null);
  }

  // --- リマインダー通知（開始・終了時間とは独立） ---

  Future<void> _pickNotifyDate(_TaskDraft draft) async {
    final base = draft.notifyAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      draft.notifyAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        base.hour,
        base.minute,
      );
    });
  }

  Future<void> _pickNotifyTime(_TaskDraft draft) async {
    final base = draft.notifyAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    setState(() {
      draft.notifyAt = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _addNotify(_TaskDraft draft) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      draft.notifyAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _clearNotify(_TaskDraft draft) {
    setState(() => draft.notifyAt = null);
  }

  Future<void> _save(JournalStore store, JournalEntry entry) async {
    for (final d in _drafts ?? const <_TaskDraft>[]) {
      final title = d.titleController.text.trim();
      if (title.isNotEmpty && title != d.task.title) {
        await store.updateTaskTitle(entry, d.task, title);
      }
      if (d.startAt != d.task.reminderAt ||
          d.endAt != d.task.reminderEndAt ||
          d.isAllDay != d.task.isAllDay) {
        await store.updateTaskSchedule(
          entry,
          d.task,
          startAt: d.startAt,
          endAt: d.endAt,
          isAllDay: d.isAllDay,
        );
      }
      if (d.notifyAt != d.task.notifyAt) {
        await store.updateTaskNotifyAt(entry, d.task, d.notifyAt);
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
          if (draft.startAt != null) ...[
            const SizedBox(height: 10),
            FilterChip(
              label: Text(l10n.allDayLabel),
              selected: draft.isAllDay,
              onSelected: (value) => _setAllDay(draft, value),
              visualDensity: VisualDensity.compact,
            ),
          ],
          const SizedBox(height: 16),
          _buildLabel(theme, l10n.taskScheduleLabel),
          const SizedBox(height: 6),
          _buildScheduleSection(draft, locale, l10n),
          const SizedBox(height: 16),
          _buildLabel(theme, l10n.reminderLabel),
          const SizedBox(height: 6),
          _buildNotifySection(draft, locale, l10n),
        ],
      ),
    );
  }

  Widget _buildLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.outline,
      ),
    );
  }

  Widget _buildScheduleSection(
    _TaskDraft draft,
    String locale,
    AppLocalizations l10n,
  ) {
    final startAt = draft.startAt;
    if (startAt == null) {
      return OutlinedButton.icon(
        onPressed: () => _addStart(draft),
        icon: const Icon(Icons.event_outlined, size: 16),
        label: Text(l10n.addStartTime),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScheduleRow(
          theme: Theme.of(context),
          caption: l10n.startTimeCaption,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickStartDate(draft),
              icon: const Icon(Icons.event_outlined, size: 16),
              label: Text(_dateLabel(startAt, locale)),
            ),
            if (!draft.isAllDay)
              OutlinedButton.icon(
                onPressed: () => _pickStartTime(draft),
                icon: const Icon(Icons.schedule_outlined, size: 16),
                label: Text(DateFormat('HH:mm').format(startAt)),
              ),
            IconButton(
              onPressed: () => _clearStart(draft),
              icon: const Icon(Icons.close),
              tooltip: l10n.removeStartTimeTooltip,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (!draft.isAllDay) ...[
          const SizedBox(height: 12),
          _buildScheduleRow(
            theme: Theme.of(context),
            caption: l10n.endTimeCaption,
            children: draft.endAt == null
                ? [
                    OutlinedButton.icon(
                      onPressed: () => _addEndTime(draft),
                      icon: const Icon(Icons.event_outlined, size: 16),
                      label: Text(l10n.addEndTime),
                    ),
                  ]
                : [
                    OutlinedButton.icon(
                      onPressed: () => _pickEndDate(draft),
                      icon: const Icon(Icons.event_outlined, size: 16),
                      label: Text(_dateLabel(draft.endAt!, locale)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickEndTime(draft),
                      icon: const Icon(Icons.schedule_outlined, size: 16),
                      label: Text(DateFormat('HH:mm').format(draft.endAt!)),
                    ),
                    IconButton(
                      onPressed: () => _clearEndTime(draft),
                      icon: const Icon(Icons.close),
                      tooltip: l10n.removeEndTimeTooltip,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
          ),
        ],
      ],
    );
  }

  /// 開始・終了それぞれの行に「開始」「終了」というキャプションを付けて
  /// 見分けやすくする（ユーザーからの「どっちがどっちかわからない」というフィードバックへの対応）。
  Widget _buildScheduleRow({
    required ThemeData theme,
    required String caption,
    required List<Widget> children,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            caption,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildNotifySection(
    _TaskDraft draft,
    String locale,
    AppLocalizations l10n,
  ) {
    final notifyAt = draft.notifyAt;
    if (notifyAt == null) {
      return OutlinedButton.icon(
        onPressed: () => _addNotify(draft),
        icon: const Icon(Icons.add_alarm_outlined, size: 16),
        label: Text(l10n.addReminder),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickNotifyDate(draft),
          icon: const Icon(Icons.event_outlined, size: 16),
          label: Text(_dateLabel(notifyAt, locale)),
        ),
        OutlinedButton.icon(
          onPressed: () => _pickNotifyTime(draft),
          icon: const Icon(Icons.schedule_outlined, size: 16),
          label: Text(DateFormat('HH:mm').format(notifyAt)),
        ),
        IconButton(
          onPressed: () => _clearNotify(draft),
          icon: const Icon(Icons.close),
          tooltip: l10n.removeReminderTooltip,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
