import 'package:flutter/foundation.dart';

import '../models/summary_level.dart';
import '../services/settings_service.dart';

class SettingsStore extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  bool darkMode = false;
  SummaryLevel summaryLevel = SummaryLevel.preserve;
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    darkMode = await _service.getDarkMode();
    summaryLevel = await _service.getSummaryLevel();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _service.setDarkMode(value);
    notifyListeners();
  }

  Future<void> setSummaryLevel(SummaryLevel value) async {
    summaryLevel = value;
    await _service.setSummaryLevel(value);
    notifyListeners();
  }
}
