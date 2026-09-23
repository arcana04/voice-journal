import 'package:intl/intl.dart';

import '../models/journal_entry.dart';

/// 期限表示用ラベル（例: 日本語なら"8月25日(火)"、英語なら"Aug 25 (Tue)"）。
/// [dueDateEnd]が指定されていれば（複数日にまたがる終日の予定）、
/// 「Sep 26 - Sep 28」のような範囲表示にする——2日目以降は曜日を省略して
/// カード幅に収まるコンパクトな表記にする。
/// 期限が推測できなければ元の言い回し（dueHint）、それも無ければ null。
String? dueLabelFor({
  DateTime? dueDate,
  DateTime? dueDateEnd,
  String? dueHint,
  required String locale,
}) {
  if (dueDate != null) {
    final datePart = DateFormat.MMMd(locale).format(dueDate);
    if (dueDateEnd != null && dueDateEnd.isAfter(dueDate)) {
      final endPart = DateFormat.MMMd(locale).format(dueDateEnd);
      return '$datePart - $endPart';
    }
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
      dueDateEnd: task.dueDateEnd,
      dueHint: task.dueHint,
      locale: locale,
    );
