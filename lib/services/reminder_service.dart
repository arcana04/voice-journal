import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/l10n_utils.dart';

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

    final l10n = currentLocalizations();
    await _plugin.zonedSchedule(
      taskId,
      l10n.reminderNotificationTitle,
      title,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          l10n.reminderNotificationChannelName,
          channelDescription: l10n.reminderNotificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTaskReminder(int taskId) => _plugin.cancel(taskId);

  /// 通知が現在許可されているかどうか。プラットフォームが判定できない場合はtrue扱い。
  Future<bool> hasNotificationPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final options = await ios.checkPermissions();
      return options?.isEnabled ?? false;
    }
    return true;
  }

  /// 通知の許可をあらためて要求する。一度拒否された後はOSがダイアログを
  /// 出さないことが多く、その場合は呼び出し側でOS設定画面への導線を出す。
  Future<bool> requestNotificationPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return true;
  }
}
