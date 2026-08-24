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
      version: 2,
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
            done INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER NOT NULL,
            category TEXT NOT NULL,
            content TEXT NOT NULL,
            FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE entries ADD COLUMN comfort_message TEXT');
          await db.execute('ALTER TABLE tasks ADD COLUMN due_date TEXT');
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

    for (final task in entry.tasks) {
      await db.insert('tasks', {
        'entry_id': entryId,
        'title': task.title,
        'due_hint': task.dueHint,
        'due_date': task.dueDate?.toIso8601String(),
        'done': 0,
      });
    }
    for (final note in entry.notes) {
      await db.insert('notes', {
        'entry_id': entryId,
        'category': note.category,
        'content': note.content,
      });
    }

    return JournalEntry(
      id: entryId,
      createdAt: entry.createdAt,
      summary: entry.summary,
      tasks: entry.tasks,
      notes: entry.notes,
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

      entries.add(JournalEntry(
        id: entryId,
        createdAt: DateTime.parse(row['created_at'] as String),
        summary: row['summary'] as String,
        tasks: taskRows.map(TaskItem.fromMap).toList(),
        notes: noteRows.map(NoteItem.fromMap).toList(),
        comfortMessage: row['comfort_message'] as String?,
      ));
    }
    return entries;
  }

  /// 直近 [days] 日分の、日付ごとの記録件数を返す（ヒートマップカレンダー用）。
  /// キーは 'yyyy-MM-dd'（ローカル日付）。
  Future<Map<String, int>> fetchEntryCountsByDate({int days = 90}) async {
    final db = await _database;
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await db.query(
      'entries',
      columns: ['created_at'],
      where: 'created_at >= ?',
      whereArgs: [since.toIso8601String()],
    );

    final counts = <String, int>{};
    for (final row in rows) {
      final createdAt = DateTime.parse(row['created_at'] as String).toLocal();
      final key = _dateKey(createdAt);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

  Future<void> deleteEntry(int entryId) async {
    final db = await _database;
    await db.delete('tasks', where: 'entry_id = ?', whereArgs: [entryId]);
    await db.delete('notes', where: 'entry_id = ?', whereArgs: [entryId]);
    await db.delete('entries', where: 'id = ?', whereArgs: [entryId]);
  }
}
