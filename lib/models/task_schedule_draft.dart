import 'journal_entry.dart';

/// タスクの「開始・終了時間（カレンダー同期用）」と「通知時刻（プッシュ通知用、
/// 開始・終了とは独立）」の可変な下書き状態。[TaskEditScreen]（既存タスク編集）と
/// [ManualTaskScreen]（新規手動作成）の両方で使う——エントリに紐づく既存の
/// [TaskItem]があるかどうかは呼び出し側の関心事で、この下書き自体はどちらの
/// 場面でも同じ形を持つ。
class TaskScheduleDraft {
  DateTime? startAt;
  DateTime? endAt;
  bool isAllDay;
  DateTime? notifyAt;

  TaskScheduleDraft({
    this.startAt,
    this.endAt,
    this.isAllDay = false,
    this.notifyAt,
  });

  /// 開始日時を変更したとき、終了日時がそれより前になっていたら消す
  /// （意味のない範囲が残らないようにする）。
  void keepEndAfterStart() {
    final start = startAt;
    final end = endAt;
    if (start != null && end != null && end.isBefore(start)) {
      endAt = null;
    }
  }

  void setAllDay(bool value) {
    isAllDay = value;
    final at = startAt;
    if (value) {
      endAt = null;
      if (at != null) {
        startAt = DateTime(at.year, at.month, at.day);
        notifyAt ??= TaskItem.defaultAllDayNotifyAt(startAt!);
      }
    }
  }

  void clearStart() {
    startAt = null;
    endAt = null;
    isAllDay = false;
  }

  void clearEndTime() => endAt = null;

  void clearNotify() => notifyAt = null;
}
