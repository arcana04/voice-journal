import 'package:flutter/material.dart';

import '../config/theme_colors.dart';
import '../models/summary_level.dart';
import '../services/settings_service.dart';

class SettingsStore extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  SummaryLevel summaryLevel = SummaryLevel.preserve;
  bool darkMode = true;
  bool hasSeenOnboarding = false;
  int accentColorIndex = 0;
  bool _loaded = false;
  bool get loaded => _loaded;

  /// アプリ全体のテーマカラー([kAccentColorPresets]から選んだもの)。設定画面の
  /// 「テーマカラー」で変更でき、[ColorScheme.fromSeed]のシードとしても
  /// 使われる(録音ボタン・波形など、あえて素のブランドカラーを使う数箇所も
  /// この値を参照する)。
  Color get accentColor =>
      kAccentColorPresets[accentColorIndex.clamp(0, kAccentColorPresets.length - 1)];

  Future<void> load() async {
    summaryLevel = await _service.getSummaryLevel();
    darkMode = await _service.getDarkMode();
    hasSeenOnboarding = await _service.getHasSeenOnboarding();
    accentColorIndex = await _service.getAccentColorIndex();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setAccentColorIndex(int index) async {
    accentColorIndex = index;
    await _service.setAccentColorIndex(index);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    hasSeenOnboarding = true;
    await _service.setHasSeenOnboarding(true);
    notifyListeners();
  }

  Future<void> setSummaryLevel(SummaryLevel value) async {
    summaryLevel = value;
    await _service.setSummaryLevel(value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _service.setDarkMode(value);
    notifyListeners();
  }
}
