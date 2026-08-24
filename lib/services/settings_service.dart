import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _darkModePref = 'dark_mode';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModePref) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModePref, value);
  }
}
