import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// 感情タグの3分類（参考デザインのPositive/Fine/Negativeグルーピング）。
/// 感情選択シートのグループ見出しに使う。
enum EmotionCategory { positive, fine, negative }

/// AIが日記（感情ログ）の内容から判定する感情タグ。バックエンドから受け取る
/// [id]は固定の英語識別子で、表示ラベル・色はこちら側で持つ。
/// [id]は既存9種を含め後方互換のため変更しない（DB・Firestoreに生文字列で
/// 保存されているため）。表示は[EmotionBubble]が正円1種類・[color]の塗り
/// だけで統一する（個別の画像アセットは持たない）。[color]は[category]ごとに
/// 色相ファミリーを揃えている（positive=暖色/fine=緑〜ティール/negative=
/// 青〜インディゴ、いずれも黒に近づけすぎず視認性を確保）ので、同じ
/// カテゴリ内の他の値と大きく外れた色相にしないこと。
enum EmotionTag {
  satisfaction('satisfaction', Color(0xFFECA413), EmotionCategory.positive),
  gratitude('gratitude', Color(0xFFE76423), EmotionCategory.positive),
  happy('happy', Color(0xFFE75740), EmotionCategory.positive),
  love('love', Color(0xFFDD3C71), EmotionCategory.positive),
  funny('funny', Color(0xFFDF2030), EmotionCategory.positive),
  joy('joy', Color(0xFFE7C623), EmotionCategory.positive),
  excited('excited', Color(0xFF28BD98), EmotionCategory.fine),
  relief('relief', Color(0xFF2BAB76), EmotionCategory.fine),
  calm('calm', Color(0xFF34A7B2), EmotionCategory.fine),
  neutral('neutral', Color(0xFF669991), EmotionCategory.fine),
  boredom('boredom', Color(0xFF428A84), EmotionCategory.fine),
  anxious('anxious', Color(0xFF5C39C6), EmotionCategory.negative),
  sadness('sadness', Color(0xFF3156C4), EmotionCategory.negative),
  fatigue('fatigue', Color(0xFF5980A6), EmotionCategory.negative),
  regret('regret', Color(0xFF633B9B), EmotionCategory.negative),
  anger('anger', Color(0xFF3528BD), EmotionCategory.negative),
  dislike('dislike', Color(0xFF4D5180), EmotionCategory.negative);

  final String id;
  final Color color;
  final EmotionCategory category;

  const EmotionTag(this.id, this.color, this.category);

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
