import 'package:intl/intl.dart';

import '../models/journal_entry.dart';

/// 期限表示用ラベル（例: 日本語なら"8月25日(火)"、英語なら"Aug 25 (Tue)"）。
/// 期限が推測できなければ元の言い回し（dueHint）、それも無ければ null。
String? dueLabelFor({
  DateTime? dueDate,
  String? dueHint,
  required String locale,
}) {
  if (dueDate != null) {
    final datePart = DateFormat.MMMd(locale).format(dueDate);
    final weekdayPart = DateFormat.E(locale).format(dueDate);
    return '$datePart($weekdayPart)';
  }
  if (dueHint != null && dueHint.isNotEmpty) {
    return dueHint;
  }
  return null;
}

/// タスクの期限表示用ラベル。[dueLabelFor] の [TaskItem] 版。
String? taskDueLabel(TaskItem task, {required String locale}) => dueLabelFor(
      dueDate: task.dueDate,
      dueHint: task.dueHint,
      locale: locale,
    );
