import 'package:intl/intl.dart';

import '../models/journal_entry.dart';

const _weekdayKanji = ['月', '火', '水', '木', '金', '土', '日'];

/// 期限表示用ラベル（例: "8月25日(火)"）。期限が推測できなければ
/// 元の言い回し（dueHint）、それも無ければ null。
String? dueLabelFor({DateTime? dueDate, String? dueHint}) {
  if (dueDate != null) {
    final weekday = _weekdayKanji[dueDate.weekday - 1];
    return '${DateFormat('M月d日').format(dueDate)}($weekday)';
  }
  if (dueHint != null && dueHint.isNotEmpty) {
    return dueHint;
  }
  return null;
}

/// タスクの期限表示用ラベル。[dueLabelFor] の [TaskItem] 版。
String? taskDueLabel(TaskItem task) =>
    dueLabelFor(dueDate: task.dueDate, dueHint: task.dueHint);
