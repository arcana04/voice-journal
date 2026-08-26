import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/journal_entry.dart';
import '../services/calendar_service.dart';
import '../services/calendar_settings_service.dart';
import '../services/db_service.dart';
import '../services/image_storage_service.dart';
import '../services/reminder_service.dart';

class JournalStore extends ChangeNotifier {
  final DbService _db = DbService.instance;
  final ReminderService _reminders = ReminderService.instance;
  final ImageStorageService _images = ImageStorageService();
  final CalendarService _calendar = CalendarService.instance;
  final CalendarSettingsService _calendarSettings = CalendarSettingsService();

  List<JournalEntry> entries = [];
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    entries = await _db.fetchEntries();
    loading = false;
    notifyListeners();
    // 端末の再起動やアプリ再インストールでOS側のスケジュールが失われていても、
    // 未完了かつ未来のリマインダーを起動のたびに再登録して復元する。
    unawaited(_rescheduleAllPendingReminders());
  }

  Future<void> _rescheduleAllPendingReminders() async {
    for (final entry in entries) {
      for (final task in entry.tasks) {
        if (!task.done && task.id != null && task.reminderAt != null) {
          await _reminders.scheduleTaskReminder(
            taskId: task.id!,
            title: task.title,
            scheduledAt: task.reminderAt!,
          );
        }
      }
    }
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

  Future<void> addEntry(JournalEntry entry) async {
    final saved = await _db.insertEntry(entry);
    final syncedTasks = <TaskItem>[];
    for (final task in saved.tasks) {
      if (task.id != null && task.reminderAt != null) {
        await _reminders.scheduleTaskReminder(
          taskId: task.id!,
          title: task.title,
          scheduledAt: task.reminderAt!,
        );
      }
      if (task.id != null) {
        final eventId = await _syncTaskCalendarEvent(task);
        if (eventId != task.calendarEventId) {
          await _db.updateTaskCalendarEventId(task.id!, eventId);
        }
        syncedTasks.add(task.copyWith(
          calendarEventId: eventId,
          clearCalendarEventId: eventId == null,
        ));
      } else {
        syncedTasks.add(task);
      }
    }
    entries.insert(0, saved.copyWith(tasks: syncedTasks));
    notifyListeners();
  }

  Future<void> toggleTask(JournalEntry entry, TaskItem task) async {
    if (task.id == null) return;
    final newDone = !task.done;
    await _db.setTaskDone(task.id!, newDone);
    final updatedTask = task.copyWith(done: newDone);

    String? eventId = task.calendarEventId;
    if (task.reminderAt != null) {
      if (newDone) {
        await _reminders.cancelTaskReminder(task.id!);
      } else {
        await _reminders.scheduleTaskReminder(
          taskId: task.id!,
          title: task.title,
          scheduledAt: task.reminderAt!,
        );
      }
      eventId = await _syncTaskCalendarEvent(updatedTask);
      if (eventId != task.calendarEventId) {
        await _db.updateTaskCalendarEventId(task.id!, eventId);
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
      );
    }).toList();
    entries[index] = entries[index].copyWith(tasks: updatedTasks);
    notifyListeners();
  }

  Future<void> deleteEntry(JournalEntry entry) async {
    if (entry.id == null) return;
    for (final task in entry.tasks) {
      if (task.id != null && task.reminderAt != null) {
        await _reminders.cancelTaskReminder(task.id!);
      }
      await _deleteTaskCalendarEvent(task);
    }
    for (final path in entry.imagePaths) {
      await _images.deleteImage(path);
    }
    await _db.deleteEntry(entry.id!);
    entries.removeWhere((e) => e.id == entry.id);
    notifyListeners();
  }

  /// 写真・動画のファイルを entry に追加する。
  Future<void> addMediaToEntry(JournalEntry entry, List<File> files) async {
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
  }

  Future<void> removeMediaFromEntry(JournalEntry entry, String path) async {
    if (entry.id == null) return;
    await _db.deleteImage(entry.id!, path);
    await _images.deleteImage(path);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    entries[index] = entries[index].copyWith(
      imagePaths: entries[index].imagePaths.where((p) => p != path).toList(),
    );
    notifyListeners();
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
      return n.copyWith(title: title, clearTitle: title == null, content: content);
    }).toList();
    entries[index] = entries[index].copyWith(notes: updatedNotes);
    notifyListeners();
  }

  Future<void> updateTaskTitle(JournalEntry entry, TaskItem task, String title) async {
    if (task.id == null || title.trim().isEmpty) return;
    final trimmed = title.trim();
    await _db.updateTaskTitle(task.id!, trimmed);

    if (task.reminderAt != null && !task.done) {
      await _reminders.scheduleTaskReminder(
        taskId: task.id!,
        title: trimmed,
        scheduledAt: task.reminderAt!,
      );
    }
    final eventId = await _syncTaskCalendarEvent(task.copyWith(title: trimmed));
    if (eventId != task.calendarEventId) {
      await _db.updateTaskCalendarEventId(task.id!, eventId);
    }

    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    final updatedTasks = entries[index].tasks.map((t) {
      if (t.id != task.id) return t;
      return t.copyWith(
        title: trimmed,
        calendarEventId: eventId,
        clearCalendarEventId: eventId == null,
      );
    }).toList();
    entries[index] = entries[index].copyWith(tasks: updatedTasks);
    notifyListeners();
  }

  Future<void> updateTaskReminder(
    JournalEntry entry,
    TaskItem task,
    DateTime? reminderAt,
  ) async {
    if (task.id == null) return;
    await _db.updateTaskReminder(task.id!, reminderAt);

    if (reminderAt == null) {
      await _reminders.cancelTaskReminder(task.id!);
    } else if (!task.done) {
      await _reminders.scheduleTaskReminder(
        taskId: task.id!,
        title: task.title,
        scheduledAt: reminderAt,
      );
    }
    final eventId = await _syncTaskCalendarEvent(
      task.copyWith(reminderAt: reminderAt, clearReminder: reminderAt == null),
    );
    if (eventId != task.calendarEventId) {
      await _db.updateTaskCalendarEventId(task.id!, eventId);
    }

    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      final updatedTasks = entries[index].tasks.map((t) {
        if (t.id != task.id) return t;
        return t.copyWith(
          reminderAt: reminderAt,
          clearReminder: reminderAt == null,
          calendarEventId: eventId,
          clearCalendarEventId: eventId == null,
        );
      }).toList();
      entries[index] = entries[index].copyWith(tasks: updatedTasks);
      notifyListeners();
    }
  }
}
