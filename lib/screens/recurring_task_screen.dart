import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';

const int _kMaxOccurrences = 200;

class _WeekdayOption {
  final int weekday;
  final String label;

  const _WeekdayOption(this.weekday, this.label);
}

List<_WeekdayOption> _weekdayOptions(String locale) {
  // 2024-01-01 は月曜日。この週を基準に曜日ラベルをロケールに合わせて生成する。
  final monday = DateTime(2024, 1, 1);
  return List.generate(7, (i) {
    final date = monday.add(Duration(days: i));
    return _WeekdayOption(date.weekday, DateFormat.E(locale).format(date));
  });
}

String _dateLabel(DateTime date, String locale) =>
    '${DateFormat.MMMd(locale).format(date)}(${DateFormat.E(locale).format(date)})';

String _timeLabel(TimeOfDay time) =>
    DateFormat('HH:mm').format(DateTime(2000, 1, 1, time.hour, time.minute));

/// 「毎週火・木」のように曜日を指定して一括でタスク（リマインダー）を作成する画面。
class RecurringTaskScreen extends StatefulWidget {
  const RecurringTaskScreen({super.key});

  @override
  State<RecurringTaskScreen> createState() => _RecurringTaskScreenState();
}

class _RecurringTaskScreenState extends State<RecurringTaskScreen> {
  final _titleController = TextEditingController();
  final Set<int> _selectedWeekdays = {};
  DateTime _startDate = DateTime.now();
  late DateTime _endDate = _startDate.add(const Duration(days: 30));
  bool _hasTime = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  List<DateTime> _occurrenceDates() {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    if (end.isBefore(start) || _selectedWeekdays.isEmpty) return const [];
    final dates = <DateTime>[];
    var day = start;
    while (!day.isAfter(end) && dates.length <= _kMaxOccurrences) {
      if (_selectedWeekdays.contains(day.weekday)) dates.add(day);
      day = day.add(const Duration(days: 1));
    }
    return dates;
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      if (_endDate.isBefore(_startDate)) _endDate = _startDate;
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _endDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() => _endTime = picked);
  }

  TaskItem _buildTask(DateTime date, String title) {
    if (_hasTime && _startTime != null) {
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endTime = _endTime;
      final end = endTime != null
          ? DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute)
          : null;
      return TaskItem(
        title: title,
        dueDate: date,
        reminderAt: start,
        reminderEndAt: end,
        notifyAt: start,
      );
    }
    return TaskItem(
      title: title,
      dueDate: date,
      reminderAt: date,
      isAllDay: true,
    );
  }

  String? _validate(AppLocalizations l10n, List<DateTime> dates) {
    if (_titleController.text.trim().isEmpty) {
      return l10n.recurringTitleRequiredError;
    }
    if (_selectedWeekdays.isEmpty) {
      return l10n.recurringSelectWeekdayError;
    }
    if (_endDate.isBefore(_startDate)) {
      return l10n.recurringInvalidPeriodError;
    }
    if (_hasTime && _startTime == null) {
      return l10n.recurringStartTimeRequiredError;
    }
    if (dates.isEmpty) {
      return l10n.recurringInvalidPeriodError;
    }
    if (dates.length > _kMaxOccurrences) {
      return l10n.recurringTooManyError(_kMaxOccurrences);
    }
    return null;
  }

  Future<void> _save(String locale) async {
    final l10n = AppLocalizations.of(context)!;
    final dates = _occurrenceDates();
    final error = _validate(l10n, dates);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final title = _titleController.text.trim();
    setState(() => _saving = true);
    try {
      final weekdayLabels = _weekdayOptions(locale)
          .where((w) => _selectedWeekdays.contains(w.weekday))
          .map((w) => w.label)
          .join(locale.startsWith('ja') ? '・' : ', ');
      final entry = JournalEntry(
        createdAt: DateTime.now(),
        summary: l10n.recurringTaskSummary(title, weekdayLabels),
        tasks: dates.map((d) => _buildTask(d, title)).toList(),
        notes: const [],
      );
      await context.read<JournalStore>().addEntry(entry);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final occurrenceCount = _occurrenceDates().length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringTaskScreenTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(locale),
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.add),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.recurringTaskTitleHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.recurringWeekdaysLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _weekdayOptions(locale))
                  FilterChip(
                    label: Text(option.label),
                    selected: _selectedWeekdays.contains(option.weekday),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _selectedWeekdays.add(option.weekday);
                      } else {
                        _selectedWeekdays.remove(option.weekday);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.recurringPeriodLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: const Icon(Icons.event_outlined, size: 16),
                  label: Text(_dateLabel(_startDate, locale)),
                ),
                const Icon(Icons.arrow_forward, size: 16),
                OutlinedButton.icon(
                  onPressed: _pickEndDate,
                  icon: const Icon(Icons.event_outlined, size: 16),
                  label: Text(_dateLabel(_endDate, locale)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.specifyTimeLabel),
              value: _hasTime,
              onChanged: (value) => setState(() => _hasTime = value),
            ),
            if (_hasTime)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickStartTime,
                    icon: const Icon(Icons.schedule_outlined, size: 16),
                    label: Text(
                      _startTime != null ? _timeLabel(_startTime!) : l10n.addReminder,
                    ),
                  ),
                  if (_startTime != null) ...[
                    const Text('-'),
                    OutlinedButton.icon(
                      onPressed: _pickEndTime,
                      icon: const Icon(Icons.schedule_outlined, size: 16),
                      label: Text(
                        _endTime != null ? _timeLabel(_endTime!) : l10n.addReminder,
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 24),
            if (occurrenceCount > 0)
              Text(
                l10n.recurringTaskCount(occurrenceCount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
