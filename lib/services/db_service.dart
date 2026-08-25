import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/journal_entry.dart';

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
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL,
            summary TEXT NOT NULL,
            comfort_message TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            due_hint TEXT,
            due_date TEXT,
            reminder_at TEXT,
            done INTEGER NOT NULL DEFAULT 0,
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
            FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE entry_images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER NOT NULL,
            path TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE entries ADD COLUMN comfort_message TEXT');
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
      },
    );
  }

  Future<JournalEntry> insertEntry(JournalEntry entry) async {
    final db = await _database;
    final entryId = await db.insert('entries', {
      'created_at': entry.createdAt.toIso8601String(),
      'summary': entry.summary,
      'comfort_message': entry.comfortMessage,
    });

    final savedTasks = <TaskItem>[];
    for (final task in entry.tasks) {
      final taskId = await db.insert('tasks', {
        'entry_id': entryId,
        'title': task.title,
        'due_hint': task.dueHint,
        'due_date': task.dueDate?.toIso8601String(),
        'reminder_at': task.reminderAt?.toIso8601String(),
        'done': 0,
      });
      savedTasks.add(TaskItem(
        id: taskId,
        entryId: entryId,
        title: task.title,
        dueHint: task.dueHint,
        dueDate: task.dueDate,
        reminderAt: task.reminderAt,
      ));
    }
    final savedNotes = <NoteItem>[];
    for (final note in entry.notes) {
      final noteId = await db.insert('notes', {
        'entry_id': entryId,
        'category': note.category,
        'title': note.title,
        'content': note.content,
      });
      savedNotes.add(NoteItem(
        id: noteId,
        entryId: entryId,
        category: note.category,
        title: note.title,
        content: note.content,
      ));
    }

    return JournalEntry(
      id: entryId,
      createdAt: entry.createdAt,
      summary: entry.summary,
      tasks: savedTasks,
      notes: savedNotes,
      comfortMessage: entry.comfortMessage,
    );
  }

  Future<List<JournalEntry>> fetchEntries() async {
    final db = await _database;
    final entryRows = await db.query('entries', orderBy: 'created_at DESC');

    final entries = <JournalEntry>[];
    for (final row in entryRows) {
      final entryId = row['id'] as int;
      final taskRows = await db.query(
        'tasks',
        where: 'entry_id = ?',
        whereArgs: [entryId],
      );
      final noteRows = await db.query(
        'notes',
        where: 'entry_id = ?',
        whereArgs: [entryId],
      );
      final imageRows = await db.query(
        'entry_images',
        where: 'entry_id = ?',
        whereArgs: [entryId],
        orderBy: 'sort_order ASC',
      );

      entries.add(JournalEntry(
        id: entryId,
        createdAt: DateTime.parse(row['created_at'] as String),
        summary: row['summary'] as String,
        tasks: taskRows.map(TaskItem.fromMap).toList(),
        notes: noteRows.map(NoteItem.fromMap).toList(),
        comfortMessage: row['comfort_message'] as String?,
        imagePaths: imageRows.map((r) => r['path'] as String).toList(),
      ));
    }
    return entries;
  }

  /// [paths] を entryId のエントリに追加で紐付ける（既存の枚数の続きの並び順で）。
  Future<void> addImages(int entryId, List<String> paths) async {
    if (paths.isEmpty) return;
    final db = await _database;
    final existingCount = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM entry_images WHERE entry_id = ?',
          [entryId],
        )) ??
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

  Future<void> setTaskDone(int taskId, bool done) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> updateNote(int noteId, {String? title, required String content}) async {
    final db = await _database;
    await db.update(
      'notes',
      {'title': title, 'content': content},
      where: 'id = ?',
      whereArgs: [noteId],
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

  Future<void> updateTaskReminder(int taskId, DateTime? reminderAt) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'reminder_at': reminderAt?.toIso8601String()},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> deleteEntry(int entryId) async {
    final db = await _database;
    await db.delete('tasks', where: 'entry_id = ?', whereArgs: [entryId]);
    await db.delete('notes', where: 'entry_id = ?', whereArgs: [entryId]);
    await db.delete('entry_images', where: 'entry_id = ?', whereArgs: [entryId]);
    await db.delete('entries', where: 'id = ?', whereArgs: [entryId]);
  }
}
