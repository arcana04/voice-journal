import 'dart:async';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';
import '../services/apple_reminders_service.dart';
import '../services/apple_reminders_settings_service.dart';
import '../services/calendar_service.dart';
import '../services/calendar_settings_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/db_service.dart';
import '../services/image_storage_service.dart';
import '../services/media_sync_service.dart';
import '../services/reminder_service.dart';

class JournalStore extends ChangeNotifier {
  final DbService _db = DbService.instance;
  final ReminderService _reminders = ReminderService.instance;
  final ImageStorageService _images = ImageStorageService();
  final CalendarService _calendar = CalendarService.instance;
  final CalendarSettingsService _calendarSettings = CalendarSettingsService();
  final AppleRemindersService _appleReminders = AppleRemindersService.instance;
  final AppleRemindersSettingsService _appleRemindersSettings =
      AppleRemindersSettingsService();
  final CloudSyncService _cloudSync = CloudSyncService();
  final MediaSyncService _mediaSync = MediaSyncService();

  List<JournalEntry> entries = [];
  bool loading = false;
  bool _syncing = false;

  /// 直近の[load]呼び出しが失敗した場合のエラー内容。成功すればnullに戻る。
  /// UIはこれを見て、末永く回り続けるローディング表示を防いだり、エラーを
  /// 表示したりする（[RootScreen]が全タブ共通で表示する）。
  String? loadError;

  /// 直近のクラウド同期（テキスト/写真・動画）操作のいずれかが失敗したかどうか。
  /// バックグラウンドで自動的に再試行することはないため、UIに常時見えるよう
  /// [RootScreen]が案内バナーを出す（静かに失敗して気づかれない状態を避ける狙い）。
  bool syncError = false;

  /// [_cloudSync]/[_mediaSync]の各操作はfire-and-forgetで呼ぶが、成否だけは
  /// [syncError]に反映してUIに見えるようにする。
  void _trackSync(Future<bool> future) {
    unawaited(
      future.then((success) {
        if (syncError == !success) return;
        syncError = !success;
        notifyListeners();
      }),
    );
  }

