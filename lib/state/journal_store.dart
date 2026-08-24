import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/journal_entry.dart';
import '../services/db_service.dart';
import '../services/reminder_service.dart';

class JournalStore extends ChangeNotifier {
  final DbService _db = DbService.instance;
  final ReminderService _reminders = ReminderService.instance;

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
    await _db.deleteEntry(entry.id!);
    entries.removeWhere((e) => e.id == entry.id);
    notifyListeners();
  }
}
