class CustomWord {
  final String word;
  final String? description;

  CustomWord({required this.word, this.description});

  Map<String, dynamic> toJson() => {
        'word': word,
        if (description != null && description!.isNotEmpty) 'description': description,
      };

  factory CustomWord.fromJson(Map<String, dynamic> json) {
    final description = (json['description'] as String?)?.trim();
    return CustomWord(
      word: json['word'] as String,
      description: (description == null || description.isEmpty) ? null : description,
    );
  }
}
