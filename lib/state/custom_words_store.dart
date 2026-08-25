import 'package:flutter/foundation.dart';

import '../services/custom_words_service.dart';

class CustomWordsStore extends ChangeNotifier {
  final CustomWordsService _service = CustomWordsService();

  List<String> words = [];
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    words = await _service.getWords();
    _loaded = true;
    notifyListeners();
  }

  Future<void> addWord(String word) async {
    final trimmed = word.trim();
    if (trimmed.isEmpty || words.contains(trimmed)) return;
    words = [...words, trimmed];
    await _service.setWords(words);
    notifyListeners();
  }

  Future<void> removeWord(String word) async {
    words = words.where((w) => w != word).toList();
    await _service.setWords(words);
    notifyListeners();
  }
}
