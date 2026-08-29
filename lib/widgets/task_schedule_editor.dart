import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/task_schedule_draft.dart';

String _dateLabel(DateTime date, String locale) =>
    '${DateFormat.MMMd(locale).format(date)}(${DateFormat.E(locale).format(date)})';

/// タスクの「開始・終了時間（カレンダー同期用）」と「通知時刻（プッシュ通知用）」
/// を編集するUI一式（全日チップ・日時ピッカーボタン群）。[ManualTaskScreen]（新規
/// 作成）と[TaskEditScreen]（既存タスク編集）で日時ピッカーのロジック・UIが
/// ほぼ丸ごと重複していたのをまとめたもの。[draft]を直接書き換えたあと
/// [onChanged]を呼ぶ（呼び出し側がsetStateするための通知——[draft]自体は
/// Listenableではないシンプルな可変オブジェクト）。
class TaskScheduleEditor extends StatelessWidget {
  final TaskScheduleDraft draft;
  final VoidCallback onChanged;

  const TaskScheduleEditor({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  Future<void> _addStart(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    draft.startAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    onChanged();
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final base = draft.startAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    draft.startAt = DateTime(
      picked.year,
      picked.month,
      picked.day,
      base.hour,
      base.minute,
    );
    draft.keepEndAfterStart();
    onChanged();
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final base = draft.startAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    draft.startAt = DateTime(
      base.year,
      base.month,
      base.day,
      picked.hour,
      picked.minute,
    );
    draft.keepEndAfterStart();
    onChanged();
  }

  void _clearStart() {
    draft.clearStart();
    onChanged();
  }

  void _setAllDay(bool value) {
    draft.setAllDay(value);
    onChanged();
  }

  Future<void> _addEndTime(BuildContext context) async {
    final base = draft.startAt ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: draft.startAt ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;
    draft.endAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    onChanged();
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final base = draft.endAt ?? draft.startAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: draft.startAt ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    draft.endAt = DateTime(
      picked.year,
      picked.month,
      picked.day,
      base.hour,
      base.minute,
    );
    onChanged();
  }

  Future<void> _pickEndTime(BuildContext context) async {
    final base = draft.endAt ?? draft.startAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    draft.endAt = DateTime(
      base.year,
      base.month,
      base.day,
      picked.hour,
      picked.minute,
    );
    onChanged();
  }

  void _clearEndTime() {
    draft.clearEndTime();
    onChanged();
  }

  Future<void> _addNotify(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    draft.notifyAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    onChanged();
  }

  Future<void> _pickNotifyDate(BuildContext context) async {
    final base = draft.notifyAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    draft.notifyAt = DateTime(
      picked.year,
      picked.month,
      picked.day,
      base.hour,
      base.minute,
    );
    onChanged();
  }

  Future<void> _pickNotifyTime(BuildContext context) async {
    final base = draft.notifyAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    draft.notifyAt = DateTime(
      base.year,
      base.month,
      base.day,
      picked.hour,
      picked.minute,
    );
    onChanged();
  }

  void _clearNotify() {
    draft.clearNotify();
    onChanged();
  }

  Widget _buildLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.outline,
      ),
    );
  }

  /// 開始・終了それぞれの行に「開始」「終了」というキャプションを付けて
  /// 見分けやすくする（ユーザーからの「どっちがどっちかわからない」というフィードバックへの対応）。
  Widget _buildScheduleRow(
    BuildContext context, {
    required String caption,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
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

  Widget _buildScheduleSection(
    BuildContext context,
    String locale,
    AppLocalizations l10n,
  ) {
    final startAt = draft.startAt;
    if (startAt == null) {
      return OutlinedButton.icon(
        onPressed: () => _addStart(context),
        icon: const Icon(Icons.event_outlined, size: 16),
        label: Text(l10n.addStartTime),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScheduleRow(
          context,
          caption: l10n.startTimeCaption,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickStartDate(context),
              icon: const Icon(Icons.event_outlined, size: 16),
              label: Text(_dateLabel(startAt, locale)),
            ),
            if (!draft.isAllDay)
              OutlinedButton.icon(
                onPressed: () => _pickStartTime(context),
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
        if (!draft.isAllDay) ...[
          const SizedBox(height: 12),
          _buildScheduleRow(
            context,
            caption: l10n.endTimeCaption,
            children: draft.endAt == null
                ? [
                    OutlinedButton.icon(
                      onPressed: () => _addEndTime(context),
                      icon: const Icon(Icons.event_outlined, size: 16),
                      label: Text(l10n.addEndTime),
                    ),
                  ]
                : [
                    OutlinedButton.icon(
                      onPressed: () => _pickEndDate(context),
                      icon: const Icon(Icons.event_outlined, size: 16),
                      label: Text(_dateLabel(draft.endAt!, locale)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickEndTime(context),
                      icon: const Icon(Icons.schedule_outlined, size: 16),
                      label: Text(DateFormat('HH:mm').format(draft.endAt!)),
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

  Widget _buildNotifySection(
    BuildContext context,
    String locale,
    AppLocalizations l10n,
  ) {
    final notifyAt = draft.notifyAt;
    if (notifyAt == null) {
      return OutlinedButton.icon(
        onPressed: () => _addNotify(context),
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
          onPressed: () => _pickNotifyDate(context),
          icon: const Icon(Icons.event_outlined, size: 16),
          label: Text(_dateLabel(notifyAt, locale)),
        ),
        OutlinedButton.icon(
          onPressed: () => _pickNotifyTime(context),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (draft.startAt != null) ...[
          FilterChip(
            label: Text(l10n.allDayLabel),
            selected: draft.isAllDay,
            onSelected: _setAllDay,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 16),
        ],
        _buildLabel(theme, l10n.taskScheduleLabel),
        const SizedBox(height: 6),
        _buildScheduleSection(context, locale, l10n),
        const SizedBox(height: 16),
        _buildLabel(theme, l10n.reminderLabel),
        const SizedBox(height: 6),
        _buildNotifySection(context, locale, l10n),
      ],
    );
  }
}
