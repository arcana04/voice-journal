class WeeklyReportKeyword {
  final String keyword;
  final int count;

  WeeklyReportKeyword({required this.keyword, required this.count});

  factory WeeklyReportKeyword.fromJson(Map<String, dynamic> json) {
    return WeeklyReportKeyword(
      keyword: (json['keyword'] as String? ?? '').trim(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ShiningIdea {
  final String title;
  final String reason;

  ShiningIdea({required this.title, required this.reason});

  factory ShiningIdea.fromJson(Map<String, dynamic> json) {
    return ShiningIdea(
      title: (json['title'] as String? ?? '').trim(),
      reason: (json['reason'] as String? ?? '').trim(),
    );
  }
}

/// AIが生成する週刊レポートのうち、判断や自然言語生成が必要な部分。
/// 感情比率や達成数などの集計値はローカルDBから直接計算するため含まない。
class WeeklyReportInsights {
  final String emotionNarrative;
  final List<WeeklyReportKeyword> topKeywords;
  final List<ShiningIdea> shiningIdeas;
  final String advice;

  WeeklyReportInsights({
    required this.emotionNarrative,
    required this.topKeywords,
    required this.shiningIdeas,
    required this.advice,
  });

  factory WeeklyReportInsights.fromJson(Map<String, dynamic> json) {
    return WeeklyReportInsights(
      emotionNarrative: (json['emotion_narrative'] as String? ?? '').trim(),
      topKeywords: (json['top_keywords'] as List? ?? [])
          .map((e) => WeeklyReportKeyword.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((k) => k.keyword.isNotEmpty)
          .toList(),
      shiningIdeas: (json['shining_ideas'] as List? ?? [])
          .map((e) => ShiningIdea.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((i) => i.title.isNotEmpty)
          .toList(),
      advice: (json['advice'] as String? ?? '').trim(),
    );
  }
}
