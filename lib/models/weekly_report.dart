import 'dart:convert';

import 'emotion_tag.dart';

/// 週の中で実際に感情タグが記録された1件（エントリ1件）の記録時刻と具体的な
/// 感情タグ。メンタルウェーブは日ごとの集計ではなく、この実際の記録時刻を
/// もとに波を描き、タップ時にタグ名まで表示する。[textLength]はその記録の
/// 本文の文字数（AIの新規判定は挟まず、既存のテキストから機械的に求める）で、
/// 過去に保存されたレポートとの互換性のため保持している。
class MoodMoment {
  final DateTime time;
  final EmotionTag tag;
  final int textLength;

  const MoodMoment({required this.time, required this.tag, this.textLength = 0});

  factory MoodMoment.fromJson(Map<String, dynamic> json) {
    final textLength = (json['l'] as num?)?.toInt() ?? 0;
    final tag = EmotionTag.fromId(json['e'] as String?);
    if (tag != null) {
      return MoodMoment(
        time: DateTime.parse(json['t'] as String),
        tag: tag,
        textLength: textLength,
      );
    }
    // 後方互換: カテゴリのみ保存していた旧形式は、そのカテゴリの代表タグに
    // フォールバックする（開発中のみ存在した形式のため簡易対応で十分）。
    final category = EmotionCategory.values.firstWhere(
      (c) => c.name == json['c'],
      orElse: () => EmotionCategory.fine,
    );
    final fallbackTag = EmotionTag.values
        .firstWhere((t) => t.category == category, orElse: () => EmotionTag.neutral);
    return MoodMoment(
      time: DateTime.parse(json['t'] as String),
      tag: fallbackTag,
      textLength: textLength,
    );
  }

  Map<String, dynamic> toJson() => {'t': time.toIso8601String(), 'e': tag.id, 'l': textLength};
}

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

/// 「脳内マップ」の1バブルが持つ、実際に紐づいた記録1件分。
class BrainMapMatch {
  final DateTime time;
  final String snippet;
  final EmotionTag? emotion;

  const BrainMapMatch({required this.time, required this.snippet, this.emotion});

