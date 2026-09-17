import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import '../models/emotion_tag.dart';
import '../models/entry_image.dart';
import '../models/journal_entry.dart';
import '../models/media_usage.dart';
import '../models/sync_failure_reason.dart';
import '../models/throwback_item.dart';
import '../services/apple_reminders_service.dart';
import '../services/apple_reminders_settings_service.dart';
import '../services/backend_service.dart';
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
  final BackendService _backend = BackendService();

  List<JournalEntry> entries = [];
  bool loading = false;
  bool _syncing = false;

  /// 写真・動画クラウド同期（サブスクプラン限定）の直近の使用量。未取得/取得
  /// 失敗時はnull（バナー等は単に表示しない）。
  MediaUsage? mediaUsage;

  /// [BackendService.fetchMediaUsage]で最新の使用量を取得する。失敗しても
  /// 静かに諦める（容量確認はコア機能ではないため、ここでUIを壊さない）。
  Future<void> refreshMediaUsage() async {
    try {
      mediaUsage = await _backend.fetchMediaUsage();
      notifyListeners();
    } catch (e) {
      debugPrint('refreshMediaUsage failed: $e');
    }
  }

  /// 直近の[load]呼び出しが失敗した場合のエラー内容。成功すればnullに戻る。
  /// UIはこれを見て、末永く回り続けるローディング表示を防いだり、エラーを
  /// 表示したりする（[RootScreen]が全タブ共通で表示する）。
  String? loadError;

  /// 直近のクラウド同期（テキスト/写真・動画）操作のいずれかが失敗したかどうか。
  /// バックグラウンドで自動的に再試行することはないため、UIに常時見えるよう
  /// [RootScreen]が案内バナーを出す（静かに失敗して気づかれない状態を避ける狙い）。
  bool syncError = false;

  /// [syncError]がtrueの場合の大まかな原因分類。UIが「サインインし直せば
  /// 直る」等、原因に応じた案内を出せるようにする（nullは分類不能/未取得）。
  SyncFailureReason? syncErrorReason;

  /// カレンダー/リマインダー連携（[_syncTaskCalendarEvent]/[_syncTaskAppleReminder]）
  /// の直近の同期が失敗したかどうか。従来はdebugPrintするだけでUIに一切
  /// 反映されず、権限が取り消された/連携先カレンダーが削除された等の理由で
  /// 静かに・恒久的にズレたままになっていた（[[project_voicejournal_knowledge_base_chat]]
  /// 参照）。[syncError]（クラウド同期用）とは原因も直し方も異なるため、
  /// 別のバナーで案内するために独立したフラグにしている。
  bool calendarSyncError = false;

  /// [_cloudSync]/[_mediaSync]の各操作はfire-and-forgetで呼ぶが、成否だけは
  /// [syncError]に反映してUIに見えるようにする。
  void _trackSync(Future<bool> future) {
    unawaited(
      future.then((success) {
        final reason = success
            ? null
            : (_cloudSync.lastFailureReason ?? _mediaSync.lastFailureReason);
        if (syncError == !success && syncErrorReason == reason) return;
        syncError = !success;
        syncErrorReason = reason;
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
      unawaited(refreshMediaUsage());
    } catch (e) {
      loadError = e.toString();
      debugPrint('journal load failed: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 今日まで(または昨日まで)連続で何日記録が続いているか。日付が変わった
  /// 瞬間に0へ戻る違和感を避けるため、今日まだ記録が無くても最後の記録が
  /// 昨日なら連続記録はまだ途切れていない扱いにする。
  int get currentStreak {
    if (entries.isEmpty) return 0;
    final dates = <DateTime>{};
    for (final entry in entries) {
      final createdAt = entry.createdAt;
      dates.add(DateTime(createdAt.year, createdAt.month, createdAt.day));
    }

    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    if (!dates.contains(cursor)) {
      final yesterday = cursor.subtract(const Duration(days: 1));
      if (!dates.contains(yesterday)) return 0;
      cursor = yesterday;
    }

    var streak = 0;
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 指定idのエントリを[entries]から探す。複数画面（編集画面など）で
  /// 同じ線形探索が重複していたのをまとめたもの。
  JournalEntry? findById(int id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// 日記タブの「思い出」機能（Instagram Storiesのようなふり返りビューア）向け。
  /// 「1ヶ月前/3ヶ月前/半年前/1年前/2年前の今日」のうち、実際に日記
  /// （[kNoteCategoryFeeling]）がある日だけを対象にする。ネガティブな感情の
  /// 日も除外しない（ユーザー指示）。同じ日に複数の日記がある場合は、
  /// ポジティブな感情のものを優先し、同程度なら文量（本文の文字数）が多い
  /// ものを優先して1件だけ選ぶ。表示順は「ランダムに出す」というユーザー
  /// 指示どおり、今日の日付をシードにした乱数でシャッフルする（同じ日に
  /// 何度開いても結果が変わらないよう、日付が変わるまでは安定させる）。
  List<ThrowbackItem> get throwbackItems {
    final now = DateTime.now();
    const monthsBackOptions = [1, 3, 6, 12, 24];
    final items = <ThrowbackItem>[];
    for (final monthsAgo in monthsBackOptions) {
      final target = DateTime(now.year, now.month - monthsAgo, now.day);
      // 対象月にその日が存在しない場合（例:過去の月末日）はDateTimeが
      // 翌月へ繰り上がって正規化されるため、dayが一致しなければ対象日なし
      // としてスキップする。
      if (target.day != now.day) continue;
      final dayEntries = entries
          .where(
            (e) =>
                e.createdAt.year == target.year &&
                e.createdAt.month == target.month &&
                e.createdAt.day == target.day &&
                e.notes.any((n) => n.category == kNoteCategoryFeeling),
          )
          .toList();
      if (dayEntries.isEmpty) continue;
      dayEntries.sort((a, b) {
        final emotionDiff =
            _throwbackEmotionScore(b) - _throwbackEmotionScore(a);
        if (emotionDiff != 0) return emotionDiff;
        return _throwbackFeelingLength(b) - _throwbackFeelingLength(a);
      });
      items.add(ThrowbackItem(entry: dayEntries.first, monthsAgo: monthsAgo));
    }
    if (items.isEmpty) return items;
    final seed = now.year * 10000 + now.month * 100 + now.day;
    items.shuffle(math.Random(seed));
    return items;
  }

  int _throwbackEmotionScore(JournalEntry entry) {
    switch (entry.emotion?.category) {
      case EmotionCategory.positive:
        return 2;
      case EmotionCategory.fine:
        return 1;
      case EmotionCategory.negative:
        return 0;
      case null:
        return 1;
    }
  }

  int _throwbackFeelingLength(JournalEntry entry) {
    var total = 0;
    for (final note in entry.notes) {
      if (note.category == kNoteCategoryFeeling) total += note.content.length;
    }
    return total;
  }

  /// [calendarId]が端末上にまだ実在するかを確認する。ユーザーがOS標準の
  /// カレンダーアプリ側で連携先カレンダーそのものを削除した場合、そのIDを
  /// 使った操作は毎回同じエラーで失敗し続け、アプリ内に復旧手段が無いまま
  /// [calendarSyncError]が永久にtrueのまま治らなくなる。この判定を使って、
  /// 「カレンダー自体が無くなった」場合だけは一時的な失敗として保持せず、
  /// 古い参照を諦めて手放す（[calendarSyncError]も立てない）。
  Future<bool> _calendarStillExists(String calendarId) async {
    try {
      final calendars = await _calendar.retrieveCalendars();
      return calendars.any((c) => c.id == calendarId);
    } catch (e) {
      // 実在確認自体が失敗した場合は「一時的な問題」の可能性を捨てきれない
      // ため、安全側に倒して「まだ存在する」ものとして扱う（＝従来通り
      // エラー保持・再試行に回す）。
      debugPrint('calendar existence check failed: $e');
      return true;
    }
  }

  /// 連携先カレンダーが選ばれていれば、タスクの状態に合わせて予定を作成・更新・
  /// 削除し、新しいカレンダーイベントIDとそのカレンダーIDを返す（連携オフや
  /// 失敗時は元の値のまま）。既にカレンダー予定を持っているタスクは、ユーザーが
  /// その後「現在選択中のカレンダー」を切り替えても、必ず予定が実際に存在する
  /// [task.calendarId]を対象に更新・削除する——現在選択中の値を使ってしまうと、
  /// 切り替え前のカレンダーに残った予定が二度と操作できず孤立してしまうため。
  /// [task.calendarEventId]はあるが[task.calendarId]が無い（切替対応前に
  /// 作られた）タスクだけ、従来どおり現在選択中の値へフォールバックする。
  Future<({String? eventId, String? calendarId})> _syncTaskCalendarEvent(
    TaskItem task,
  ) async {
    final selectedCalendarId = await _calendarSettings.getCalendarId();
    if (selectedCalendarId == null) {
      // 連携オフ。既にカレンダー予定を持つタスクであっても、[task.calendarId]
      // （予定作成時のカレンダーID）へフォールバックして更新を続けてしまうと
      // 「オフにしたのに前から連携していたタスクだけ同期され続ける」ことに
      // なる（新規タスクだけがオフの恩恵を受け、既存タスクは取り残される
      // バグだった）。Appleリマインダー連携（[_syncTaskAppleReminder]）と
      // 同じく、以後は一切触らない。
      return (eventId: task.calendarEventId, calendarId: task.calendarId);
    }
    final existingCalendarId = task.calendarEventId == null
        ? null
        : (task.calendarId ?? selectedCalendarId);

    if (task.reminderAt == null || task.done) {
      if (task.calendarEventId != null && existingCalendarId != null) {
        try {
          await _calendar.deleteEvent(existingCalendarId, task.calendarEventId!);
        } catch (e) {
          debugPrint('calendar sync (delete) failed: $e');
          if (await _calendarStillExists(existingCalendarId)) {
            if (!calendarSyncError) {
              calendarSyncError = true;
              notifyListeners();
            }
            return (eventId: task.calendarEventId, calendarId: task.calendarId);
          }
          // カレンダー自体がもう無いので、消せなかった予定への参照を諦めて
          // 手放す——保持し続けても二度と成功しない。
        }
      }
      return (eventId: null, calendarId: null);
    }

    // 既存予定があればそのカレンダーを、無ければ現在選択中のカレンダーを
    // 新規作成先にする（連携オフの場合は関数の先頭で既にreturn済み）。
    final targetCalendarId = existingCalendarId ?? selectedCalendarId;

    try {
      final result = await _calendar.upsertEvent(
        calendarId: targetCalendarId,
        eventId: task.calendarEventId,
        title: task.title,
        start: task.reminderAt!,
        end: task.reminderEndAt,
        allDay: task.isAllDay,
      );
      if (calendarSyncError) {
        calendarSyncError = false;
        notifyListeners();
      }
      return (eventId: result, calendarId: result == null ? null : targetCalendarId);
    } catch (e) {
      debugPrint('calendar sync failed: $e');
      if (await _calendarStillExists(targetCalendarId)) {
        if (!calendarSyncError) {
          calendarSyncError = true;
          notifyListeners();
        }
        return (eventId: task.calendarEventId, calendarId: task.calendarId);
      }
      // 作成先のカレンダー自体が無くなっている。古い予定への参照も一緒に
      // 手放す——同じカレンダーIDで再試行しても二度と成功しない。
      if (calendarSyncError) {
        calendarSyncError = false;
        notifyListeners();
      }
      return (eventId: null, calendarId: null);
    }
  }

  Future<void> _deleteTaskCalendarEvent(TaskItem task) async {
    if (task.calendarEventId == null) return;
    // 予定が実際に存在するカレンダーを対象にする（[_syncTaskCalendarEvent]と
    // 同じ理由）。切替対応前のデータで[calendarId]が無い場合のみ、現在選択中の
    // カレンダーへフォールバックする。
    final calendarId =
        task.calendarId ?? await _calendarSettings.getCalendarId();
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
      final String? result;
      if (dueDate == null) {
        if (task.appleReminderId != null) {
          await _appleReminders.deleteReminder(task.appleReminderId!);
        }
        result = null;
      } else {
        result = await _appleReminders.upsertReminder(
          listId: listId,
          reminderId: task.appleReminderId,
          title: task.title,
          dueDate: dueDate,
          includesTime: task.reminderAt != null && !task.isAllDay,
          completed: task.done,
        );
      }
      if (calendarSyncError) {
        calendarSyncError = false;
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('apple reminders sync failed: $e');
      if (!calendarSyncError) {
        calendarSyncError = true;
        notifyListeners();
      }
      return task.appleReminderId;
    }
  }

  Future<void> _deleteTaskAppleReminder(TaskItem task) async {
    if (task.appleReminderId == null) return;
    // ネイティブ側のdeleteReminder(AppleRemindersChannel.swift)はreminderIdだけで
    // EKReminderをグローバルに検索して削除でき、リストIDを必要としない。以前は
    // ここで「現在選択中のリマインダーリスト」の取得を必須にしていたため、連携を
    // OFFにした（listIdがnullになる）後にタスクを削除すると、実際のリマインダーは
    // Apple Reminders側に永久に残り続けていた（カレンダー連携で既に修正した
    // 孤立バグと同じ構造）。listIdの有無に関わらず常に削除を試みる。
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
    for (var task in saved.tasks) {
      if (task.id != null && task.notifyAt != null) {
        final scheduled = await _reminders.scheduleTaskReminder(
          taskId: task.id!,
          title: task.title,
          scheduledAt: task.notifyAt!,
        );
        // AIが音声から解析したnotify_atが、保存時点で既に過去になっている
        // ことがある（例:「15時にリマインドして」を15時より後に保存した場合）。
        // 通知は予約されないのに画面上は「リマインダー設定済み」に見える
        // 状態を残さないよう、DB・以後の表示側の両方でnotify_atをクリアする。
        if (!scheduled) {
          await _db.updateTaskNotifyAt(task.id!, null);
          task = task.copyWith(clearNotify: true);
        }
      }
      if (task.id != null) {
        final calendarSync = await _syncTaskCalendarEvent(task);
        final eventId = calendarSync.eventId;
        if (eventId != task.calendarEventId ||
            calendarSync.calendarId != task.calendarId) {
          await _db.updateTaskCalendarEventId(
            task.id!,
            eventId,
            calendarId: calendarSync.calendarId,
          );
        }
        final reminderId = await _syncTaskAppleReminder(task);
        if (reminderId != task.appleReminderId) {
          await _db.updateTaskAppleReminderId(task.id!, reminderId);
        }
        syncedTasks.add(
          task.copyWith(
            calendarEventId: eventId,
            clearCalendarEventId: eventId == null,
            calendarId: calendarSync.calendarId,
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
    String? calendarId = task.calendarId;
    if (task.reminderAt != null) {
      final calendarSync = await _syncTaskCalendarEvent(updatedTask);
      eventId = calendarSync.eventId;
      calendarId = calendarSync.calendarId;
      if (eventId != task.calendarEventId || calendarId != task.calendarId) {
        await _db.updateTaskCalendarEventId(
          task.id!,
          eventId,
          calendarId: calendarId,
        );
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
        calendarId: calendarId,
        appleReminderId: reminderId,
        clearAppleReminderId: reminderId == null,
      );
    }).toList();
    entries[index] = entries[index].copyWith(tasks: updatedTasks);
    notifyListeners();
    _trackSync(_cloudSync.pushEntry(entries[index]));
  }

  /// Notion連携(1タップ送信)でタスクを送信し、成功したら作成されたNotionページの
  /// URLをローカルへ永続化する。ユーザー操作起点の1回きりの送信のため、カレンダー/
  /// リマインダー同期と違い失敗を握りつぶさず[BackendServiceException]をそのまま
  /// 投げる(呼び出し元の編集画面がSnackBarで結果を見せる)。
  Future<String> sendTaskToNotion(
    JournalEntry entry,
    TaskItem task, {
    required String locale,
  }) async {
    if (task.id == null) {
      throw StateError('sendTaskToNotion called on an unsaved task');
    }
    final pageUrl = await _backend.notionSendItem(
      title: task.title,
      content: task.dueHint ?? '',
      category: 'Task',
      date: entry.createdAt,
      dueDate: task.dueDate,
      done: task.done,
      locale: locale,
    );
    await _db.updateTaskNotionPageUrl(task.id!, pageUrl);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      final updatedTasks = entries[index].tasks.map((t) {
        if (t.id != task.id) return t;
        return t.copyWith(notionPageUrl: pageUrl);
      }).toList();
      entries[index] = entries[index].copyWith(tasks: updatedTasks);
      notifyListeners();
    }
    return pageUrl;
  }

  /// [sendTaskToNotion]の日記/アイデア版。
  Future<String> sendNoteToNotion(
    JournalEntry entry,
    NoteItem note, {
    required String locale,
  }) async {
    if (note.id == null) {
      throw StateError('sendNoteToNotion called on an unsaved note');
    }
    final rawTitle = (note.title ?? '').trim();
    final fallback = note.content.trim();
    final title = rawTitle.isNotEmpty
        ? rawTitle
        : (fallback.length > 80 ? '${fallback.substring(0, 80)}…' : fallback);
    final category = note.category == kNoteCategoryIdea ? 'Idea' : 'Diary';
    final pageUrl = await _backend.notionSendItem(
      title: title,
      content: note.content,
      category: category,
      date: entry.createdAt,
      locale: locale,
    );
    await _db.updateNoteNotionPageUrl(note.id!, pageUrl);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      final updatedNotes = entries[index].notes.map((n) {
        if (n.id != note.id) return n;
        return n.copyWith(notionPageUrl: pageUrl);
      }).toList();
      entries[index] = entries[index].copyWith(notes: updatedNotes);
      notifyListeners();
    }
    return pageUrl;
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
    // 現在のサブスク状態([canSyncMedia])に関わらず常に削除を試みる——アップロード
    // (課金対象の機能)とは違い、後片付けはいつでも許可しないと、Pro/メディア同期が
    // 失効した後に削除したエントリの写真・動画がStorageに残り続け、5GB上限を
    // 永久に圧迫してしまう。アップロードされたことが無ければStorage側で
    // 空振り（no-op）になるだけで害は無い。
    _trackSync(_mediaSync.deleteAllMedia(entry.remoteId));
  }

  /// アカウント切り替え/アカウント削除で[DbService.wipeAllLocalData]がSQLiteの
  /// 行を丸ごと消す直前に呼ぶ。DB側は行ごと消えるため、消える前にこの端末上の
  /// 副作用（予約済みローカル通知、カレンダー予定、Appleリマインダー、添付画像
  /// ファイル）を先に片付けておかないと、前のアカウントの内容が端末に残り続けて
  /// しまう（例: 家族共有端末で別アカウントに切り替えた後、前の持ち主のタスク内容の
  /// 通知が鳴る）。クラウド（Firestore/Storage）側のデータには一切触れない——
  /// アカウント切り替えでは前の持ち主のクラウドデータは消さない仕様であり、
  /// アカウント削除ではサーバー側の`deleteAccount`が別途クラウド側を消すため。
  Future<void> teardownAllLocalSideEffects() async {
    for (final entry in entries) {
      for (final task in entry.tasks) {
        if (task.id != null) {
          await _reminders.cancelTaskReminder(task.id!);
        }
        await _deleteTaskCalendarEvent(task);
        await _deleteTaskAppleReminder(task);
      }
    }
    // 上のループはメモリ上の[entries]（＝現在の持ち主のもの）が正しく読み込め
    // ている前提だが、念のための安全網として通知は全消去もしておく。画像は
    // ディレクトリごと消すため、個別ファイルを辿る必要はない。
    await _reminders.cancelAll();
    await _images.deleteAllImages();
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
      // deleteEntryと同じ理由で、現在のサブスク状態に関わらず常に削除を試みる。
      _trackSync(_mediaSync.deleteAllMedia(updated.remoteId));
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
    final newImages = [
      for (final path in paths) EntryImage(entryId: entry.id!, path: path),
    ];
    entries[index] = entries[index].copyWith(
      images: [...entries[index].images, ...newImages],
    );
    notifyListeners();
    // 容量上限に達している場合は、静かに（同期エラー扱いにはせず）アップロード
    // 自体をスキップする——ファイルはローカルには残るので、上限に達した後も
    // 撮影・添付そのものは引き続きでき、データが失われることはない。
    if (canSyncMedia && mediaUsage?.isOverCap != true) {
      _trackSync(
        _mediaSync.uploadPendingMedia(
          entryId: entry.id!,
          remoteId: entry.remoteId,
        ),
      );
      unawaited(refreshMediaUsage());
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
      images: entries[index].images.where((i) => i.path != path).toList(),
    );
    notifyListeners();
    // deleteEntryと同じ理由で、現在のサブスク状態に関わらず常に削除を試みる。
    _trackSync(_mediaSync.deleteMedia(entry.remoteId, path));
  }

  /// 添付画像の自由配置（Pro限定）。[x]/[y]は正規化座標(0..1)、[scale]は
  /// 基準サイズに対する拡大率。クラウド同期は対象外（Storageには画像バイナリ
  /// しか無く、位置情報を運ぶチャンネルが無いため、端末ローカルにのみ保存する）。
  Future<void> updateImagePosition(
    JournalEntry entry,
    String path, {
    required double x,
    required double y,
    required double scale,
  }) async {
    if (entry.id == null) return;
    await _db.updateImagePosition(entry.id!, path, x: x, y: y, scale: scale);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    entries[index] = entries[index].copyWith(
      images: [
        for (final image in entries[index].images)
          if (image.path == path)
            image.copyWith(x: x, y: y, scale: scale)
          else
            image,
      ],
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

  Future<void> updateIdeaMeta(
    JournalEntry entry,
    NoteItem note, {
    required String? ideaStatus,
    required bool pinned,
    required String? tag,
  }) async {
    if (note.id == null) return;
    await _db.updateIdeaMeta(
      note.id!,
      ideaStatus: ideaStatus,
      pinned: pinned,
      tag: tag,
    );
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    final updatedNotes = entries[index].notes.map((n) {
      if (n.id != note.id) return n;
      return n.copyWith(
        ideaStatus: ideaStatus,
        clearIdeaStatus: ideaStatus == null,
        pinned: pinned,
        tag: tag,
        clearTag: tag == null,
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
    final calendarSync = await _syncTaskCalendarEvent(
      task.copyWith(title: trimmed),
    );
    final eventId = calendarSync.eventId;
    if (eventId != task.calendarEventId ||
        calendarSync.calendarId != task.calendarId) {
      await _db.updateTaskCalendarEventId(
        task.id!,
        eventId,
        calendarId: calendarSync.calendarId,
      );
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
        calendarId: calendarSync.calendarId,
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
    final calendarSync = await _syncTaskCalendarEvent(scheduledTask);
    final eventId = calendarSync.eventId;
    if (eventId != task.calendarEventId ||
        calendarSync.calendarId != task.calendarId) {
      await _db.updateTaskCalendarEventId(
        task.id!,
        eventId,
        calendarId: calendarSync.calendarId,
      );
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
          calendarId: calendarSync.calendarId,
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
      syncErrorReason = success
          ? null
          : (_cloudSync.lastFailureReason ?? _mediaSync.lastFailureReason);
      await load();
    }
  }
}
