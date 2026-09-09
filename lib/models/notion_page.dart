/// Notion連携の接続先候補として一覧表示する、インテグレーションに共有済みのページ。
class NotionPage {
  final String id;
  final String title;

  const NotionPage({required this.id, required this.title});

  factory NotionPage.fromJson(Map<String, dynamic> json) {
    return NotionPage(
      id: json['id'] as String? ?? '',
      title: (json['title'] as String? ?? '').trim(),
    );
  }
}
