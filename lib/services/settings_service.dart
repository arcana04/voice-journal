import 'package:shared_preferences/shared_preferences.dart';

import '../models/summary_level.dart';

class SettingsService {
  static const _summaryLevelPref = 'summary_level';
  static const _darkModePref = 'dark_mode';

  Future<SummaryLevel> getSummaryLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return SummaryLevelX.fromWireValue(prefs.getString(_summaryLevelPref));
  }

  Future<void> setSummaryLevel(SummaryLevel value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_summaryLevelPref, value.wireValue);
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModePref) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModePref, value);
  }
}
