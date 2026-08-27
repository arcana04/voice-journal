import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';

String _dateLabel(DateTime date, String locale) =>
    '${DateFormat.MMMd(locale).format(date)}(${DateFormat.E(locale).format(date)})';

/// AIの解析を経ずに、手動で1件だけタスクを作成する画面。買い物や単純な用事など、
/// 録音・AI解析するまでもない内容を無料枠を消費せずすぐに登録できるようにする。
class ManualTaskScreen extends StatefulWidget {
  const ManualTaskScreen({super.key});

  @override
  State<ManualTaskScreen> createState() => _ManualTaskScreenState();
}

class _ManualTaskScreenState extends State<ManualTaskScreen> {
  final _titleController = TextEditingController();
  DateTime? _startAt;
  DateTime? _endAt;
  bool _isAllDay = false;
  DateTime? _notifyAt;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // --- 開始・終了時間（カレンダー同期用） ---

  Future<void> _addStart() async {
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
      _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickStartDate() async {
    final base = _startAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _startAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        base.hour,
        base.minute,
      );
      _keepEndAfterStart();
    });
  }

  Future<void> _pickStartTime() async {
    final base = _startAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    setState(() {
      _startAt = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );
      _keepEndAfterStart();
    });
  }

  void _clearStart() {
    setState(() {
      _startAt = null;
      _endAt = null;
      _isAllDay = false;
    });
  }

  void _setAllDay(bool value) {
    setState(() {
      _isAllDay = value;
      final at = _startAt;
      if (value) {
        _endAt = null;
        if (at != null) {
          _startAt = DateTime(at.year, at.month, at.day);
        }
      }
    });
  }

  void _keepEndAfterStart() {
    final start = _startAt;
    final end = _endAt;
    if (start != null && end != null && end.isBefore(start)) {
      _endAt = null;
    }
  }

  Future<void> _addEndTime() async {
    final base = _startAt ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: _startAt ?? DateTime(2000),
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
      _endAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickEndDate() async {
    final base = _endAt ?? _startAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: _startAt ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _endAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        base.hour,
        base.minute,
      );
    });
  }

  Future<void> _pickEndTime() async {
    final base = _endAt ?? _startAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    setState(() {
      _endAt = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _clearEndTime() {
    setState(() => _endAt = null);
  }

  // --- リマインダー通知（開始・終了時間とは独立） ---

  Future<void> _addNotify() async {
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
      _notifyAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickNotifyDate() async {
    final base = _notifyAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _notifyAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        base.hour,
        base.minute,
      );
    });
  }

  Future<void> _pickNotifyTime() async {
    final base = _notifyAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    setState(() {
      _notifyAt = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _clearNotify() {
    setState(() => _notifyAt = null);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.manualTaskTitleRequiredError)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final startAt = _startAt;
      final task = TaskItem(
        title: title,
        dueDate: startAt != null
            ? DateTime(startAt.year, startAt.month, startAt.day)
            : null,
        reminderAt: startAt,
        reminderEndAt: _endAt,
        isAllDay: _isAllDay,
        notifyAt: _notifyAt,
      );
      final entry = JournalEntry(
        createdAt: DateTime.now(),
        summary: title,
        tasks: [task],
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manualTaskScreenTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
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
              autofocus: true,
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                labelText: l10n.manualTaskTitleHint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_startAt != null) ...[
              const SizedBox(height: 16),
              FilterChip(
                label: Text(l10n.allDayLabel),
                selected: _isAllDay,
                onSelected: _setAllDay,
                visualDensity: VisualDensity.compact,
              ),
            ],
            const SizedBox(height: 20),
            _buildLabel(theme, l10n.taskScheduleLabel),
            const SizedBox(height: 6),
            _buildScheduleSection(locale, l10n),
            const SizedBox(height: 20),
            _buildLabel(theme, l10n.reminderLabel),
            const SizedBox(height: 6),
            _buildNotifySection(locale, l10n),
          ],
        ),
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

  Widget _buildScheduleSection(String locale, AppLocalizations l10n) {
    final startAt = _startAt;
    if (startAt == null) {
      return OutlinedButton.icon(
        onPressed: _addStart,
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
              onPressed: _pickStartDate,
              icon: const Icon(Icons.event_outlined, size: 16),
              label: Text(_dateLabel(startAt, locale)),
            ),
            if (!_isAllDay)
              OutlinedButton.icon(
                onPressed: _pickStartTime,
                icon: const Icon(Icons.schedule_outlined, size: 16),
                label: Text(DateFormat('HH:mm').format(startAt)),
              ),
            IconButton(
              onPressed: _clearStart,
              icon: const Icon(Icons.close),
              tooltip: l10n.removeStartTimeTooltip,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (!_isAllDay) ...[
          const SizedBox(height: 12),
          _buildScheduleRow(
            theme: Theme.of(context),
            caption: l10n.endTimeCaption,
            children: _endAt == null
                ? [
                    OutlinedButton.icon(
                      onPressed: _addEndTime,
                      icon: const Icon(Icons.event_outlined, size: 16),
                      label: Text(l10n.addEndTime),
                    ),
                  ]
                : [
                    OutlinedButton.icon(
                      onPressed: _pickEndDate,
                      icon: const Icon(Icons.event_outlined, size: 16),
                      label: Text(_dateLabel(_endAt!, locale)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickEndTime,
                      icon: const Icon(Icons.schedule_outlined, size: 16),
                      label: Text(DateFormat('HH:mm').format(_endAt!)),
                    ),
                    IconButton(
                      onPressed: _clearEndTime,
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

  Widget _buildNotifySection(String locale, AppLocalizations l10n) {
    final notifyAt = _notifyAt;
    if (notifyAt == null) {
      return OutlinedButton.icon(
        onPressed: _addNotify,
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
          onPressed: _pickNotifyDate,
          icon: const Icon(Icons.event_outlined, size: 16),
          label: Text(_dateLabel(notifyAt, locale)),
        ),
        OutlinedButton.icon(
          onPressed: _pickNotifyTime,
          icon: const Icon(Icons.schedule_outlined, size: 16),
          label: Text(DateFormat('HH:mm').format(notifyAt)),
        ),
        IconButton(
          onPressed: _clearNotify,
          icon: const Icon(Icons.close),
          tooltip: l10n.removeReminderTooltip,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
