import 'package:shared_preferences/shared_preferences.dart';

import '../models/diary_style.dart';
import '../models/summary_level.dart';

class SettingsService {
  static const _summaryLevelPref = 'summary_level';
  static const _diaryStylePref = 'diary_style';
  static const _darkModePref = 'dark_mode';
  static const _hasSeenOnboardingPref = 'has_seen_onboarding';

  Future<SummaryLevel> getSummaryLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return SummaryLevelX.fromWireValue(prefs.getString(_summaryLevelPref));
  }

  Future<void> setSummaryLevel(SummaryLevel value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_summaryLevelPref, value.wireValue);
  }

  Future<DiaryStyle> getDiaryStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return DiaryStyleX.fromWireValue(prefs.getString(_diaryStylePref));
  }

  Future<void> setDiaryStyle(DiaryStyle value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_diaryStylePref, value.wireValue);
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModePref) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModePref, value);
  }

  Future<bool> getHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingPref) ?? false;
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingPref, value);
  }
}
