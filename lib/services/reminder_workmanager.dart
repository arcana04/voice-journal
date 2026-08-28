import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'reminder_service.dart';

/// 端末再起動後、アプリを開かなくてもタスクリマインダーの通知が復元されるようにする
/// ためのバックグラウンドタスク。AndroidのWorkManagerは自身のスケジュールを端末再起動
/// をまたいで保持する（flutter_local_notificationsが使うAlarmManagerは保持しない）ため、
/// 定期実行タスクとして登録しておくことで、再起動後に最短15分（Android側の最小間隔）
/// 以内に通知が再登録される。
const String kReminderResyncTaskName = 'reminder_resync';
const String kReminderResyncUniqueName = 'reminder_resync_periodic';

@pragma('vm:entry-point')
void reminderCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (task == kReminderResyncTaskName) {
      // rescheduleAllPendingが必要なプラグイン初期化を内部で行う。initialize()は
      // 通知許可のリクエストを含み、フォアグラウンドActivityが無いこの
      // バックグラウンドisolateから呼ぶとクラッシュするため、ここでは呼ばない。
      await ReminderService.instance.rescheduleAllPending();
    }
    return true;
  });
}
