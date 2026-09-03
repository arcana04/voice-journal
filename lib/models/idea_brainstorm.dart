/// 「アイデアを深掘り」機能がAIから返す、1つの切り口。
class IdeaAngle {
  final String title;
  final String description;

  const IdeaAngle({required this.title, required this.description});

  factory IdeaAngle.fromJson(Map<String, dynamic> json) {
    return IdeaAngle(
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
    );
  }
}
