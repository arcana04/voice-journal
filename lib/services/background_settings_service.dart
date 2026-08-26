import 'package:shared_preferences/shared_preferences.dart';

class BackgroundSettingsService {
  static const _backgroundIdPref = 'app_background_id';

  Future<String?> getBackgroundId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundIdPref);
  }

  Future<void> setBackgroundId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundIdPref, id);
  }
}