  Future<void> load() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      entries = await _db.fetchEntries();
      // 端末の再起動やアプリ再インストールでOS側のスケジュールが失われていても、
      // 未完了かつ未来のリマインダーを起動のたびに再登録して復元する。Android では
      // これに加えて WorkManager 経由でも定期的に同じ復元処理を行う
      // （[reminderCallbackDispatcher]）ため、再起動後アプリを開かなくても復元される。
      unawaited(_reminders.rescheduleAllPending());
    } catch (e) {
      loadError = e.toString();
      debugPrint('journal load failed: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 指定idのエントリを[entries]から探す。複数画面（編集画面など）で
  /// 同じ線形探索が重複していたのをまとめたもの。
  JournalEntry? findById(int id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// 連携先カレンダーが選ばれていれば、タスクの状態に合わせて予定を作成・更新・
  /// 削除し、新しいカレンダーイベントIDを返す（連携オフや失敗時は元の値のまま）。
  Future<String?> _syncTaskCalendarEvent(TaskItem task) async {
    final calendarId = await _calendarSettings.getCalendarId();
    if (calendarId == null) return task.calendarEventId;

    try {
      if (task.reminderAt == null || task.done) {
        if (task.calendarEventId != null) {
          await _calendar.deleteEvent(calendarId, task.calendarEventId!);
        }
        return null;
      }
      return await _calendar.upsertEvent(
        calendarId: calendarId,
        eventId: task.calendarEventId,
        title: task.title,
        start: task.reminderAt!,
        end: task.reminderEndAt,
        allDay: task.isAllDay,
      );
    } catch (e) {
      debugPrint('calendar sync failed: $e');
      return task.calendarEventId;
    }
  }

  Future<void> _deleteTaskCalendarEvent(TaskItem task) async {
    if (task.calendarEventId == null) return;
    final calendarId = await _calendarSettings.getCalendarId();
    if (calendarId == null) return;
    try {
      await _calendar.deleteEvent(calendarId, task.calendarEventId!);
    } catch (e) {
      debugPrint('calendar delete failed: $e');
    }
  }

  /// 連携先リマインダーリストが選ばれていれば、タスクの状態に合わせてiPhone標準の
  /// リマインダーを作成・更新し、新しいリマインダーIDを返す（連携オフや失敗時は
  /// 元の値のまま）。カレンダー予定と違い、完了時は削除せず「完了」状態にする
  /// （リマインダーアプリは完了済みToDoを取り消し線付きで表示し続ける設計のため）。
  Future<String?> _syncTaskAppleReminder(TaskItem task) async {
    final listId = await _appleRemindersSettings.getListId();
    if (listId == null) return task.appleReminderId;

    try {
      final dueDate = task.reminderAt ?? task.dueDate;
      if (dueDate == null) {
        if (task.appleReminderId != null) {
          await _appleReminders.deleteReminder(task.appleReminderId!);
        }
        return null;
      }
      return await _appleReminders.upsertReminder(
        listId: listId,
        reminderId: task.appleReminderId,
        title: task.title,
        dueDate: dueDate,
        includesTime: task.reminderAt != null && !task.isAllDay,
        completed: task.done,
      );
    } catch (e) {
      debugPrint('apple reminders sync failed: $e');
      return task.appleReminderId;
    }
  }

  Future<void> _deleteTaskAppleReminder(TaskItem task) async {
    if (task.appleReminderId == null) return;
    final listId = await _appleRemindersSettings.getListId();
    if (listId == null) return;
    try {
      await _appleReminders.deleteReminder(task.appleReminderId!);
    } catch (e) {
      debugPrint('apple reminders delete failed: $e');
    }
  }

  /// [skipCloudPush]は、クラウドから復元してきたエントリを再度クラウドへ
  /// 送り返さないようにするためのフラグ（[fullSync]から使う）。
  Future<JournalEntry> addEntry(
    JournalEntry entry, {
    bool skipCloudPush = false,
  }) async {
    final saved = await _db.insertEntry(entry);
    final syncedTasks = <TaskItem>[];
    for (final task in saved.tasks) {
      if (task.id != null && task.notifyAt != null) {
        await _reminders.scheduleTaskReminder(
          taskId: task.id!,
          title: task.title,
          scheduledAt: task.notifyAt!,
        );
      }
      if (task.id != null) {
        final eventId = await _syncTaskCalendarEvent(task);
        if (eventId != task.calendarEventId) {
          await _db.updateTaskCalendarEventId(task.id!, eventId);
        }
        final reminderId = await _syncTaskAppleReminder(task);
        if (reminderId != task.appleReminderId) {
          await _db.updateTaskAppleReminderId(task.id!, reminderId);
        }
        syncedTasks.add(
          task.copyWith(
            calendarEventId: eventId,
            clearCalendarEventId: eventId == null,
            appleReminderId: reminderId,
            clearAppleReminderId: reminderId == null,
          ),
        );
      } else {
        syncedTasks.add(task);
      }
    }
    final finalEntry = saved.copyWith(tasks: syncedTasks);
    entries.insert(0, finalEntry);
    notifyListeners();
    if (!skipCloudPush) {
      _trackSync(_cloudSync.pushEntry(finalEntry));
    }
    return finalEntry;
  }

  Future<void> toggleTask(JournalEntry entry, TaskItem task) async {
    if (task.id == null) return;
    final newDone = !task.done;
    await _db.setTaskDone(task.id!, newDone);
    final updatedTask = task.copyWith(done: newDone);

    String? eventId = task.calendarEventId;
    if (task.reminderAt != null) {
      eventId = await _syncTaskCalendarEvent(updatedTask);
      if (eventId != task.calendarEventId) {
        await _db.updateTaskCalendarEventId(task.id!, eventId);
      }
    }
    String? reminderId = task.appleReminderId;
    if (task.reminderAt != null || task.dueDate != null) {
      reminderId = await _syncTaskAppleReminder(updatedTask);
      if (reminderId != task.appleReminderId) {
        await _db.updateTaskAppleReminderId(task.id!, reminderId);
      }
    }
    if (task.notifyAt != null) {
      if (newDone) {
        await _reminders.cancelTaskReminder(task.id!);
      } else {
        await _reminders.scheduleTaskReminder(
          taskId: task.id!,
          title: task.title,
          scheduledAt: task.notifyAt!,
        );
      }
    }

    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    final updatedTasks = entries[index].tasks.map((t) {
      if (t.id != task.id) return t;
      return t.copyWith(
        done: newDone,
        calendarEventId: eventId,
        clearCalendarEventId: eventId == null,
        appleReminderId: reminderId,
        clearAppleReminderId: reminderId == null,
      );
    }).toList();
    entries[index] = entries[index].copyWith(tasks: updatedTasks);
    notifyListeners();
    _trackSync(_cloudSync.pushEntry(entries[index]));
  }

  Future<void> deleteEntry(JournalEntry entry, {bool canSyncMedia = false}) async {
    if (entry.id == null) return;
    for (final task in entry.tasks) {
      if (task.id != null && task.notifyAt != null) {
        await _reminders.cancelTaskReminder(task.id!);
      }
      await _deleteTaskCalendarEvent(task);
      await _deleteTaskAppleReminder(task);
    }
    for (final path in entry.imagePaths) {
      await _images.deleteImage(path);
    }
    await _db.deleteEntry(entry.id!);
    entries.removeWhere((e) => e.id == entry.id);
    notifyListeners();
    _trackSync(_cloudSync.deleteEntry(entry.remoteId));
    if (canSyncMedia) {
      _trackSync(_mediaSync.deleteAllMedia(entry.remoteId));
    }
  }

  /// entry丸ごとではなく、指定したnote（同じカテゴリの内容）だけを削除する。
  /// 日記・アイデアの削除ボタンから使う——1回の録音がタスク・日記・アイデアに
  /// 同時に仕分けられることがあるため、削除操作が他カテゴリの内容まで
  /// 巻き込まないようにするための単位。[alsoDeleteImages]は日記側の削除だけ
  /// trueで渡す——写真・動画添付は日記編集画面からしか行えず、概念上「日記側の
  /// 付属物」であるため。削除後にentryがタスク・note・画像すべて空になったら、
  /// 空のentryを残さずentry自体を削除する（[_replaceOrDeleteIfEmpty]）。
  Future<void> deleteNotesFromEntry(
    JournalEntry entry,
    List<NoteItem> notes, {
    bool alsoDeleteImages = false,
    bool canSyncMedia = false,
  }) async {
    if (entry.id == null || notes.isEmpty) return;

    if (alsoDeleteImages) {
      final current = entries.firstWhere(
        (e) => e.id == entry.id,
        orElse: () => entry,
      );
      for (final path in List<String>.from(current.imagePaths)) {
        await removeMediaFromEntry(entry, path, canSyncMedia: canSyncMedia);
      }
    }

    final removedIds = notes.map((n) => n.id).whereType<int>().toSet();
    if (removedIds.isEmpty) return;
    await _db.deleteNotes(removedIds.toList());

    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    final updated = entries[index].copyWith(
      notes: entries[index].notes
          .where((n) => !removedIds.contains(n.id))
          .toList(),
    );
    await _replaceOrDeleteIfEmpty(index, updated, canSyncMedia: canSyncMedia);
  }

  /// entry丸ごとではなく、指定したtaskだけを削除する
  /// （[deleteNotesFromEntry]のタスク版）。カレンダー予定・通知も片付ける。
  Future<void> deleteTasksFromEntry(
    JournalEntry entry,
    List<TaskItem> tasks, {
    bool canSyncMedia = false,
  }) async {
    if (entry.id == null || tasks.isEmpty) return;
    for (final task in tasks) {
      if (task.id != null && task.notifyAt != null) {
        await _reminders.cancelTaskReminder(task.id!);
      }
      await _deleteTaskCalendarEvent(task);
      await _deleteTaskAppleReminder(task);
    }

    final removedIds = tasks.map((t) => t.id).whereType<int>().toSet();
    if (removedIds.isEmpty) return;
    await _db.deleteTasks(removedIds.toList());

    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    final updated = entries[index].copyWith(
      tasks: entries[index].tasks
          .where((t) => !removedIds.contains(t.id))
          .toList(),
    );
    await _replaceOrDeleteIfEmpty(index, updated, canSyncMedia: canSyncMedia);
  }

  /// [deleteNotesFromEntry]/[deleteTasksFromEntry]共通の後始末: 更新後の
  /// entryがタスク・note・画像すべて空になったら、空のentryを残さず削除する。
  /// そうでなければ通常どおり更新してクラウドへpushする。
  Future<void> _replaceOrDeleteIfEmpty(
    int index,
    JournalEntry updated, {
    required bool canSyncMedia,
  }) async {
    if (updated.tasks.isEmpty &&
        updated.notes.isEmpty &&
        updated.imagePaths.isEmpty) {
      await _db.deleteEntry(updated.id!);
      entries.removeAt(index);
      notifyListeners();
      _trackSync(_cloudSync.deleteEntry(updated.remoteId));
      if (canSyncMedia) {
        _trackSync(_mediaSync.deleteAllMedia(updated.remoteId));
      }
      return;
    }
    entries[index] = updated;
    notifyListeners();
    _trackSync(_cloudSync.pushEntry(updated));
  }

  /// 写真・動画のファイルを entry に追加する。[canSyncMedia]なら、Firebase Storageへの
  /// クラウドバックアップも行う（サブスクプラン限定機能——買い切りプランでは
  /// 写真・動画の同期は対象外）。
  Future<void> addMediaToEntry(
    JournalEntry entry,
    List<File> files, {
    bool canSyncMedia = false,
  }) async {
    if (entry.id == null || files.isEmpty) return;
    final paths = <String>[];
    for (final file in files) {
      paths.add(await _images.saveImage(file));
    }
    await _db.addImages(entry.id!, paths);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    entries[index] = entries[index].copyWith(
      imagePaths: [...entries[index].imagePaths, ...paths],
    );
    notifyListeners();
    if (canSyncMedia) {
      _trackSync(
        _mediaSync.uploadPendingMedia(
          entryId: entry.id!,
          remoteId: entry.remoteId,
        ),
      );
    }
  }

  Future<void> removeMediaFromEntry(
    JournalEntry entry,
    String path, {
    bool canSyncMedia = false,
  }) async {
    if (entry.id == null) return;
    await _db.deleteImage(entry.id!, path);
    await _images.deleteImage(path);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    entries[index] = entries[index].copyWith(
      imagePaths: entries[index].imagePaths.where((p) => p != path).toList(),
    );
    notifyListeners();
    if (canSyncMedia) {
      _trackSync(_mediaSync.deleteMedia(entry.remoteId, path));
    }
  }

  Future<void> updateNoteText(
    JournalEntry entry,
    NoteItem note, {
    String? title,
    required String content,
  }) async {
    if (note.id == null) return;
    await _db.updateNote(note.id!, title: title, content: content);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    final updatedNotes = entries[index].notes.map((n) {
      if (n.id != note.id) return n;
      return n.copyWith(
        title: title,
        clearTitle: title == null,
        content: content,
      );
    }).toList();
    entries[index] = entries[index].copyWith(notes: updatedNotes);
    notifyListeners();
    _trackSync(_cloudSync.pushEntry(entries[index]));
  }

  Future<void> updateNoteStyle(
    JournalEntry entry,
    NoteItem note, {
    required int fontFamilyIndex,
    required Color? textColor,
    required double fontScale,
    required String? backgroundId,
  }) async {
    if (note.id == null) return;
    await _db.updateNoteStyle(
      note.id!,
      fontFamilyIndex: fontFamilyIndex,
      textColorValue: textColor?.toARGB32(),
      fontScale: fontScale,
      backgroundId: backgroundId,
    );
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    final updatedNotes = entries[index].notes.map((n) {
      if (n.id != note.id) return n;
      return n.copyWith(
        fontFamilyIndex: fontFamilyIndex,
        textColorValue: textColor?.toARGB32(),
        clearTextColor: textColor == null,
        fontScale: fontScale,
        backgroundId: backgroundId,
        clearBackground: backgroundId == null,
      );
    }).toList();
    entries[index] = entries[index].copyWith(notes: updatedNotes);
    notifyListeners();
    _trackSync(_cloudSync.pushEntry(entries[index]));
  }

  Future<void> updateEntryEmotion(
    JournalEntry entry,
    EmotionTag? emotion,
  ) async {
    if (entry.id == null) return;
    await _db.updateEntryEmotion(entry.id!, emotion);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    entries[index] = entries[index].copyWith(
      emotion: emotion,
      clearEmotion: emotion == null,
    );
    notifyListeners();
    _trackSync(_cloudSync.pushEntry(entries[index]));
  }

  Future<void> updateTaskTitle(
    JournalEntry entry,
    TaskItem task,
    String title,
  ) async {
    if (task.id == null || title.trim().isEmpty) return;
    final trimmed = title.trim();
    await _db.updateTaskTitle(task.id!, trimmed);

    if (task.notifyAt != null && !task.done) {
      await _reminders.scheduleTaskReminder(
        taskId: task.id!,
        title: trimmed,
        scheduledAt: task.notifyAt!,
      );
    }
    final eventId = await _syncTaskCalendarEvent(task.copyWith(title: trimmed));
    if (eventId != task.calendarEventId) {
      await _db.updateTaskCalendarEventId(task.id!, eventId);
    }
    final reminderId = await _syncTaskAppleReminder(
      task.copyWith(title: trimmed),
    );
    if (reminderId != task.appleReminderId) {
      await _db.updateTaskAppleReminderId(task.id!, reminderId);
    }

    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    final updatedTasks = entries[index].tasks.map((t) {
      if (t.id != task.id) return t;
      return t.copyWith(
        title: trimmed,
        calendarEventId: eventId,
        clearCalendarEventId: eventId == null,
        appleReminderId: reminderId,
        clearAppleReminderId: reminderId == null,
      );
    }).toList();
    entries[index] = entries[index].copyWith(tasks: updatedTasks);
    notifyListeners();
    _trackSync(_cloudSync.pushEntry(entries[index]));
  }

  /// タスクの「開始・終了時間」（カレンダー同期用）を更新する。プッシュ通知の
  /// 発火時刻には一切影響しない（[updateTaskNotifyAt]で別途管理）。
  Future<void> updateTaskSchedule(
    JournalEntry entry,
    TaskItem task, {
    required DateTime? startAt,
    DateTime? endAt,
    bool isAllDay = false,
  }) async {
    if (task.id == null) return;
    final effectiveAllDay = startAt != null && isAllDay;
    final effectiveEndAt = effectiveAllDay ? null : endAt;
    // 「今日/今週/1ヶ月以内」フィルタはdueDateだけを見るため、開始日時を
    // 変更したらdueDateもその日付に合わせて更新する（さもないと編集後も
    // 古い期限日でフィルタされてしまう）。
    final newDueDate = startAt != null
        ? DateTime(startAt.year, startAt.month, startAt.day)
        : null;
    await _db.updateTaskSchedule(
      task.id!,
      startAt,
      endAt: effectiveEndAt,
      isAllDay: effectiveAllDay,
      dueDate: newDueDate,
    );

    final scheduledTask = task.copyWith(
      dueDate: newDueDate,
      clearDueDate: newDueDate == null,
      reminderAt: startAt,
      clearReminder: startAt == null,
      reminderEndAt: effectiveEndAt,
      clearReminderEndAt: effectiveEndAt == null,
      isAllDay: effectiveAllDay,
    );
    final eventId = await _syncTaskCalendarEvent(scheduledTask);
    if (eventId != task.calendarEventId) {
      await _db.updateTaskCalendarEventId(task.id!, eventId);
    }
    final reminderId = await _syncTaskAppleReminder(scheduledTask);
    if (reminderId != task.appleReminderId) {
      await _db.updateTaskAppleReminderId(task.id!, reminderId);
    }

    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      final updatedTasks = entries[index].tasks.map((t) {
        if (t.id != task.id) return t;
        return t.copyWith(
          dueDate: newDueDate,
          clearDueDate: newDueDate == null,
          reminderAt: startAt,
          clearReminder: startAt == null,
          reminderEndAt: effectiveEndAt,
          clearReminderEndAt: effectiveEndAt == null,
          calendarEventId: eventId,
          clearCalendarEventId: eventId == null,
          appleReminderId: reminderId,
          clearAppleReminderId: reminderId == null,
          isAllDay: effectiveAllDay,
        );
      }).toList();
      entries[index] = entries[index].copyWith(tasks: updatedTasks);
      notifyListeners();
      _trackSync(_cloudSync.pushEntry(entries[index]));
    }
  }

  /// タスクのプッシュ通知の発火時刻を更新する。カレンダーの開始・終了時間
  /// （[updateTaskSchedule]）には一切影響しない。
  Future<void> updateTaskNotifyAt(
    JournalEntry entry,
    TaskItem task,
    DateTime? notifyAt,
  ) async {
    if (task.id == null) return;
    await _db.updateTaskNotifyAt(task.id!, notifyAt);

    if (notifyAt == null) {
      await _reminders.cancelTaskReminder(task.id!);
    } else if (!task.done) {
      await _reminders.scheduleTaskReminder(
        taskId: task.id!,
        title: task.title,
        scheduledAt: notifyAt,
      );
    }

    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      final updatedTasks = entries[index].tasks.map((t) {
        if (t.id != task.id) return t;
        return t.copyWith(notifyAt: notifyAt, clearNotify: notifyAt == null);
      }).toList();
      entries[index] = entries[index].copyWith(tasks: updatedTasks);
      notifyListeners();
      _trackSync(_cloudSync.pushEntry(entries[index]));
    }
  }

  /// メールアカウントのサインアップ/サインイン後、または手動の「クラウドから復元」
  /// 操作から呼ぶ。まず現在のローカルの全エントリをクラウドへpushし（この端末で
  /// 未同期のまま溜まっていたデータをアップロード）、次にクラウド上にあってこの
  /// 端末にまだ無いエントリを取り込む（削除の伝播は行わない — データを失わない
  /// ことを優先した意図的な仕様）。
  Future<void> fullSync({bool canSyncMedia = false}) async {
    if (_syncing) return;
    _syncing = true;
    var success = true;
    try {
      for (final entry in entries) {
        if (!await _cloudSync.pushEntry(entry)) success = false;
        if (canSyncMedia && entry.id != null) {
          final uploaded = await _mediaSync.uploadPendingMedia(
            entryId: entry.id!,
            remoteId: entry.remoteId,
          );
          if (!uploaded) success = false;
        }
      }
      final remoteEntries = await _cloudSync.fetchAll();
      if (remoteEntries == null) {
        success = false;
      } else {
        final localRemoteIds = entries
            .map((e) => e.remoteId)
            .whereType<String>()
            .toSet();
        for (final remote in remoteEntries) {
          if (remote.remoteId == null ||
              localRemoteIds.contains(remote.remoteId)) {
            continue;
          }
          final saved = await addEntry(remote, skipCloudPush: true);
          if (canSyncMedia && saved.id != null) {
            final downloaded = await _mediaSync.downloadMissingMedia(
              entryId: saved.id!,
              remoteId: saved.remoteId,
              localPaths: saved.imagePaths,
            );
            if (!downloaded) success = false;
          }
        }
      }
    } finally {
      _syncing = false;
      syncError = !success;
      await load();
    }
  }
}
