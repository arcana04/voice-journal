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

  /// アカウント切り替え/アカウント削除で呼ぶ。[DbService.wipeAllLocalData]は
  /// SQLiteしか消さず、この用語集はSharedPreferencesに保存しているため対象
  /// 外だった——前のアカウントの登録語（人名などを含みうる）が新しい
  /// アカウントに引き継がれ、そのまま文字起こしのヒントとしてAIに送られ
  /// 続けてしまっていた（端末を共有した場合のクロスアカウント漏えい）。
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customWordsPref);
  }
}
