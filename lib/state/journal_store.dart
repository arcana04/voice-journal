import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/journal_entry.dart';
import '../services/db_service.dart';
import '../services/image_storage_service.dart';
import '../services/reminder_service.dart';

class JournalStore extends ChangeNotifier {
  final DbService _db = DbService.instance;
  final ReminderService _reminders = ReminderService.instance;
  final ImageStorageService _images = ImageStorageService();

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

  Future<void> addEntry(JournalEntry entry) async {
    final saved = await _db.insertEntry(entry);
    entries.insert(0, saved);
    for (final task in saved.tasks) {
      if (task.id != null && task.reminderAt != null) {
        await _reminders.scheduleTaskReminder(
          taskId: task.id!,
          title: task.title,
          scheduledAt: task.reminderAt!,
        );
      }
    }
    notifyListeners();
  }

  Future<void> toggleTask(JournalEntry entry, TaskItem task) async {
    if (task.id == null) return;
    final newDone = !task.done;
    await _db.setTaskDone(task.id!, newDone);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    final updatedTasks = entries[index]
        .tasks
        .map((t) => t.id == task.id ? t.copyWith(done: newDone) : t)
        .toList();
    entries[index] = entries[index].copyWith(tasks: updatedTasks);
    notifyListeners();

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
    }
  }

  Future<void> deleteEntry(JournalEntry entry) async {
    if (entry.id == null) return;
    for (final task in entry.tasks) {
      if (task.id != null && task.reminderAt != null) {
        await _reminders.cancelTaskReminder(task.id!);
      }
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
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    final updatedTasks = entries[index]
        .tasks
        .map((t) => t.id == task.id ? t.copyWith(title: trimmed) : t)
        .toList();
    entries[index] = entries[index].copyWith(tasks: updatedTasks);
    notifyListeners();

    if (task.reminderAt != null && !task.done) {
      await _reminders.scheduleTaskReminder(
        taskId: task.id!,
        title: trimmed,
        scheduledAt: task.reminderAt!,
      );
    }
  }

  Future<void> updateTaskReminder(
    JournalEntry entry,
    TaskItem task,
    DateTime? reminderAt,
  ) async {
    if (task.id == null) return;
    await _db.updateTaskReminder(task.id!, reminderAt);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      final updatedTasks = entries[index].tasks.map((t) {
        if (t.id != task.id) return t;
        return t.copyWith(reminderAt: reminderAt, clearReminder: reminderAt == null);
      }).toList();
      entries[index] = entries[index].copyWith(tasks: updatedTasks);
      notifyListeners();
    }

    if (reminderAt == null) {
      await _reminders.cancelTaskReminder(task.id!);
    } else if (!task.done) {
      await _reminders.scheduleTaskReminder(
        taskId: task.id!,
        title: task.title,
        scheduledAt: reminderAt,
      );
    }
  }
}
