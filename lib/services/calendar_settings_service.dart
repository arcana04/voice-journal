import 'package:shared_preferences/shared_preferences.dart';

class CalendarSettingsService {
  static const _calendarIdPref = 'calendar_integration_id';
  static const _calendarNamePref = 'calendar_integration_name';

  Future<String?> getCalendarId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_calendarIdPref);
  }

  Future<String?> getCalendarName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_calendarNamePref);
  }

  Future<void> setCalendar(String? id, String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_calendarIdPref);
      await prefs.remove(_calendarNamePref);
    } else {
      await prefs.setString(_calendarIdPref, id);
      await prefs.setString(_calendarNamePref, name ?? '');
    }
  }
}
