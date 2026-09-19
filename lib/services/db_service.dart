import 'dart:math';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/emotion_tag.dart';
import '../models/entry_image.dart';
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

/// `ALTER TABLE ... ADD COLUMN`をべき等にする。過去に_database getterの
/// 競合（同時に複数回_open()が走ってしまう不具合、修正済み）でonUpgradeが
/// 一部だけ実行された端末があり、カラムは追加済みなのにuser_versionだけ
/// 古いまま進まなくなっていた。以後同じ状況が起きても先に進めるよう、
/// 既に存在するカラムへのALTER TABLEは無視する。
Future<void> _addColumnIfMissing(Database db, String sql) async {
  try {
    await db.execute(sql);
  } on DatabaseException catch (e) {
    if (!e.toString().contains('duplicate column name')) rethrow;
  }
}

class DbService {
  static final DbService instance = DbService._internal();
  DbService._internal();

  Future<Database>? _dbFuture;

  // ほぼ同時に複数箇所（各Storeのロードなど）からこのgetterが呼ばれると、
  // 単に「Database?をキャッシュする」実装ではDatabaseが確立する前に
  // _open()が並行して複数回走ってしまい、onUpgradeのマイグレーション
  // （ALTER TABLE）が重複実行されて"duplicate column name"エラーで
  // 失敗する不具合があった。Futureそのものをメモ化することで、後から来た
  // 呼び出しは同じ1つの_open()呼び出しを待つようにする。
  Future<Database> get _database => _dbFuture ??= _open();

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'voicejournal.db');
    return openDatabase(
      path,
      version: 29,
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
            remote_id TEXT,
            updated_at TEXT
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
            calendar_id TEXT,
            apple_reminder_id TEXT,
            apple_reminder_list_id TEXT,
            is_all_day INTEGER NOT NULL DEFAULT 0,
            notify_at TEXT,
            notion_page_url TEXT,
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
            idea_status TEXT,
            pinned INTEGER NOT NULL DEFAULT 0,
            tag TEXT,
            notion_page_url TEXT,
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
            pos_x REAL,
            pos_y REAL,
            scale REAL,
            FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE weekly_reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            week_key TEXT NOT NULL,
            week_start TEXT NOT NULL,
            week_end TEXT NOT NULL,
            mood_headline TEXT NOT NULL,
            emotion_narrative TEXT NOT NULL,
            top_keywords_json TEXT NOT NULL,
            shining_ideas_json TEXT NOT NULL,
            highlight_quote_json TEXT NOT NULL,
            advice TEXT NOT NULL,
            weekly_letter TEXT NOT NULL DEFAULT '',
            emotion_counts_json TEXT NOT NULL,
            daily_emotions_json TEXT NOT NULL,
            daily_emotion_counts_json TEXT,
            mood_moments_json TEXT NOT NULL DEFAULT '[]',
            brain_map_json TEXT NOT NULL DEFAULT '[]',
            diary_count INTEGER NOT NULL,
            idea_count INTEGER NOT NULL,
            total_tasks INTEGER NOT NULL,
            completed_tasks INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            entry_ids_signature TEXT NOT NULL DEFAULT '',
            locale TEXT NOT NULL DEFAULT '',
            letter_unlocked INTEGER NOT NULL DEFAULT 0,
            UNIQUE(week_key, locale)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addColumnIfMissing(
            db,
            'ALTER TABLE entries ADD COLUMN comfort_message TEXT',
          );
          await _addColumnIfMissing(
            db,
            'ALTER TABLE tasks ADD COLUMN due_date TEXT',
          );
        }
        if (oldVersion < 3) {
          await _addColumnIfMissing(
            db,
            'ALTER TABLE tasks ADD COLUMN reminder_at TEXT',
          );
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS entry_images (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              entry_id INTEGER NOT NULL,
              path TEXT NOT NULL,
              sort_order INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 5) {
          await _addColumnIfMissing(
            db,
            'ALTER TABLE notes ADD COLUMN title TEXT',
          );
        }
        if (oldVersion < 6) {
          await _addColumnIfMissing(
            db,
            'ALTER TABLE entries ADD COLUMN emotion TEXT',
          );
        }
        if (oldVersion < 7) {
          await _addColumnIfMissing(
            db,
            'ALTER TABLE tasks ADD COLUMN calendar_event_id TEXT',
          );
        }
        if (oldVersion < 8) {
          await _addColumnIfMissing(
            db,
            'ALTER TABLE tasks ADD COLUMN reminder_end_at TEXT',
          );
        }
        if (oldVersion < 9) {
          await _addColumnIfMissing(
            db,
            'ALTER TABLE notes ADD COLUMN font_family_index INTEGER',
          );
          await _addColumnIfMissing(
            db,
            'ALTER TABLE notes ADD COLUMN text_color INTEGER',
          );
          await _addColumnIfMissing(
            db,
            'ALTER TABLE notes ADD COLUMN font_scale REAL',
          );
        }
        if (oldVersion < 10) {
          await _addColumnIfMissing(
            db,
            'ALTER TABLE tasks ADD COLUMN is_all_day INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 11) {
          await _addColumnIfMissing(
            db,
            'ALTER TABLE entries ADD COLUMN remote_id TEXT',
          );
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_entries_remote_id ON entries(remote_id)',
          );
          final rows = await db.query(
            'entries',
            columns: ['id'],
            where: 'remote_id IS NULL',
          );
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
          await _addColumnIfMissing(
            db,
            'ALTER TABLE notes ADD COLUMN background_id TEXT',
          );
        }
        if (oldVersion < 13) {
          // 「通知時刻」を「開始・終了時間（カレンダー用）」から独立させる。既存タスクは
          // 従来どおり開始時刻に通知していたはずなので、その値をそのまま引き継ぐ
          // （以後はTaskEditScreenで両者を別々に変更できる）。
          await _addColumnIfMissing(
            db,
            'ALTER TABLE tasks ADD COLUMN notify_at TEXT',
          );
          await db.execute('UPDATE tasks SET notify_at = reminder_at');
        }
        if (oldVersion < 14) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS weekly_reports (
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
          await _addColumnIfMissing(
            db,
            'ALTER TABLE entry_images ADD COLUMN uploaded INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 16) {
          await _addColumnIfMissing(
            db,
            'ALTER TABLE tasks ADD COLUMN apple_reminder_id TEXT',
          );
        }
        if (oldVersion < 17) {
          await _addColumnIfMissing(
            db,
            'ALTER TABLE weekly_reports ADD COLUMN daily_emotion_counts_json TEXT',
          );
        }
        if (oldVersion < 18) {
          await _addColumnIfMissing(
            db,
            "ALTER TABLE weekly_reports ADD COLUMN weekly_letter TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 19) {
          await _addColumnIfMissing(
            db,
            "ALTER TABLE weekly_reports ADD COLUMN mood_moments_json TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 20) {
          await _addColumnIfMissing(
            db,
            "ALTER TABLE weekly_reports ADD COLUMN brain_map_json TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 21) {
          await _addColumnIfMissing(
            db,
            'ALTER TABLE notes ADD COLUMN idea_status TEXT',
          );
          await _addColumnIfMissing(
            db,
            'ALTER TABLE notes ADD COLUMN pinned INTEGER NOT NULL DEFAULT 0',
          );
          await _addColumnIfMissing(
            db,
            'ALTER TABLE notes ADD COLUMN tag TEXT',
          );
        }
        if (oldVersion < 22) {
          // 週次レポートのキャッシュ判定を件数だけでなく実際の記録idの集合でも
          // 検証できるようにする列。既存行はデフォルト値''になり、次回の判定で
          // 必ず不一致(=再生成)扱いになる想定通りの挙動。
          await _addColumnIfMissing(
            db,
            "ALTER TABLE weekly_reports ADD COLUMN entry_ids_signature TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 23) {
          // 日記添付画像の自由配置（Pro限定）用。NULLのままなら「まだ動かして
          // いない」を意味し、キャンバス側で自動的に並べる。
          await _addColumnIfMissing(
            db,
            'ALTER TABLE entry_images ADD COLUMN pos_x REAL',
          );
          await _addColumnIfMissing(
            db,
            'ALTER TABLE entry_images ADD COLUMN pos_y REAL',
          );
          await _addColumnIfMissing(
            db,
            'ALTER TABLE entry_images ADD COLUMN scale REAL',
          );
        }
        if (oldVersion < 24) {
          // Notion連携(1タップ送信)で送信済みのタスク/ノートが指す、作成された
          // NotionページのURL。未送信はNULL。
          await _addColumnIfMissing(
            db,
            'ALTER TABLE tasks ADD COLUMN notion_page_url TEXT',
          );
          await _addColumnIfMissing(
            db,
            'ALTER TABLE notes ADD COLUMN notion_page_url TEXT',
          );
        }
        if (oldVersion < 25) {
          // calendar_event_idが「どのカレンダーの予定か」を記録していなかった
          // ため、ユーザーが連携先カレンダーを切り替えると、以前作成した予定を
          // 二度と削除・更新できず孤立していた。予定を作った時点のカレンダーIDを
          // 別途保持し、以後はそのタスクの予定に対する操作は常にこのIDを使う
          // （現在選択中のカレンダーが何であってもブレない）。既存行はNULLの
          // ままになるため、移行前に作られた予定については従来どおり現在選択中の
          // カレンダーへフォールバックする（journal_store.dart参照）。
          await _addColumnIfMissing(
            db,
            'ALTER TABLE tasks ADD COLUMN calendar_id TEXT',
          );
        }
        if (oldVersion < 26) {
          // 週次レポートのキャッシュ判定に表示言語を含めていなかったため、
          // ある言語設定で一度生成したレポートを別の言語に切り替えた後も、
          // 中身（キーワード・レター等）が古い言語のまま表示され続けていた。
          // 既存行はデフォルト値''になり、現在の表示言語と一致しないため
          // 次回開いたときに必ず再生成される。
          await _addColumnIfMissing(
            db,
            "ALTER TABLE weekly_reports ADD COLUMN locale TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 27) {
          // v26でlocale列を足したが、week_keyのUNIQUE制約はそのままだった
          // ため、saveWeeklyReportのupsert(ConflictAlgorithm.replace)が
          // week_key単位で行を上書きしてしまい、別言語で生成し直すと前の
          // 言語のスナップショットが破壊されていた。一意制約を
          // (week_key, locale)の組に変更する必要があるが、SQLiteはUNIQUE
          // 制約の変更をALTER TABLEでサポートしないため、テーブルを
          // 作り直す。
          //
          // 併せて、「先週比」比較で使っていた「week_endが日曜20:00固定なら
          // 確定済みの週」という判定を、週の集計対象期間を正しく拡張する
          // 修正（entries.whereの境界の隙間で日曜20:00〜月曜0:00の記録が
          // 毎週必ず取りこぼされていた問題の修正）に伴って廃止する。以後は
          // week_endが「週の実際の終端」を表すようになり、そこから解禁済み
          // かどうかを逆算できなくなるため、letter_unlocked列を新設し、
          // 既存行は保存時点のweek_start/week_endから当時解禁済みだったか
          // どうかを逆算して埋める。
          await db.execute('''
            CREATE TABLE weekly_reports_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              week_key TEXT NOT NULL,
              week_start TEXT NOT NULL,
              week_end TEXT NOT NULL,
              mood_headline TEXT NOT NULL,
              emotion_narrative TEXT NOT NULL,
              top_keywords_json TEXT NOT NULL,
              shining_ideas_json TEXT NOT NULL,
              highlight_quote_json TEXT NOT NULL,
              advice TEXT NOT NULL,
              weekly_letter TEXT NOT NULL DEFAULT '',
              emotion_counts_json TEXT NOT NULL,
              daily_emotions_json TEXT NOT NULL,
              daily_emotion_counts_json TEXT,
              mood_moments_json TEXT NOT NULL DEFAULT '[]',
              brain_map_json TEXT NOT NULL DEFAULT '[]',
              diary_count INTEGER NOT NULL,
              idea_count INTEGER NOT NULL,
              total_tasks INTEGER NOT NULL,
              completed_tasks INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              entry_ids_signature TEXT NOT NULL DEFAULT '',
              locale TEXT NOT NULL DEFAULT '',
              letter_unlocked INTEGER NOT NULL DEFAULT 0,
              UNIQUE(week_key, locale)
            )
          ''');
          // 移行前はweek_keyがUNIQUEだったため、既存行の間でweek_keyの重複は
          // 起こり得ない（1週につき常に1件）。そのままコピーしてよい。
          await db.execute('''
            INSERT INTO weekly_reports_new (
              id, week_key, week_start, week_end, mood_headline,
              emotion_narrative, top_keywords_json, shining_ideas_json,
              highlight_quote_json, advice, weekly_letter,
              emotion_counts_json, daily_emotions_json,
              daily_emotion_counts_json, mood_moments_json, brain_map_json,
              diary_count, idea_count, total_tasks, completed_tasks,
              created_at, entry_ids_signature, locale
            )
            SELECT
              id, week_key, week_start, week_end, mood_headline,
              emotion_narrative, top_keywords_json, shining_ideas_json,
              highlight_quote_json, advice, weekly_letter,
              emotion_counts_json, daily_emotions_json,
              daily_emotion_counts_json, mood_moments_json, brain_map_json,
              diary_count, idea_count, total_tasks, completed_tasks,
              created_at, entry_ids_signature, locale
            FROM weekly_reports
          ''');
          await db.execute('DROP TABLE weekly_reports');
          await db.execute(
            'ALTER TABLE weekly_reports_new RENAME TO weekly_reports',
          );

          final rows = await db.query(
            'weekly_reports',
            columns: ['id', 'week_start', 'week_end'],
          );
          for (final row in rows) {
            final weekStart = DateTime.tryParse(row['week_start'] as String);
            final weekEnd = DateTime.tryParse(row['week_end'] as String);
            if (weekStart == null || weekEnd == null) continue;
            final cutoff = weekStart.add(const Duration(days: 6, hours: 20));
            final wasUnlocked = !weekEnd.isBefore(cutoff);
            if (wasUnlocked) {
              await db.update(
                'weekly_reports',
                {'letter_unlocked': 1},
                where: 'id = ?',
                whereArgs: [row['id']],
              );
            }
          }
        }
        if (oldVersion < 28) {
          // apple_reminder_idが「どのリマインダーリストの項目か」を記録して
          // いなかったため、calendar_id（v25）と同じ理由の不具合があった:
          // ユーザーが連携先リマインダーリストを切り替えた後にタスクを編集・
          // 完了操作すると、既存のリマインダーが無断で新しいリストへ移動して
          // いた（Apple Reminders側のcalendarプロパティを、現在選択中のリスト
          // で上書きしてしまうため）。以後は作成時点のリストIDを別途保持し、
          // 既存リマインダーへの更新は常にこのIDが指すリストを対象にする。
          // 既存行はNULLのままになるため、移行前に作られたリマインダーに
          // ついては従来どおり現在選択中のリストへフォールバックする
          // （journal_store.dart参照）。
          await _addColumnIfMissing(
            db,
            'ALTER TABLE tasks ADD COLUMN apple_reminder_list_id TEXT',
          );
        }
        if (oldVersion < 29) {
          // fullSyncが同じremoteIdのエントリを端末とリモートの両方で見つけた際に
          // どちらの内容が新しいか判定できず、常にローカル側の(古いかもしれない)
          // 内容でリモートを無条件に上書きしてしまっていた不具合の修正用
          // ([[project_voicejournal_knowledge_base_chat]]参照)。以後は
          // エントリの内容(summary/tasks/notes/emotion/comfort_message)を
          // 変更するたびにこの列を更新し、fullSyncはこれとFirestore側の
          // 同名フィールドを比較して新しい方を採用する。既存行にはこの概念が
          // 無かったため、created_atをそのまま「最終更新時刻」の代わりとして
          // 埋める(実際の最終編集時刻より古い可能性はあるが、少なくとも
          // 「常にローカルが勝つ」よりは正確な比較ができる)。
          await _addColumnIfMissing(
            db,
            'ALTER TABLE entries ADD COLUMN updated_at TEXT',
          );
          await db.execute(
            'UPDATE entries SET updated_at = created_at WHERE updated_at IS NULL',
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
      'updated_at': entry.updatedAt.toIso8601String(),
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
        'idea_status': note.ideaStatus,
        'pinned': note.pinned ? 1 : 0,
        'tag': note.tag,
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
          ideaStatus: note.ideaStatus,
          pinned: note.pinned,
          tag: note.tag,
        ),
      );
    }

    return JournalEntry(
      id: entryId,
      remoteId: remoteId,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
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
          // 移行(v29)未完了/バックフィル漏れの行に対する保険としてcreated_atへ
          // フォールバックする。通常はマイグレーションで必ず埋まっている。
          updatedAt:
              DateTime.tryParse(row['updated_at'] as String? ?? '') ??
              DateTime.parse(row['created_at'] as String),
          summary: row['summary'] as String,
          tasks: (tasksByEntry[row['id'] as int] ?? const [])
              .map(TaskItem.fromMap)
              .toList(),
          notes: (notesByEntry[row['id'] as int] ?? const [])
              .map(NoteItem.fromMap)
              .toList(),
          comfortMessage: row['comfort_message'] as String?,
          emotion: EmotionTag.fromId(row['emotion'] as String?),
          images: (imagesByEntry[row['id'] as int] ?? const [])
              .map(
                (r) => EntryImage(
                  id: r['id'] as int,
                  entryId: r['entry_id'] as int,
                  path: r['path'] as String,
                  sortOrder: r['sort_order'] as int,
                  x: r['pos_x'] as double?,
                  y: r['pos_y'] as double?,
                  scale: r['scale'] as double?,
                ),
              )
              .toList(),
        ),
    ];
  }

  /// [x]/[y]/[scale]を更新する（Pro限定の自由配置機能）。[x]/[y]は正規化座標
  /// (0..1)、[scale]は基準サイズに対する拡大率。
  Future<void> updateImagePosition(
    int entryId,
    String path, {
    required double x,
    required double y,
    required double scale,
  }) async {
    final db = await _database;
    await db.update(
      'entry_images',
      {'pos_x': x, 'pos_y': y, 'scale': scale},
      where: 'entry_id = ? AND path = ?',
      whereArgs: [entryId, path],
    );
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

  /// アイデアの検討状況・ピン留め・タグを更新する。[ideaStatus]/[tag]はnullを
  /// 渡すと「指定なし」として保存される。
  Future<void> updateIdeaMeta(
    int noteId, {
    required String? ideaStatus,
    required bool pinned,
    required String? tag,
  }) async {
    final db = await _database;
    await db.update(
      'notes',
      {'idea_status': ideaStatus, 'pinned': pinned ? 1 : 0, 'tag': tag},
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

  Future<void> updateTaskCalendarEventId(
    int taskId,
    String? eventId, {
    String? calendarId,
  }) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'calendar_event_id': eventId, 'calendar_id': calendarId},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> updateTaskAppleReminderId(
    int taskId,
    String? reminderId, {
    String? listId,
  }) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'apple_reminder_id': reminderId, 'apple_reminder_list_id': listId},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Notion連携(1タップ送信)で送信に成功した際、作成されたNotionページのURLを保存する。
  Future<void> updateTaskNotionPageUrl(int taskId, String? pageUrl) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'notion_page_url': pageUrl},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Notion連携(1タップ送信)で送信に成功した際、作成されたNotionページのURLを保存する。
  Future<void> updateNoteNotionPageUrl(int noteId, String? pageUrl) async {
    final db = await _database;
    await db.update(
      'notes',
      {'notion_page_url': pageUrl},
      where: 'id = ?',
      whereArgs: [noteId],
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

  /// エントリ内容(summary/tasks/notes/emotion/comfort_message)を変更する
  /// メソッドから呼ぶ。[JournalStore]の各更新メソッドはtasks/notesの各行を
  /// 個別のメソッドで更新するため、親のentries行の`updated_at`はここで
  /// 別途明示的に更新する必要がある([fullSync]の新旧比較の基準になる)。
  Future<void> touchEntry(int entryId, DateTime updatedAt) async {
    final db = await _database;
    await db.update(
      'entries',
      {'updated_at': updatedAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  /// [fullSync]がリモート側の方が新しい(updated_atが後)と判定した既存ローカル
  /// エントリに対して使う。ローカルの`id`(端末固有の連番)はそのまま維持しつつ、
  /// summary/comfort_message/emotion/created_at/updated_atとtasks/notesの
  /// 中身をリモートの内容で丸ごと置き換える(フィールド単位のマージではなく、
  /// タイムスタンプによるlast-write-winsの「巻き戻し」)。tasks/notesは
  /// entry_idに紐づく子テーブルごと作り直すため、置き換え前のtask/note idとの
  /// 対応は失われる — calendar_event_id/apple_reminder_id等、置き換え前の
  /// タスクが持っていた端末ローカルな連携リンクの後始末は呼び出し元
  /// ([JournalStore])の責任。entry_images(添付画像)はこのエントリのローカル
  /// 専用データ(クラウド同期対象外)のため一切触らない。
  Future<JournalEntry> replaceEntryContent(
    int entryId,
    JournalEntry remote,
  ) async {
    final db = await _database;
    await db.update(
      'entries',
      {
        'created_at': remote.createdAt.toIso8601String(),
        'summary': remote.summary,
        'comfort_message': remote.comfortMessage,
        'emotion': remote.emotion?.id,
        'updated_at': remote.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
    await db.delete('tasks', where: 'entry_id = ?', whereArgs: [entryId]);
    await db.delete('notes', where: 'entry_id = ?', whereArgs: [entryId]);

    final savedTasks = <TaskItem>[];
    for (final task in remote.tasks) {
      final taskId = await db.insert('tasks', {
        'entry_id': entryId,
        'title': task.title,
        'due_hint': task.dueHint,
        'due_date': task.dueDate?.toIso8601String(),
        'reminder_at': task.reminderAt?.toIso8601String(),
        'reminder_end_at': task.reminderEndAt?.toIso8601String(),
        'done': task.done ? 1 : 0,
        'is_all_day': task.isAllDay ? 1 : 0,
        'notify_at': task.notifyAt?.toIso8601String(),
        'notion_page_url': task.notionPageUrl,
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
          done: task.done,
          isAllDay: task.isAllDay,
          notifyAt: task.notifyAt,
          notionPageUrl: task.notionPageUrl,
        ),
      );
    }
    final savedNotes = <NoteItem>[];
    for (final note in remote.notes) {
      final noteId = await db.insert('notes', {
        'entry_id': entryId,
        'category': note.category,
        'title': note.title,
        'content': note.content,
        'font_family_index': note.fontFamilyIndex,
        'text_color': note.textColorValue,
        'font_scale': note.fontScale,
        'background_id': note.backgroundId,
        'idea_status': note.ideaStatus,
        'pinned': note.pinned ? 1 : 0,
        'tag': note.tag,
        'notion_page_url': note.notionPageUrl,
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
          ideaStatus: note.ideaStatus,
          pinned: note.pinned,
          tag: note.tag,
          notionPageUrl: note.notionPageUrl,
        ),
      );
    }

    return JournalEntry(
      id: entryId,
      remoteId: remote.remoteId,
      createdAt: remote.createdAt,
      updatedAt: remote.updatedAt,
      summary: remote.summary,
      tasks: savedTasks,
      notes: savedNotes,
      comfortMessage: remote.comfortMessage,
      emotion: remote.emotion,
    );
  }

  /// アカウント削除時に端末ローカルのデータを全て消す。`entries`を消せば
  /// `tasks`/`notes`/`entry_images`はON DELETE CASCADEで連動して消えるが、
  /// `weekly_reports`はentriesに外部キーで紐づいていない独立テーブルなので
  /// 明示的に消す必要がある。
  Future<void> wipeAllLocalData() async {
    final db = await _database;
    await db.delete('entries');
    await db.delete('weekly_reports');
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

  /// [weekKey]+[SavedWeeklyReport.locale]の組で upsert する（一意制約は
  /// (week_key, locale)。[DbService._open]参照）。同じ週・同じ表示言語に
  /// 何度開いても最新の内容で上書きされるが、言語が違えば別行として残るため、
  /// 表示言語を切り替えても他方の言語のキャッシュを破壊しない。
  Future<void> saveWeeklyReport(SavedWeeklyReport report) async {
    final db = await _database;
    await db.insert(
      'weekly_reports',
      report.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 履歴一覧用。同じ週に複数言語のスナップショットが保存されている場合
  /// （現在進行中の週を複数の表示言語で開いた後、週が終わって履歴入りした
  /// 場合など）、週ごとに1件だけ（最後に生成されたもの）を返す——履歴画面は
  /// 「週の一覧」であって「(週,言語)の一覧」ではないため、同じ週が複数
  /// 並んで見えてしまうのを避ける。
  Future<List<SavedWeeklyReport>> listWeeklyReports() async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT wr.* FROM weekly_reports wr
      INNER JOIN (
        SELECT week_key, MAX(id) AS max_id
        FROM weekly_reports
        GROUP BY week_key
      ) latest ON wr.week_key = latest.week_key AND wr.id = latest.max_id
      ORDER BY wr.week_start DESC
    ''');
    return rows.map(SavedWeeklyReport.fromMap).toList();
  }

  /// 言語を問わず、その週で最後に保存されたスナップショットを1件返す
  /// （「先週比」比較用。比較に使うのは件数などの集計値のみで、言語ごとの
  /// テキストには依存しないため、locale一致は問わない）。
  Future<SavedWeeklyReport?> getWeeklyReportByWeekKey(String weekKey) async {
    final db = await _database;
    final rows = await db.query(
      'weekly_reports',
      where: 'week_key = ?',
      whereArgs: [weekKey],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SavedWeeklyReport.fromMap(rows.first);
  }

  /// 現在の週のキャッシュ判定用。[weekKey]と[locale]の両方が一致する行だけを
  /// 返す——一意制約が(week_key, locale)の組になったため、これで初めて
  /// 「今の表示言語で以前生成済みか」を正しく判定できる
  /// （[[project_voicejournal_knowledge_base_chat]]参照）。
  Future<SavedWeeklyReport?> getWeeklyReportByWeekKeyAndLocale(
    String weekKey,
    String locale,
  ) async {
    final db = await _database;
    final rows = await db.query(
      'weekly_reports',
      where: 'week_key = ? AND locale = ?',
      whereArgs: [weekKey, locale],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SavedWeeklyReport.fromMap(rows.first);
  }
}
