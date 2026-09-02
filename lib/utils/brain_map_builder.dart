import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';
import '../models/weekly_report.dart';
import 'emotion_color_blend.dart';

/// 週刊脳内レポートの「脳内マップ」用データを組み立てる。AIが抽出した
/// キーワード([topKeywords])は文字列と概算件数だけを持っているので、実際の
/// 週の記録本文と照合して、本当の出現件数・紐づく記録・感情のブレンド色を
/// ローカルで計算する(AIの役割はキーワード抽出のみ、集計はローカルDBの値
/// から行うという他の指標と同じ役割分担)。
/// [needle]自身に加えて、日本語のい形容詞の活用差(例:「楽しい」⇄「楽しかった」
/// 「楽しくない」)を吸収するための語幹も候補として返す。AIが抽出するキーワードは
/// 辞書形（言い切りの形）になりがちな一方、実際の記録文では活用した形で書かれて
/// いることが多く、そのままの文字列一致だとバブルが消えてしまうため。
Iterable<String> _matchCandidates(String needle) sync* {
  yield needle;
  if (needle.length > 1 && needle.endsWith('い')) {
    yield needle.substring(0, needle.length - 1);
  }
}

List<BrainMapBubble> buildBrainMapBubbles(
  List<JournalEntry> entries,
  List<WeeklyReportKeyword> topKeywords, {
  int maxBubbles = 10,
  int maxSnippetLength = 40,
}) {
  final bubbles = <BrainMapBubble>[];

  for (final topKeyword in topKeywords) {
    final needle = topKeyword.keyword.trim().toLowerCase();
    if (needle.isEmpty) continue;
    final candidates = _matchCandidates(needle).toList();

    final matches = <BrainMapMatch>[];
    final emotionCounts = <EmotionTag, int>{};

    for (final entry in entries) {
      String? snippetSource;
      for (final note in entry.notes) {
        final haystack = '${note.title ?? ''} ${note.content}'.toLowerCase();
        if (candidates.any(haystack.contains)) {
          snippetSource = note.content;
          break;
        }
      }
      if (snippetSource == null) {
        for (final task in entry.tasks) {
          final haystack = task.title.toLowerCase();
          if (candidates.any(haystack.contains)) {
            snippetSource = task.title;
            break;
          }
        }
      }
      if (snippetSource == null) continue;
      matches.add(BrainMapMatch(
        time: entry.createdAt,
        snippet: snippetSource.length > maxSnippetLength
            ? '${snippetSource.substring(0, maxSnippetLength)}…'
            : snippetSource,
        emotion: entry.emotion,
      ));
      if (entry.emotion != null) {
        emotionCounts[entry.emotion!] = (emotionCounts[entry.emotion!] ?? 0) + 1;
      }
    }

    if (matches.isEmpty) continue;
    matches.sort((a, b) => b.time.compareTo(a.time));
    bubbles.add(BrainMapBubble(
      keyword: topKeyword.keyword.trim(),
      weight: matches.length,
      colorValue: blendEmotionColors(emotionCounts).toARGB32(),
      matches: matches,
    ));
  }

  bubbles.sort((a, b) => b.weight.compareTo(a.weight));
  return bubbles.take(maxBubbles).toList();
}
