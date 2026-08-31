import 'dart:math';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';
import '../models/weekly_report.dart';

const String _kIdChars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

/// クラウド同期用の安定ID。Firestoreのドキュメント自動IDと同じ文字種・桁数で
/// 生成する（このファイルをcloud_firestoreに依存させないよう自前で生成する）。
String _generateLocalId() {
  final random = Random.secure();
  return List.generate(
    20,
    (_) => _kIdChars[random.nextInt(_kIdChars.length)],
  ).join();
}

class DbService {
  static final DbService instance = DbService._internal();
  DbService._internal();

  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final opened = await _open();
    _db = opened;
    return opened;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'voicejournal.db');
    return openDatabase(
      path,
      version: 16,
      // tasks/notes/entry_imagesはON DELETE CASCADEをスキーマに宣言しているが、
      // SQLiteは外部キー制約自体をデフォルトで無効にしており、接続のたびに
      // 明示的に有効化しないとその宣言は一切効かない（各deleteメソッドが手動で
      // 子テーブルを削除しているのはそのため）。ここで有効化することで、
      // スキーマの宣言どおりに実際にカスケード削除されるようにする。
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL,
            summary TEXT NOT NULL,
            comfort_message TEXT,
            emotion TEXT,
            remote_id TEXT
          )
        ''');
        await db.execute(
          'CREATE UNIQUE INDEX idx_entries_remote_id ON entries(remote_id)',
        );
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            due_hint TEXT,
            due_date TEXT,
            reminder_at TEXT,
            reminder_end_at TEXT,
            done INTEGER NOT NULL DEFAULT 0,
            calendar_event_id TEXT,
            apple_reminder_id TEXT,
            is_all_day INTEGER NOT NULL DEFAULT 0,
            notify_at TEXT,
            FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER NOT NULL,
            category TEXT NOT NULL,
            title TEXT,
            content TEXT NOT NULL,
            font_family_index INTEGER,
            text_color INTEGER,
            font_scale REAL,
            background_id TEXT,
            FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE entry_images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER NOT NULL,
            path TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            uploaded INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE weekly_reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            week_key TEXT NOT NULL UNIQUE,
            week_start TEXT NOT NULL,
            week_end TEXT NOT NULL,
            mood_headline TEXT NOT NULL,
            emotion_narrative TEXT NOT NULL,
            top_keywords_json TEXT NOT NULL,
            shining_ideas_json TEXT NOT NULL,
            highlight_quote_json TEXT NOT NULL,
            advice TEXT NOT NULL,
            emotion_counts_json TEXT NOT NULL,
            daily_emotions_json TEXT NOT NULL,
            diary_count INTEGER NOT NULL,
            idea_count INTEGER NOT NULL,
            total_tasks INTEGER NOT NULL,
            completed_tasks INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE entries ADD COLUMN comfort_message TEXT',
          );
          await db.execute('ALTER TABLE tasks ADD COLUMN due_date TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE tasks ADD COLUMN reminder_at TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE entry_images (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              entry_id INTEGER NOT NULL,
              path TEXT NOT NULL,
              sort_order INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE notes ADD COLUMN title TEXT');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE entries ADD COLUMN emotion TEXT');
        }
        if (oldVersion < 7) {
          await db.execute(
            'ALTER TABLE tasks ADD COLUMN calendar_event_id TEXT',
          );
        }
        if (oldVersion < 8) {
          await db.execute('ALTER TABLE tasks ADD COLUMN reminder_end_at TEXT');
        }
        if (oldVersion < 9) {
          await db.execute(
            'ALTER TABLE notes ADD COLUMN font_family_index INTEGER',
          );
          await db.execute('ALTER TABLE notes ADD COLUMN text_color INTEGER');
          await db.execute('ALTER TABLE notes ADD COLUMN font_scale REAL');
        }
        if (oldVersion < 10) {
          await db.execute(
            'ALTER TABLE tasks ADD COLUMN is_all_day INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 11) {
          await db.execute('ALTER TABLE entries ADD COLUMN remote_id TEXT');
          await db.execute(
            'CREATE UNIQUE INDEX idx_entries_remote_id ON entries(remote_id)',
          );
          final rows = await db.query('entries', columns: ['id']);
          final batch = db.batch();
          for (final row in rows) {
            batch.update(
              'entries',
              {'remote_id': _generateLocalId()},
              where: 'id = ?',
              whereArgs: [row['id'] as int],
            );
          }
          await batch.commit(noResult: true);
        }
        if (oldVersion < 12) {
          await db.execute('ALTER TABLE notes ADD COLUMN background_id TEXT');
        }
        if (oldVersion < 13) {
          // 「通知時刻」を「開始・終了時間（カレンダー用）」から独立させる。既存タスクは
          // 従来どおり開始時刻に通知していたはずなので、その値をそのまま引き継ぐ
          // （以後はTaskEditScreenで両者を別々に変更できる）。
          await db.execute('ALTER TABLE tasks ADD COLUMN notify_at TEXT');
          await db.execute('UPDATE tasks SET notify_at = reminder_at');
        }
        if (oldVersion < 14) {
          await db.execute('''
            CREATE TABLE weekly_reports (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              week_key TEXT NOT NULL UNIQUE,
              week_start TEXT NOT NULL,
              week_end TEXT NOT NULL,
              mood_headline TEXT NOT NULL,
              emotion_narrative TEXT NOT NULL,
              top_keywords_json TEXT NOT NULL,
              shining_ideas_json TEXT NOT NULL,
              highlight_quote_json TEXT NOT NULL,
              advice TEXT NOT NULL,
              emotion_counts_json TEXT NOT NULL,
              daily_emotions_json TEXT NOT NULL,
              diary_count INTEGER NOT NULL,
              idea_count INTEGER NOT NULL,
              total_tasks INTEGER NOT NULL,
              completed_tasks INTEGER NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 15) {
          await db.execute(
            'ALTER TABLE entry_images ADD COLUMN uploaded INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 16) {
          await db.execute(
            'ALTER TABLE tasks ADD COLUMN apple_reminder_id TEXT',
          );
        }
      },
    );
  }

  Future<JournalEntry> insertEntry(JournalEntry entry) async {
    final db = await _database;
    final remoteId = entry.remoteId ?? _generateLocalId();
    final entryId = await db.insert('entries', {
      'created_at': entry.createdAt.toIso8601String(),
      'summary': entry.summary,
      'comfort_message': entry.comfortMessage,
      'emotion': entry.emotion?.id,
      'remote_id': remoteId,
    });

    final savedTasks = <TaskItem>[];
    for (final task in entry.tasks) {
      final taskId = await db.insert('tasks', {
        'entry_id': entryId,
        'title': task.title,
        'due_hint': task.dueHint,
        'due_date': task.dueDate?.toIso8601String(),
        'reminder_at': task.reminderAt?.toIso8601String(),
        'reminder_end_at': task.reminderEndAt?.toIso8601String(),
        'done': 0,
        'is_all_day': task.isAllDay ? 1 : 0,
        'notify_at': task.notifyAt?.toIso8601String(),
      });
      savedTasks.add(
        TaskItem(
          id: taskId,
          entryId: entryId,
          title: task.title,
          dueHint: task.dueHint,
          dueDate: task.dueDate,
          reminderAt: task.reminderAt,
          reminderEndAt: task.reminderEndAt,
          isAllDay: task.isAllDay,
          notifyAt: task.notifyAt,
        ),
      );
    }
    final savedNotes = <NoteItem>[];
    for (final note in entry.notes) {
      final noteId = await db.insert('notes', {
        'entry_id': entryId,
        'category': note.category,
        'title': note.title,
        'content': note.content,
        'font_family_index': note.fontFamilyIndex,
        'text_color': note.textColorValue,
        'font_scale': note.fontScale,
        'background_id': note.backgroundId,
      });
      savedNotes.add(
        NoteItem(
          id: noteId,
          entryId: entryId,
          category: note.category,
          title: note.title,
          content: note.content,
          fontFamilyIndex: note.fontFamilyIndex,
          textColorValue: note.textColorValue,
          fontScale: note.fontScale,
          backgroundId: note.backgroundId,
        ),
      );
    }

    return JournalEntry(
      id: entryId,
      remoteId: remoteId,
      createdAt: entry.createdAt,
      summary: entry.summary,
      tasks: savedTasks,
      notes: savedNotes,
      comfortMessage: entry.comfortMessage,
      emotion: entry.emotion,
    );
  }

  /// [rows]を`entry_id`ごとにグループ分けする。呼び出し元がorderByで指定した
  /// 並び順は、各グループ内での相対順序としてそのまま保たれる。
  Map<int, List<Map<String, Object?>>> _groupByEntryId(
    List<Map<String, Object?>> rows,
  ) {
    final byEntry = <int, List<Map<String, Object?>>>{};
    for (final row in rows) {
      (byEntry[row['entry_id'] as int] ??= []).add(row);
    }
    return byEntry;
  }

  /// エントリ1件ごとにtasks/notes/entry_imagesを逐次クエリするとエントリ数分
  /// だけ往復が発生する（N+1）ため、テーブルごとに1回ずつ全件取得してから
  /// entry_idでグループ分けする方式に変えている。
  Future<List<JournalEntry>> fetchEntries() async {
    final db = await _database;
    final entryRows = await db.query('entries', orderBy: 'created_at DESC');
    if (entryRows.isEmpty) return [];

    final tasksByEntry = _groupByEntryId(await db.query('tasks'));
    final notesByEntry = _groupByEntryId(await db.query('notes'));
    final imagesByEntry = _groupByEntryId(
      await db.query('entry_images', orderBy: 'sort_order ASC'),
    );

    return [
      for (final row in entryRows)
        JournalEntry(
          id: row['id'] as int,
          remoteId: row['remote_id'] as String?,
          createdAt: DateTime.parse(row['created_at'] as String),
          summary: row['summary'] as String,
          tasks: (tasksByEntry[row['id'] as int] ?? const [])
              .map(TaskItem.fromMap)
              .toList(),
          notes: (notesByEntry[row['id'] as int] ?? const [])
              .map(NoteItem.fromMap)
              .toList(),
          comfortMessage: row['comfort_message'] as String?,
          emotion: EmotionTag.fromId(row['emotion'] as String?),
          imagePaths: (imagesByEntry[row['id'] as int] ?? const [])
              .map((r) => r['path'] as String)
              .toList(),
        ),
    ];
  }

  /// [paths] を entryId のエントリに追加で紐付ける（既存の枚数の続きの並び順で）。
  Future<void> addImages(int entryId, List<String> paths) async {
    if (paths.isEmpty) return;
    final db = await _database;
    final existingCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM entry_images WHERE entry_id = ?',
            [entryId],
          ),
        ) ??
        0;
    final batch = db.batch();
    for (var i = 0; i < paths.length; i++) {
      batch.insert('entry_images', {
        'entry_id': entryId,
        'path': paths[i],
        'sort_order': existingCount + i,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteImage(int entryId, String path) async {
    final db = await _database;
    await db.delete(
      'entry_images',
      where: 'entry_id = ? AND path = ?',
      whereArgs: [entryId, path],
    );
  }

  /// まだクラウドにアップロードしていない（[uploaded]=0の）添付ファイルの
  /// ローカルパス一覧。
  Future<List<String>> getUnuploadedImagePaths(int entryId) async {
    final db = await _database;
    final rows = await db.query(
      'entry_images',
      columns: ['path'],
      where: 'entry_id = ? AND uploaded = 0',
      whereArgs: [entryId],
    );
    return rows.map((r) => r['path'] as String).toList();
  }

  Future<void> markImageUploaded(String path) async {
    final db = await _database;
    await db.update(
      'entry_images',
      {'uploaded': 1},
      where: 'path = ?',
      whereArgs: [path],
    );
  }

  Future<void> setTaskDone(int taskId, bool done) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> updateNote(
    int noteId, {
    String? title,
    required String content,
  }) async {
    final db = await _database;
    await db.update(
      'notes',
      {'title': title, 'content': content},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  /// 日記ノートの文字スタイル（フォント・色・サイズ倍率）と背景イラストを更新する。
  /// [textColorValue]/[backgroundId]はnullを渡すと「指定なし」として保存される。
  Future<void> updateNoteStyle(
    int noteId, {
    required int fontFamilyIndex,
    required int? textColorValue,
    required double fontScale,
    required String? backgroundId,
  }) async {
    final db = await _database;
    await db.update(
      'notes',
      {
        'font_family_index': fontFamilyIndex,
        'text_color': textColorValue,
        'font_scale': fontScale,
        'background_id': backgroundId,
      },
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  Future<void> updateEntryEmotion(int entryId, EmotionTag? emotion) async {
    final db = await _database;
    await db.update(
      'entries',
      {'emotion': emotion?.id},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<void> updateTaskTitle(int taskId, String title) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'title': title},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// タスクの「開始・終了時間」（カレンダー同期用）を更新する。プッシュ通知の
  /// 発火時刻（[updateTaskNotifyAt]）には一切影響しない。
  Future<void> updateTaskSchedule(
    int taskId,
    DateTime? startAt, {
    DateTime? endAt,
    bool isAllDay = false,
    DateTime? dueDate,
  }) async {
    final db = await _database;
    final values = <String, Object?>{
      'reminder_at': startAt?.toIso8601String(),
      'is_all_day': (startAt != null && isAllDay) ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
    };
    if (startAt == null || isAllDay) {
      values['reminder_end_at'] = null;
    } else {
      values['reminder_end_at'] = endAt?.toIso8601String();
    }
    await db.update('tasks', values, where: 'id = ?', whereArgs: [taskId]);
  }

  /// タスクのプッシュ通知の発火時刻を更新する。「開始・終了時間」（カレンダー同期用、
  /// [updateTaskSchedule]）には一切影響しない。
  Future<void> updateTaskNotifyAt(int taskId, DateTime? notifyAt) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'notify_at': notifyAt?.toIso8601String()},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> updateTaskCalendarEventId(int taskId, String? eventId) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'calendar_event_id': eventId},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> updateTaskAppleReminderId(int taskId, String? reminderId) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'apple_reminder_id': reminderId},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> deleteEntry(int entryId) async {
    final db = await _database;
    await db.delete('tasks', where: 'entry_id = ?', whereArgs: [entryId]);
    await db.delete('notes', where: 'entry_id = ?', whereArgs: [entryId]);
    await db.delete(
      'entry_images',
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );
    await db.delete('entries', where: 'id = ?', whereArgs: [entryId]);
  }

  /// entry単位ではなく、指定したnoteだけを削除する（日記/アイデア個別削除用）。
  Future<void> deleteNotes(List<int> noteIds) async {
    if (noteIds.isEmpty) return;
    final db = await _database;
    final placeholders = List.filled(noteIds.length, '?').join(',');
    await db.delete(
      'notes',
      where: 'id IN ($placeholders)',
      whereArgs: noteIds,
    );
  }

  /// entry単位ではなく、指定したtaskだけを削除する（タスク個別削除用）。
  Future<void> deleteTasks(List<int> taskIds) async {
    if (taskIds.isEmpty) return;
    final db = await _database;
    final placeholders = List.filled(taskIds.length, '?').join(',');
    await db.delete(
      'tasks',
      where: 'id IN ($placeholders)',
      whereArgs: taskIds,
    );
  }

  /// [weekKey]（週の月曜日の日付、例: '2026-08-24'）で upsert する。同じ週に
  /// 何度開いても最新の内容で上書きされる。
  Future<void> saveWeeklyReport(SavedWeeklyReport report) async {
    final db = await _database;
    await db.insert(
      'weekly_reports',
      report.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SavedWeeklyReport>> listWeeklyReports() async {
    final db = await _database;
    final rows = await db.query('weekly_reports', orderBy: 'week_start DESC');
    return rows.map(SavedWeeklyReport.fromMap).toList();
  }
}
