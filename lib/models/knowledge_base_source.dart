/// 相談機能（第二の脳）の回答が実際にどの記録を参照したかを示す1件分。
/// バックエンドの埋め込み検索で選ばれた上位K件をそのまま返しているため、
/// AIの自己申告ではなく実際にコンテキストへ渡された記録と一致する。
/// [entryId]は`JournalEntry.remoteId`と突き合わせて元の記録を開くのに使う。
class KnowledgeBaseSource {
  final String entryId;
  final DateTime? date;
  final String excerpt;

  const KnowledgeBaseSource({
    required this.entryId,
    required this.date,
    required this.excerpt,
  });

  factory KnowledgeBaseSource.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    return KnowledgeBaseSource(
      entryId: json['id'] as String? ?? '',
      date: dateStr != null && dateStr.isNotEmpty
          ? DateTime.tryParse(dateStr)
          : null,
      excerpt: json['excerpt'] as String? ?? '',
    );
  }
}

/// askKnowledgeBaseの戻り値。[sources]は同期済みユーザーの埋め込み検索が
/// 効いた場合のみ入り、未同期ユーザーの全件詰め込みフォールバック時は空になる。
class KnowledgeBaseAnswer {
  final String answer;
  final List<KnowledgeBaseSource> sources;

  const KnowledgeBaseAnswer({required this.answer, required this.sources});
}
