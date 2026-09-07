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
  final taskLabel = switch (locale) {
    'en' => 'Task',
    'es' => 'Tarea',
    'de' => 'Aufgabe',
    _ => 'タスク',
  };
  final doneMark = switch (locale) {
    'en' => '(done) ',
    'es' => '(hecho) ',
    'de' => '(erledigt) ',
    _ => '(完了) ',
  };
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

/// noteの[category]はDBには常に固定の日本語文字列（アイデア／感情ログ）で
/// 保存されているため、表示用ラベルはロケールごとにここで変換する。
String _categoryLabel(String category, String locale) {
  final isIdea = category == kNoteCategoryIdea;
  return switch (locale) {
    'en' => isIdea ? 'Idea' : 'Feeling',
    'es' => isIdea ? 'Idea' : 'Sentimiento',
    'de' => isIdea ? 'Idee' : 'Gefühl',
    _ => category,
  };
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
  if (locale == 'es') {
    return switch (tag) {
      EmotionTag.satisfaction => 'Satisfacción',
      EmotionTag.gratitude => 'Gratitud',
      EmotionTag.happy => 'Feliz',
      EmotionTag.love => 'Amor',
      EmotionTag.funny => 'Divertido',
      EmotionTag.joy => 'Alegría',
      EmotionTag.excited => 'Emocionado',
      EmotionTag.relief => 'Alivio',
      EmotionTag.calm => 'Tranquilo',
      EmotionTag.neutral => 'Neutral',
      EmotionTag.boredom => 'Aburrimiento',
      EmotionTag.anxious => 'Ansioso',
      EmotionTag.sadness => 'Triste',
      EmotionTag.fatigue => 'Cansado',
      EmotionTag.regret => 'Arrepentimiento',
      EmotionTag.anger => 'Enojo',
      EmotionTag.dislike => 'Disgusto',
    };
  }
  if (locale == 'de') {
    return switch (tag) {
      EmotionTag.satisfaction => 'Zufriedenheit',
      EmotionTag.gratitude => 'Dankbarkeit',
      EmotionTag.happy => 'Glücklich',
      EmotionTag.love => 'Liebe',
      EmotionTag.funny => 'Lustig',
      EmotionTag.joy => 'Freude',
      EmotionTag.excited => 'Aufgeregt',
      EmotionTag.relief => 'Erleichterung',
      EmotionTag.calm => 'Ruhig',
      EmotionTag.neutral => 'Neutral',
      EmotionTag.boredom => 'Langeweile',
      EmotionTag.anxious => 'Ängstlich',
      EmotionTag.sadness => 'Traurig',
      EmotionTag.fatigue => 'Müde',
      EmotionTag.regret => 'Bedauern',
      EmotionTag.anger => 'Wut',
      EmotionTag.dislike => 'Abneigung',
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
