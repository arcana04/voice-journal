import 'dart:convert';

import 'emotion_tag.dart';

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

  Map<String, dynamic> toJson() => {'keyword': keyword, 'count': count};
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

  Map<String, dynamic> toJson() => {'title': title, 'reason': reason};
}

class HighlightQuote {
  final String quote;
  final String reason;

  HighlightQuote({required this.quote, required this.reason});

  factory HighlightQuote.fromJson(Map<String, dynamic> json) {
    return HighlightQuote(
      quote: (json['quote'] as String? ?? '').trim(),
      reason: (json['reason'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => {'quote': quote, 'reason': reason};
}

/// AIが生成する週刊レポートのうち、判断や自然言語生成が必要な部分。
/// 感情比率や達成数などの集計値はローカルDBから直接計算するため含まない。
class WeeklyReportInsights {
  final String moodHeadline;
  final String emotionNarrative;
  final List<WeeklyReportKeyword> topKeywords;
  final List<ShiningIdea> shiningIdeas;
  final HighlightQuote highlightQuote;
  final String advice;

  WeeklyReportInsights({
    required this.moodHeadline,
    required this.emotionNarrative,
    required this.topKeywords,
    required this.shiningIdeas,
    required this.highlightQuote,
    required this.advice,
  });

  factory WeeklyReportInsights.fromJson(Map<String, dynamic> json) {
    return WeeklyReportInsights(
      moodHeadline: (json['mood_headline'] as String? ?? '').trim(),
      emotionNarrative: (json['emotion_narrative'] as String? ?? '').trim(),
      topKeywords: (json['top_keywords'] as List? ?? [])
          .map((e) => WeeklyReportKeyword.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((k) => k.keyword.isNotEmpty)
          .toList(),
      shiningIdeas: (json['shining_ideas'] as List? ?? [])
          .map((e) => ShiningIdea.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((i) => i.title.isNotEmpty)
          .toList(),
      highlightQuote: HighlightQuote.fromJson(
        Map<String, dynamic>.from(
          (json['highlight_quote'] as Map?) ?? const {},
        ),
      ),
      advice: (json['advice'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mood_headline': moodHeadline,
        'emotion_narrative': emotionNarrative,
        'top_keywords': topKeywords.map((k) => k.toJson()).toList(),
        'shining_ideas': shiningIdeas.map((i) => i.toJson()).toList(),
        'highlight_quote': highlightQuote.toJson(),
        'advice': advice,
      };
}

/// ローカルDBに保存された、過去の週の週刊レポートのスナップショット。
/// AIの生成結果（[insights]）と、その時点でのローカル集計値を丸ごと保存する
/// ことで、履歴閲覧時にAIを再度呼ばず・再集計もせずそのまま表示できる。
class SavedWeeklyReport {
  final int? id;
  final String weekKey;
  final DateTime weekStart;
  final DateTime weekEnd;
  final WeeklyReportInsights insights;
  final Map<EmotionTag, int> emotionCounts;
  /// 曜日ごと(月〜日、7件)の感情内訳。1日に複数の記録があれば全て保持する
  /// （「今週のオーロラ」の色ブレンドに使うため、単一の代表感情には潰さない）。
  final List<Map<EmotionTag, int>> dailyEmotionCounts;
  final int diaryCount;
  final int ideaCount;
  final int totalTasks;
  final int completedTasks;
  final DateTime createdAt;

  SavedWeeklyReport({
    this.id,
    required this.weekKey,
    required this.weekStart,
    required this.weekEnd,
    required this.insights,
    required this.emotionCounts,
    required this.dailyEmotionCounts,
    required this.diaryCount,
    required this.ideaCount,
    required this.totalTasks,
    required this.completedTasks,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'week_key': weekKey,
      'week_start': weekStart.toIso8601String(),
      'week_end': weekEnd.toIso8601String(),
      'mood_headline': insights.moodHeadline,
      'emotion_narrative': insights.emotionNarrative,
      'top_keywords_json': jsonEncode(insights.topKeywords.map((k) => k.toJson()).toList()),
      'shining_ideas_json': jsonEncode(insights.shiningIdeas.map((i) => i.toJson()).toList()),
      'highlight_quote_json': jsonEncode(insights.highlightQuote.toJson()),
      'advice': insights.advice,
      'emotion_counts_json': jsonEncode({
        for (final e in emotionCounts.entries) e.key.id: e.value,
      }),
      // 後方互換用に単一の代表感情（最多カウントのタグ）も残しておく。
      'daily_emotions_json': jsonEncode(dailyEmotionCounts.map((dayCounts) {
        if (dayCounts.isEmpty) return null;
        return dayCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key.id;
      }).toList()),
      'daily_emotion_counts_json': jsonEncode(dailyEmotionCounts.map((dayCounts) {
        return {for (final e in dayCounts.entries) e.key.id: e.value};
      }).toList()),
      'diary_count': diaryCount,
      'idea_count': ideaCount,
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavedWeeklyReport.fromMap(Map<String, Object?> map) {
    final topKeywordsRaw = jsonDecode(map['top_keywords_json'] as String) as List;
    final shiningIdeasRaw = jsonDecode(map['shining_ideas_json'] as String) as List;
    final highlightQuoteRaw =
        jsonDecode(map['highlight_quote_json'] as String) as Map<String, dynamic>;
    final emotionCountsRaw =
        jsonDecode(map['emotion_counts_json'] as String) as Map<String, dynamic>;
    final dailyEmotionCountsColumn = map['daily_emotion_counts_json'] as String?;
    final List<Map<EmotionTag, int>> dailyEmotionCounts;
    if (dailyEmotionCountsColumn != null) {
      final raw = jsonDecode(dailyEmotionCountsColumn) as List;
      dailyEmotionCounts = raw.map((dayRaw) {
        final dayMap = Map<String, dynamic>.from(dayRaw as Map);
        return <EmotionTag, int>{
          for (final entry in dayMap.entries)
            if (EmotionTag.fromId(entry.key) != null)
              EmotionTag.fromId(entry.key)!: (entry.value as num).toInt(),
        };
      }).toList();
    } else {
      // このカラムが無い古い保存済みレポート（v17マイグレーション前）は、
      // 唯一持っていた単一の代表感情から簡易的に1件カウントを合成する
      // （全く出さないより、劣化版でも「今週のオーロラ」を表示する）。
      final dailyEmotionsRaw = jsonDecode(map['daily_emotions_json'] as String) as List;
      dailyEmotionCounts = dailyEmotionsRaw.map((id) {
        final tag = EmotionTag.fromId(id as String?);
        return tag == null ? <EmotionTag, int>{} : <EmotionTag, int>{tag: 1};
      }).toList();
    }

    return SavedWeeklyReport(
      id: map['id'] as int?,
      weekKey: map['week_key'] as String,
      weekStart: DateTime.parse(map['week_start'] as String),
      weekEnd: DateTime.parse(map['week_end'] as String),
      insights: WeeklyReportInsights(
        moodHeadline: map['mood_headline'] as String? ?? '',
        emotionNarrative: map['emotion_narrative'] as String? ?? '',
        topKeywords: topKeywordsRaw
            .map((e) => WeeklyReportKeyword.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        shiningIdeas: shiningIdeasRaw
            .map((e) => ShiningIdea.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        highlightQuote: HighlightQuote.fromJson(highlightQuoteRaw),
        advice: map['advice'] as String? ?? '',
      ),
      emotionCounts: {
        for (final entry in emotionCountsRaw.entries)
          if (EmotionTag.fromId(entry.key) != null)
            EmotionTag.fromId(entry.key)!: (entry.value as num).toInt(),
      },
      dailyEmotionCounts: dailyEmotionCounts,
      diaryCount: map['diary_count'] as int,
      ideaCount: map['idea_count'] as int,
      totalTasks: map['total_tasks'] as int,
      completedTasks: map['completed_tasks'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
