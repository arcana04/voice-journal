import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CustomWordsService {
  static const _customWordsPref = 'custom_words';

  Future<List<String>> getWords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customWordsPref);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<String>();
  }

  Future<void> setWords(List<String> words) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customWordsPref, jsonEncode(words));
  }
}
