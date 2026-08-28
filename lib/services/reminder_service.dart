import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/l10n_utils.dart';
import 'db_service.dart';

const String _kWeeklyReportPayload = 'weekly_report';
const int _kWeeklyReportNotificationId = 900000;

/// 時刻付きのToDoに対するローカル通知（リマインダー）を管理する。
///
/// 通知時刻は端末の実際のタイムゾーン（現地時刻）のウォールクロック時刻として
/// スケジュールする——海外渡航中など、端末のOSタイムゾーンが変わればそれに
/// 追従する。タイムゾーンの検出に失敗した場合のみAsia/Tokyoにフォールバックする。
class ReminderService {
  ReminderService._internal();
  static final ReminderService instance = ReminderService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _pluginInitialized = false;

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
    await _initializePluginOnly();
    _initialized = true;

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

  /// [rescheduleAllPending]をWorkManagerのバックグラウンドisolateから呼ぶ際に使う。
  /// フォアグラウンドのActivityが存在しない状態で通知許可をリクエストすると
  /// （[initialize]内の`requestNotificationsPermission`）NullPointerExceptionで
  /// タスクが失敗するため、プラグインの初期化のみ行い許可リクエストは行わない。
  Future<void> _initializePluginOnly() async {
    if (_pluginInitialized) return;
    _pluginInitialized = true;

    tz_data.initializeTimeZones();
    try {
      final deviceTimezone = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(deviceTimezone));
    } catch (e) {
      debugPrint('failed to resolve device timezone, defaulting to Asia/Tokyo: $e');
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    }

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

  /// DBに保存済みの未完了タスクを読み直し、通知が消えていても再スケジュールする。
  /// アプリ起動時（[JournalStore.load]）に加えて、端末再起動後もWorkManager経由の
  /// バックグラウンドタスク（[reminderCallbackDispatcher]）から呼ばれる — Android の
  /// AlarmManagerベースの通知はOS再起動で消えるため、アプリを開かなくても復元できる
  /// ようにするための保険。
  Future<void> rescheduleAllPending() async {
    await _initializePluginOnly();
    final entries = await DbService.instance.fetchEntries();
    for (final entry in entries) {
      for (final task in entry.tasks) {
        if (!task.done && task.id != null && task.notifyAt != null) {
          await scheduleTaskReminder(
            taskId: task.id!,
            title: task.title,
            scheduledAt: task.notifyAt!,
          );
        }
      }
    }
  }

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
