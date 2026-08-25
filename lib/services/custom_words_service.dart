import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_word.dart';

class CustomWordsService {
  static const _customWordsPref = 'custom_words';

  Future<List<CustomWord>> getWords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customWordsPref);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) {
      if (e is String) return CustomWord(word: e);
      return CustomWord.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();
  }

  Future<void> setWords(List<CustomWord> words) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customWordsPref, jsonEncode(words.map((w) => w.toJson()).toList()));
  }
}
