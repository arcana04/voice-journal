import 'package:shared_preferences/shared_preferences.dart';

import '../models/summary_level.dart';

class SettingsService {
  static const _summaryLevelPref = 'summary_level';

  Future<SummaryLevel> getSummaryLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return SummaryLevelX.fromWireValue(prefs.getString(_summaryLevelPref));
  }

  Future<void> setSummaryLevel(SummaryLevel value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_summaryLevelPref, value.wireValue);
  }
}
