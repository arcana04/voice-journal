import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 時刻付きのToDoに対するローカル通知（リマインダー）を管理する。
///
/// タスクの reminder_at はサーバー側でJST（Asia/Tokyo）として計算されるため、
/// 端末のOSタイムゾーン設定に関わらずAsia/Tokyoのウォールクロック時刻として
/// スケジュールする。
class ReminderService {
  ReminderService._internal();
  static final ReminderService instance = ReminderService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required DateTime scheduledAt,
  }) async {
    final scheduled = tz.TZDateTime(
      tz.local,
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
      scheduledAt.hour,
      scheduledAt.minute,
    );
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      taskId,
      'リマインダー',
      title,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'ToDoリマインダー',
          channelDescription: '独り言から作られたToDoの時刻リマインダー',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTaskReminder(int taskId) => _plugin.cancel(taskId);
}