  factory BrainMapMatch.fromJson(Map<String, dynamic> json) {
    return BrainMapMatch(
      time: DateTime.parse(json['t'] as String),
      snippet: json['s'] as String? ?? '',
      emotion: EmotionTag.fromId(json['e'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        't': time.toIso8601String(),
        's': snippet,
        if (emotion != null) 'e': emotion!.id,
      };
}

/// 「脳内マップ」(Word Cloudのバブル)の1件。[WeeklyReportInsights.topKeywords]
/// (AIが抽出したキーワード)と、その週の実際の記録本文を突き合わせてローカルで
/// 計算する(AIの判断はキーワード抽出のみ、紐づく感情の集計・色のブレンドは
/// ローカルDBの値から計算する、という他の集計値と同じ役割分担)。
/// 履歴閲覧時にも同じ結果を再現できるよう、計算結果をそのまま保存する。
class BrainMapBubble {
  final String keyword;
  /// バブルの大きさに使う重み(そのキーワードが実際に見つかった記録の件数)。
  /// AIの自己申告のcountではなく、ローカルでの実際のマッチ件数を使う。
  final int weight;
  /// 紐づく感情をブレンドした色(ARGB32)。[emotion_color_blend.dart]で計算済み。
  final int colorValue;
  final List<BrainMapMatch> matches;

  const BrainMapBubble({
    required this.keyword,
    required this.weight,
    required this.colorValue,
    required this.matches,
  });

  factory BrainMapBubble.fromJson(Map<String, dynamic> json) {
    return BrainMapBubble(
      keyword: json['k'] as String? ?? '',
      weight: (json['w'] as num?)?.toInt() ?? 0,
      colorValue: (json['c'] as num?)?.toInt() ?? 0xFF2A3040,
      matches: (json['m'] as List? ?? [])
          .map((e) => BrainMapMatch.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'k': keyword,
        'w': weight,
        'c': colorValue,
        'm': matches.map((e) => e.toJson()).toList(),
      };
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
  final String weeklyLetter;

  WeeklyReportInsights({
    required this.moodHeadline,
    required this.emotionNarrative,
    required this.topKeywords,
    required this.shiningIdeas,
    required this.highlightQuote,
    required this.advice,
    required this.weeklyLetter,
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
      weeklyLetter: (json['weekly_letter'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mood_headline': moodHeadline,
        'emotion_narrative': emotionNarrative,
        'top_keywords': topKeywords.map((k) => k.toJson()).toList(),
        'shining_ideas': shiningIdeas.map((i) => i.toJson()).toList(),
        'highlight_quote': highlightQuote.toJson(),
        'advice': advice,
        'weekly_letter': weeklyLetter,
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
  /// メンタルウェーブ用の、実際の記録時刻ごとの感情カテゴリ一覧。
  final List<MoodMoment> moodMoments;
  /// 「脳内マップ」のバブル一覧。生成時にその週の実際の記録と突き合わせて
  /// 計算済みのものをそのまま保存する(履歴閲覧時は元の記録が残っていない
  /// 週もあるため、都度再計算はせずスナップショットをそのまま使う)。
  final List<BrainMapBubble> brainMapBubbles;
  final int diaryCount;
  final int ideaCount;
  final int totalTasks;
  final int completedTasks;
  final DateTime createdAt;
  /// その週に実在した記録(エントリ)のidをソートして連結した文字列。件数
  /// (diaryCount等)だけでは「記録を削除して別の記録を同数だけ作り直した」
  /// ケースを見分けられず、中身が変わったのにキャッシュを再利用してしまう
  /// （AIが生成したキーワード等が実際の記録と食い違って表示される）ため、
  /// この署名も一致した場合のみキャッシュを再利用する。
  final String entryIdsSignature;

  SavedWeeklyReport({
    this.id,
    required this.weekKey,
    required this.weekStart,
    required this.weekEnd,
    required this.insights,
    required this.emotionCounts,
    required this.dailyEmotionCounts,
    required this.moodMoments,
    required this.brainMapBubbles,
    required this.diaryCount,
    required this.ideaCount,
    required this.totalTasks,
    required this.completedTasks,
    required this.createdAt,
    this.entryIdsSignature = '',
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
      'weekly_letter': insights.weeklyLetter,
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
      'mood_moments_json': jsonEncode(moodMoments.map((m) => m.toJson()).toList()),
      'brain_map_json': jsonEncode(brainMapBubbles.map((b) => b.toJson()).toList()),
      'diary_count': diaryCount,
      'idea_count': ideaCount,
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'created_at': createdAt.toIso8601String(),
      'entry_ids_signature': entryIdsSignature,
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
    final moodMomentsColumn = map['mood_moments_json'] as String?;
    final moodMoments = moodMomentsColumn == null
        ? const <MoodMoment>[]
        : (jsonDecode(moodMomentsColumn) as List)
            .map((e) => MoodMoment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    final brainMapColumn = map['brain_map_json'] as String?;
    final brainMapBubbles = brainMapColumn == null
        ? const <BrainMapBubble>[]
        : (jsonDecode(brainMapColumn) as List)
            .map((e) => BrainMapBubble.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

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
        weeklyLetter: map['weekly_letter'] as String? ?? '',
      ),
      emotionCounts: {
        for (final entry in emotionCountsRaw.entries)
          if (EmotionTag.fromId(entry.key) != null)
            EmotionTag.fromId(entry.key)!: (entry.value as num).toInt(),
      },
      dailyEmotionCounts: dailyEmotionCounts,
      moodMoments: moodMoments,
      brainMapBubbles: brainMapBubbles,
      diaryCount: map['diary_count'] as int,
      ideaCount: map['idea_count'] as int,
      totalTasks: map['total_tasks'] as int,
      completedTasks: map['completed_tasks'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      entryIdsSignature: map['entry_ids_signature'] as String? ?? '',
    );
  }
}
