import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// 感情タグの3分類（参考デザインのPositive/Fine/Negativeグルーピング）。
/// 感情選択シートのグループ見出しに使う。
enum EmotionCategory { positive, fine, negative }

/// AIが日記（感情ログ）の内容から判定する感情タグ。バックエンドから受け取る
/// [id]は固定の英語識別子で、表示ラベル・泡画像・色はこちら側で持つ。
/// [id]は既存9種を含め後方互換のため変更しない（DB・Firestoreに生文字列で
/// 保存されているため）。
enum EmotionTag {
  satisfaction(
    'satisfaction',
    'assets/images/emotion_bubbles/emotion_satisfaction.png',
    Color(0xFFBA6A02),
    EmotionCategory.positive,
  ),
  gratitude(
    'gratitude',
    'assets/images/emotion_bubbles/emotion_gratitude.png',
    Color(0xFFD53E28),
    EmotionCategory.positive,
  ),
  happy(
    'happy',
    'assets/images/emotion_bubbles/emotion_happy.png',
    Color(0xFFC53001),
    EmotionCategory.positive,
  ),
  love(
    'love',
    'assets/images/emotion_bubbles/emotion_love.png',
    Color(0xFFC41556),
    EmotionCategory.positive,
  ),
  funny(
    'funny',
    'assets/images/emotion_bubbles/emotion_funny.png',
    Color(0xFFB11624),
    EmotionCategory.positive,
  ),
  joy(
    'joy',
    'assets/images/emotion_bubbles/emotion_joy.png',
    Color(0xFF6A8210),
    EmotionCategory.positive,
  ),
  excited(
    'excited',
    'assets/images/emotion_bubbles/emotion_excited.png',
    Color(0xFF59258F),
    EmotionCategory.fine,
  ),
  relief(
    'relief',
    'assets/images/emotion_bubbles/emotion_relief.png',
    Color(0xFF147A5E),
    EmotionCategory.fine,
  ),
  calm(
    'calm',
    'assets/images/emotion_bubbles/emotion_calm.png',
    Color(0xFF0F6DAC),
    EmotionCategory.fine,
  ),
  neutral(
    'neutral',
    'assets/images/emotion_bubbles/emotion_neutral.png',
    Color(0xFF565963),
    EmotionCategory.fine,
  ),
  boredom(
    'boredom',
    'assets/images/emotion_bubbles/emotion_boredom.png',
    Color(0xFF78503D),
    EmotionCategory.fine,
  ),
  anxious(
    'anxious',
    'assets/images/emotion_bubbles/emotion_anxious.png',
    Color(0xFF2A1454),
    EmotionCategory.negative,
  ),
  sadness(
    'sadness',
    'assets/images/emotion_bubbles/emotion_sadness.png',
    Color(0xFF041262),
    EmotionCategory.negative,
  ),
  fatigue(
    'fatigue',
    'assets/images/emotion_bubbles/emotion_fatigue.png',
    Color(0xFF12243E),
    EmotionCategory.negative,
  ),
  regret(
    'regret',
    'assets/images/emotion_bubbles/emotion_regret.png',
    Color(0xFF381C2C),
    EmotionCategory.negative,
  ),
  anger(
    'anger',
    'assets/images/emotion_bubbles/emotion_anger.png',
    Color(0xFF29070D),
    EmotionCategory.negative,
  ),
  dislike(
    'dislike',
    'assets/images/emotion_bubbles/emotion_dislike.png',
    Color(0xFF1C1C1C),
    EmotionCategory.negative,
  );

  final String id;
  final String asset;
  final Color color;
  final EmotionCategory category;

  const EmotionTag(this.id, this.asset, this.color, this.category);

  String labelFor(AppLocalizations l10n) => switch (this) {
        EmotionTag.satisfaction => l10n.emotionSatisfaction,
        EmotionTag.gratitude => l10n.emotionGratitude,
        EmotionTag.happy => l10n.emotionHappy,
        EmotionTag.love => l10n.emotionLove,
        EmotionTag.funny => l10n.emotionFunny,
        EmotionTag.joy => l10n.emotionJoy,
        EmotionTag.excited => l10n.emotionExcited,
        EmotionTag.relief => l10n.emotionRelief,
        EmotionTag.calm => l10n.emotionCalm,
        EmotionTag.neutral => l10n.emotionNeutral,
        EmotionTag.boredom => l10n.emotionBoredom,
        EmotionTag.anxious => l10n.emotionAnxious,
        EmotionTag.sadness => l10n.emotionSadness,
        EmotionTag.fatigue => l10n.emotionFatigue,
        EmotionTag.regret => l10n.emotionRegret,
        EmotionTag.anger => l10n.emotionAnger,
        EmotionTag.dislike => l10n.emotionDislike,
      };

  static EmotionTag? fromId(String? id) {
    if (id == null) return null;
    for (final e in EmotionTag.values) {
      if (e.id == id) return e;
    }
    return null;
  }
}
