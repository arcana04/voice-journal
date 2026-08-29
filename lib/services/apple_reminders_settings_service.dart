import 'package:shared_preferences/shared_preferences.dart';

class AppleRemindersSettingsService {
  static const _listIdPref = 'apple_reminders_list_id';
  static const _listNamePref = 'apple_reminders_list_name';

  Future<String?> getListId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_listIdPref);
  }

  Future<String?> getListName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_listNamePref);
  }

  Future<void> setList(String? id, String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_listIdPref);
      await prefs.remove(_listNamePref);
    } else {
      await prefs.setString(_listIdPref, id);
      await prefs.setString(_listNamePref, name ?? '');
    }
  }
}
