import 'package:flutter/foundation.dart';

import '../services/settings_service.dart';

class SettingsStore extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  bool darkMode = false;
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    darkMode = await _service.getDarkMode();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _service.setDarkMode(value);
    notifyListeners();
  }
}
