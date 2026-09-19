import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

/// device_calendarの呼び出しが失敗したことを表す例外(権限が取り消された、
/// 対象のカレンダー/予定がOS側で操作できない等)。device_calendarパッケージ
/// 自体は失敗を例外ではなく`Result.errors`(データはnull/空のまま)として返す
/// 設計のため、呼び出し元のtry/catchが確実に拾えるよう、ここで明示的に
/// 例外へ変換する——「取得・操作できたが対象が0件/該当なし」という正当な
/// 結果と、「取得・操作そのものに失敗した」を混同しないための境界。
class CalendarServiceException implements Exception {
  final String message;
  CalendarServiceException(this.message);

  @override
  String toString() => 'CalendarServiceException: $message';
}

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

  /// 書き込み可能なカレンダーの一覧を返す。取得そのものが失敗した場合（権限が
  /// 取り消された、OS側のエラー等）は[CalendarServiceException]を投げる——
  /// 「正常に取得できたが対象カレンダーが1つも無い」という正当な空リストと、
  /// 呼び出し元(JournalStore._calendarStillExists等)が区別できるようにする。
  Future<List<Calendar>> retrieveCalendars() async {
    final result = await _plugin.retrieveCalendars();
    if (result.hasErrors || result.data == null) {
      throw CalendarServiceException(
        result.errors.isEmpty
            ? 'retrieveCalendars returned no data'
            : result.errors.map((e) => e.errorMessage).join('; '),
      );
    }
    return result.data!.where((c) => c.isReadOnly != true).toList();
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
    // device_calendarは権限取り消し等の失敗を例外ではなく`Result.errors`
    // (dataはnullのまま)として返すため、ここでチェックせずdataだけを見ると
    // 「予定を作成/更新できなかった」ことが「連携オフ・予定なし」と同じ
    // 見た目(null)になり、呼び出し元(JournalStore._syncTaskCalendarEvent)の
    // try/catchが失敗を検知できず、既存の予定IDを静かに手放してしまう。
    if (result == null || result.hasErrors) {
      throw CalendarServiceException(
        (result?.errors ?? const <ResultError>[]).isEmpty
            ? 'createOrUpdateEvent returned no data'
            : result!.errors.map((e) => e.errorMessage).join('; '),
      );
    }
    return result.data;
  }

  /// 予定を削除する。削除そのものが失敗した場合（権限が取り消された等）は
  /// [CalendarServiceException]を投げる——[upsertEvent]と同じ理由で、
  /// 呼び出し元が「削除に失敗した」を検知できるようにする。
  Future<void> deleteEvent(String calendarId, String eventId) async {
    final result = await _plugin.deleteEvent(calendarId, eventId);
    if (result.hasErrors) {
      throw CalendarServiceException(
        result.errors.map((e) => e.errorMessage).join('; '),
      );
    }
  }
}
