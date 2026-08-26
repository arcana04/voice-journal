import 'package:intl/intl.dart';

import '../models/journal_entry.dart';

/// 過去の記録をAIへのコンテキストとして渡すためのプレーンテキスト整形。
/// 「第二の脳」チャットと週刊レポートで共通して使う、全件詰め込みMVP方式の処理。
String formatEntriesAsContext(
  List<JournalEntry> entries,
  String locale, {
  int maxEntries = 200,
  int maxChars = 24000,
}) {
  final dateFormat = DateFormat.yMMMd(locale);
  final taskLabel = locale == 'en' ? 'Task' : 'タスク';
  final doneMark = locale == 'en' ? '(done) ' : '(完了) ';
  final buffer = StringBuffer();

  for (final entry in entries.take(maxEntries)) {
    if (buffer.length >= maxChars) break;
    buffer.writeln('■ ${dateFormat.format(entry.createdAt)}');
    for (final note in entry.notes) {
      final label = _categoryLabel(note.category, locale);
      final title = note.title == null ? '' : '${note.title}: ';
      buffer.writeln('[$label] $title${note.content}');
    }
    for (final task in entry.tasks) {
      buffer.writeln('[$taskLabel] ${task.done ? doneMark : ''}${task.title}');
    }
    buffer.writeln();
  }

  final text = buffer.toString();
  return text.length > maxChars ? text.substring(0, maxChars) : text;
}

String _categoryLabel(String category, String locale) {
  if (locale != 'en') return category;
  return category == kNoteCategoryIdea ? 'Idea' : 'Feeling';
}
