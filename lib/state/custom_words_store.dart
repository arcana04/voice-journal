import 'package:flutter/foundation.dart';

import '../models/custom_word.dart';
import '../services/custom_words_service.dart';

class CustomWordsStore extends ChangeNotifier {
  final CustomWordsService _service = CustomWordsService();

  List<CustomWord> words = [];
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    words = await _service.getWords();
    _loaded = true;
    notifyListeners();
  }

  Future<void> addWord(String word, {String? description}) async {
    final trimmed = word.trim();
    if (trimmed.isEmpty || words.any((w) => w.word == trimmed)) return;
    words = [...words, CustomWord(word: trimmed, description: description?.trim())];
    await _service.setWords(words);
    notifyListeners();
  }

  Future<void> removeWord(CustomWord word) async {
    words = words.where((w) => w.word != word.word).toList();
    await _service.setWords(words);
    notifyListeners();
  }
}
