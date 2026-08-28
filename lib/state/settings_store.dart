import 'package:flutter/foundation.dart';

import '../models/diary_style.dart';
import '../models/summary_level.dart';
import '../services/settings_service.dart';

class SettingsStore extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  SummaryLevel summaryLevel = SummaryLevel.preserve;
  DiaryStyle diaryStyle = DiaryStyle.standard;
  bool darkMode = true;
  bool hasSeenOnboarding = false;
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    summaryLevel = await _service.getSummaryLevel();
    diaryStyle = await _service.getDiaryStyle();
    darkMode = await _service.getDarkMode();
    hasSeenOnboarding = await _service.getHasSeenOnboarding();
    _loaded = true;
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

  Future<void> setDiaryStyle(DiaryStyle value) async {
    diaryStyle = value;
    await _service.setDiaryStyle(value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _service.setDarkMode(value);
    notifyListeners();
  }
}
