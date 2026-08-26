import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';

import '../services/calendar_service.dart';
import '../services/calendar_settings_service.dart';

/// 「連携」設定画面と、選択中のカレンダー連携状態を保持するストア。
class CalendarStore extends ChangeNotifier {
  final CalendarService _calendar = CalendarService.instance;
  final CalendarSettingsService _service = CalendarSettingsService();

  String? selectedCalendarId;
  String? selectedCalendarName;
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    selectedCalendarId = await _service.getCalendarId();
    selectedCalendarName = await _service.getCalendarName();
    _loaded = true;
    notifyListeners();
  }

  /// 権限をリクエストし、端末のカレンダー一覧を取得する。
  /// 権限が得られなければ`granted: false`、得られたがカレンダーが
  /// 1件もなければ`granted: true`・空リストを返す。
  Future<({bool granted, List<Calendar> calendars})> requestCalendars() async {
    final granted = await _calendar.requestPermissions();
    if (!granted) return (granted: false, calendars: const <Calendar>[]);
    final calendars = await _calendar.retrieveCalendars();
    return (granted: true, calendars: calendars);
  }

  Future<void> setCalendar(Calendar? calendar) async {
    selectedCalendarId = calendar?.id;
    selectedCalendarName = calendar?.name;
    await _service.setCalendar(calendar?.id, calendar?.name);
    notifyListeners();
  }
}
