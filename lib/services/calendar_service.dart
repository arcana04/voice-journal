import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

/// 端末のカレンダー（iOS標準カレンダー・Googleカレンダーなど、端末側に登録済みの
/// カレンダーアカウント）と連携するためのラッパー。EventKit（iOS）/
/// カレンダープロバイダ（Android）にOS標準のプラグイン経由でアクセスする。
class CalendarService {
  static final CalendarService instance = CalendarService._internal();
  CalendarService._internal();

  // shouldInitTimezone: falseにしないと、このプラグインが内部で
  // tz.initializeTimeZones()を再実行し、その副作用でtz.localがUTCに
  // リセットされてしまう（timezoneパッケージのinitializeDatabase()は常に
  // _local = UTCで終わるため）。ReminderService.initialize()が既に
  // Asia/Tokyoを設定・データベース初期化済みなので、ここでは再初期化しない。
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin(
    shouldInitTimezone: false,
  );

  Future<bool> hasPermissions() async {
    final result = await _plugin.hasPermissions();
    return result.data ?? false;
  }

  Future<bool> requestPermissions() async {
    final result = await _plugin.requestPermissions();
    return result.data ?? false;
  }

  /// 書き込み可能なカレンダーの一覧を返す。
  Future<List<Calendar>> retrieveCalendars() async {
    final result = await _plugin.retrieveCalendars();
    final calendars = result.data ?? const <Calendar>[];
    return calendars.where((c) => c.isReadOnly != true).toList();
  }

  /// [calendarId]に予定を作成・更新する。既存の[eventId]を渡すとその予定を更新する。
  /// [end]を渡せばその日時を終了時刻に使い、省略時は[start]の1時間後をデフォルトにする。
  /// [allDay]がtrueの場合、時刻を無視して[start]（〜[end]）の日付だけを終日イベントとして登録する。
  /// 成功すればイベントIDを返す。
  Future<String?> upsertEvent({
    required String calendarId,
    String? eventId,
    required String title,
    required DateTime start,
    DateTime? end,
    bool allDay = false,
  }) async {
    final location = tz.local;
    DateTime effectiveStart = start;
    DateTime effectiveEnd = end ?? start.add(const Duration(hours: 1));
    if (allDay) {
      effectiveStart = DateTime(start.year, start.month, start.day);
      final endDateOnly = end != null
          ? DateTime(end.year, end.month, end.day)
          : effectiveStart;
      // device_calendarの終日イベントは終了日時を「翌日の0時」として扱う
      effectiveEnd = endDateOnly.add(const Duration(days: 1));
    }
    final event = Event(
      calendarId,
      eventId: eventId,
      title: title,
      start: tz.TZDateTime.from(effectiveStart, location),
      end: tz.TZDateTime.from(effectiveEnd, location),
      allDay: allDay,
    );
    final result = await _plugin.createOrUpdateEvent(event);
    return result?.data;
  }

  Future<void> deleteEvent(String calendarId, String eventId) async {
    await _plugin.deleteEvent(calendarId, eventId);
  }
}
