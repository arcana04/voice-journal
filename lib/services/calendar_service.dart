import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

/// 端末のカレンダー（iOS標準カレンダー・Googleカレンダーなど、端末側に登録済みの
/// カレンダーアカウント）と連携するためのラッパー。EventKit（iOS）/
/// カレンダープロバイダ（Android）にOS標準のプラグイン経由でアクセスする。
class CalendarService {
  static final CalendarService instance = CalendarService._internal();
  CalendarService._internal();

  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

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
  /// 成功すればイベントIDを返す。
  Future<String?> upsertEvent({
    required String calendarId,
    String? eventId,
    required String title,
    required DateTime start,
    DateTime? end,
  }) async {
    final location = tz.local;
    final event = Event(
      calendarId,
      eventId: eventId,
      title: title,
      start: tz.TZDateTime.from(start, location),
      end: tz.TZDateTime.from(
        end ?? start.add(const Duration(hours: 1)),
        location,
      ),
    );
    final result = await _plugin.createOrUpdateEvent(event);
    return result?.data;
  }

  Future<void> deleteEvent(String calendarId, String eventId) async {
    await _plugin.deleteEvent(calendarId, eventId);
  }
}
