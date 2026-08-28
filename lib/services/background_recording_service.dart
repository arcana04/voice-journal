import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../l10n/l10n_utils.dart';

/// 録音中に使うフォアグラウンドサービスのタスクハンドラ。実際の録音処理は
/// メインisolateの[RecorderService]がそのまま行うため、ここでは何もしない
/// ——このサービスの役割はプロセスをフォアグラウンド状態に保ち、Androidが
/// バックグラウンド/画面オフでのマイクアクセスを許可し続けるようにすること。
@pragma('vm:entry-point')
void backgroundRecordingTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_BackgroundRecordingTaskHandler());
}

class _BackgroundRecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

/// 録音中、Androidでアプリがバックグラウンドに回っても/画面がオフになっても
/// マイクアクセスを維持するためのフォアグラウンドサービス。
///
/// iOSは`Info.plist`の`UIBackgroundModes`(audio)だけで背景録音を継続できる
/// （録音中のAVAudioSessionがアクティブである限りOSがプロセスを生かし続ける）
/// ため、このサービスはAndroidでのみ使用する。
class BackgroundRecordingService {
  static bool _initialized = false;

  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        // チャンネルの重要度等は初回作成時にしか反映されないため、既存インス
        // トールでLOW重要度のまま残らないよう新しいチャンネルIDを使う。
        channelId: 'background_recording_v2',
        channelName: currentLocalizations().backgroundRecordingChannelName,
        channelDescription:
            currentLocalizations().backgroundRecordingChannelDescription,
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    _ensureInitialized();
    if (await FlutterForegroundTask.isRunningService) return;

    // フォアグラウンドサービスの通知を表示するには許可が必要
    // （Android 13+）。未許可ならここでリクエストする。
    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    final l10n = currentLocalizations();
    final result = await FlutterForegroundTask.startService(
      serviceId: 501,
      notificationTitle: l10n.backgroundRecordingNotificationTitle,
      notificationText: l10n.backgroundRecordingNotificationText,
      callback: backgroundRecordingTaskCallback,
    );
    if (result is ServiceRequestFailure) {
      // 通知が拒否されている等でサービスを開始できなくても、フォアグラウンド
      // （アプリ表示中）での録音自体は通常どおり続けられるので致命的ではない。
      debugPrint('BackgroundRecordingService.start failed: ${result.error}');
    }
  }

  /// 録音中の通知本文を更新する（経過時間の表示などに使う）。サービスが
  /// 動いていない場合は何もしない。
  static Future<void> updateNotificationText(String text) async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.updateService(notificationText: text);
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}
