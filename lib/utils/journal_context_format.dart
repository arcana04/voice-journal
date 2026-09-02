import 'package:intl/intl.dart';

import '../models/emotion_tag.dart';
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
    final emotionSuffix = entry.emotion == null ? '' : ' — ${_emotionLabel(entry.emotion!, locale)}';
    buffer.writeln('■ ${dateFormat.format(entry.createdAt)}$emotionSuffix');
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

/// AIへのコンテキスト整形専用のラベル。l10n（BuildContext）を使えない純粋な
/// フォーマット関数なので、[EmotionTag.labelFor]とは別に、AI向けの識別しやすい
/// 短い語をここに直接持つ（表示中の[EmotionTag.labelFor]と表記は基本的に一致させる）。
String _emotionLabel(EmotionTag tag, String locale) {
  if (locale == 'en') {
    return switch (tag) {
      EmotionTag.satisfaction => 'Satisfaction',
      EmotionTag.gratitude => 'Gratitude',
      EmotionTag.happy => 'Happy',
      EmotionTag.love => 'Love',
      EmotionTag.funny => 'Funny',
      EmotionTag.joy => 'Joy',
      EmotionTag.excited => 'Excited',
      EmotionTag.relief => 'Relief',
      EmotionTag.calm => 'Calm',
      EmotionTag.neutral => 'Neutral',
      EmotionTag.boredom => 'Boredom',
      EmotionTag.anxious => 'Anxious',
      EmotionTag.sadness => 'Sad',
      EmotionTag.fatigue => 'Tired',
      EmotionTag.regret => 'Regret',
      EmotionTag.anger => 'Anger',
      EmotionTag.dislike => 'Dislike',
    };
  }
  return switch (tag) {
    EmotionTag.satisfaction => '満足',
    EmotionTag.gratitude => '感謝',
    EmotionTag.happy => '嬉しい',
    EmotionTag.love => '好き',
    EmotionTag.funny => '面白い',
    EmotionTag.joy => '楽しい',
    EmotionTag.excited => 'ドキドキ',
    EmotionTag.relief => '安心',
    EmotionTag.calm => '穏やか',
    EmotionTag.neutral => '普通',
    EmotionTag.boredom => '退屈',
    EmotionTag.anxious => '不安',
    EmotionTag.sadness => '悲しい',
    EmotionTag.fatigue => '疲れた',
    EmotionTag.regret => '後悔',
    EmotionTag.anger => '怒り',
    EmotionTag.dislike => '嫌い',
  };
}
