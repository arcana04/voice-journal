import 'package:intl/intl.dart';

import '../models/journal_entry.dart';

const _weekdayKanji = ['月', '火', '水', '木', '金', '土', '日'];

/// タスクの期限表示用ラベル（例: "8月25日(火)"）。期限が推測できなければ
/// 元の言い回し（due_hint）、それも無ければ null。
String? taskDueLabel(TaskItem task) {
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
