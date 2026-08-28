import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/l10n_utils.dart';

const String _kWeeklyReportPayload = 'weekly_report';
const int _kWeeklyReportNotificationId = 900000;

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

  /// 週刊レポート通知がタップされるたびにインクリメントされる。[RootScreen]が
  /// これを監視し、週刊レポート画面を開く。
  final ValueNotifier<int> weeklyReportRequests = ValueNotifier(0);

  void _handleNotificationTap(String? payload) {
    if (payload == _kWeeklyReportPayload) {
      weeklyReportRequests.value++;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) =>
          _handleNotificationTap(response.payload),
    );

    // アプリが終了していた状態から通知タップで起動された場合（コールドスタート）。
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _handleNotificationTap(launchDetails?.notificationResponse?.payload);
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
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

  /// 毎週日曜20:00（JST）に週刊脳内レポートの完成を知らせる通知を（再）スケジュール
  /// する。既存のスケジュールがあれば同じ通知IDで上書きされる。
  Future<void> scheduleWeeklyReportNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    while (scheduled.weekday != DateTime.sunday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final l10n = currentLocalizations();
    await _plugin.zonedSchedule(
      _kWeeklyReportNotificationId,
      l10n.weeklyReportNotificationTitle,
      l10n.weeklyReportNotificationBody,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_report',
          l10n.weeklyReportNotificationChannelName,
          channelDescription: l10n.weeklyReportNotificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: _kWeeklyReportPayload,
    );
  }

  Future<void> cancelWeeklyReportNotification() =>
      _plugin.cancel(_kWeeklyReportNotificationId);

  /// 通知が現在許可されているかどうか。プラットフォームが判定できない場合はtrue扱い。
  Future<bool> hasNotificationPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final options = await ios.checkPermissions();
      return options?.isEnabled ?? false;
    }
    return true;
  }

  /// 通知の許可をあらためて要求する。一度拒否された後はOSがダイアログを
  /// 出さないことが多く、その場合は呼び出し側でOS設定画面への導線を出す。
  Future<bool> requestNotificationPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }
}
