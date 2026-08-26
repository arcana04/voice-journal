import '../l10n/app_localizations.dart';

/// AIが日記（感情ログ）の内容から判定する感情タグ。バックエンドから受け取る
/// [id]は固定の英語識別子で、絵文字と表示ラベルはこちら側で持つ。
enum EmotionTag {
  fatigue('fatigue', '😩'),
  love('love', '😍'),
  anxious('anxious', '😰'),
  excited('excited', '🤩'),
  joy('joy', '😄'),
  sadness('sadness', '😢'),
  anger('anger', '😠'),
  satisfaction('satisfaction', '😊'),
  neutral('neutral', '😐');

  final String id;
  final String emoji;
  const EmotionTag(this.id, this.emoji);

  String labelFor(AppLocalizations l10n) => switch (this) {
        EmotionTag.fatigue => l10n.emotionFatigue,
        EmotionTag.love => l10n.emotionLove,
        EmotionTag.anxious => l10n.emotionAnxious,
        EmotionTag.excited => l10n.emotionExcited,
        EmotionTag.joy => l10n.emotionJoy,
        EmotionTag.sadness => l10n.emotionSadness,
        EmotionTag.anger => l10n.emotionAnger,
        EmotionTag.satisfaction => l10n.emotionSatisfaction,
        EmotionTag.neutral => l10n.emotionNeutral,
      };

  static EmotionTag? fromId(String? id) {
    if (id == null) return null;
    for (final e in EmotionTag.values) {
      if (e.id == id) return e;
    }
    return null;
  }
}
