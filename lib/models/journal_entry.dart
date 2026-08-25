class TaskItem {
  final int? id;
  final int? entryId;
  final String title;
  final String? dueHint;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final bool done;

  TaskItem({
    this.id,
    this.entryId,
    required this.title,
    this.dueHint,
    this.dueDate,
    this.reminderAt,
    this.done = false,
  });

  TaskItem copyWith({bool? done}) {
    return TaskItem(
      id: id,
      entryId: entryId,
      title: title,
      dueHint: dueHint,
      dueDate: dueDate,
      reminderAt: reminderAt,
      done: done ?? this.done,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'entry_id': entryId,
      'title': title,
      'due_hint': dueHint,
      'due_date': dueDate?.toIso8601String(),
      'reminder_at': reminderAt?.toIso8601String(),
      'done': done ? 1 : 0,
    };
  }

  factory TaskItem.fromMap(Map<String, Object?> map) {
    final dueDateStr = map['due_date'] as String?;
    final reminderAtStr = map['reminder_at'] as String?;
    return TaskItem(
      id: map['id'] as int?,
      entryId: map['entry_id'] as int?,
      title: map['title'] as String,
      dueHint: map['due_hint'] as String?,
      dueDate: dueDateStr != null ? DateTime.tryParse(dueDateStr) : null,
      reminderAt: reminderAtStr != null ? DateTime.tryParse(reminderAtStr) : null,
      done: (map['done'] as int? ?? 0) == 1,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final dueDateStr = json['due_date'] as String?;
    final reminderAtStr = json['reminder_at'] as String?;
    return TaskItem(
      title: (json['title'] as String? ?? '').trim(),
      dueHint: json['due_hint'] as String?,
      dueDate: dueDateStr != null ? DateTime.tryParse(dueDateStr) : null,
      reminderAt: reminderAtStr != null ? DateTime.tryParse(reminderAtStr) : null,
    );
  }
}

class NoteItem {
  final int? id;
  final int? entryId;
  final String category;
  final String content;

  NoteItem({
    this.id,
    this.entryId,
    required this.category,
    required this.content,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'entry_id': entryId,
      'category': category,
      'content': content,
    };
  }

  factory NoteItem.fromMap(Map<String, Object?> map) {
    return NoteItem(
      id: map['id'] as int?,
      entryId: map['entry_id'] as int?,
      category: map['category'] as String,
      content: map['content'] as String,
    );
  }

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      category: (json['category'] as String? ?? 'メモ').trim(),
      content: (json['content'] as String? ?? '').trim(),
    );
  }
}

/// [NoteItem.category] の3分類のうち感情ログを示す値。
const String kNoteCategoryFeeling = '感情ログ';

/// [NoteItem.category] の3分類のうちアイデア・思いつきを示す値。
const String kNoteCategoryIdea = 'アイデア';

class JournalEntry {
  final int? id;
  final DateTime createdAt;
  final String summary;
  final List<TaskItem> tasks;
  final List<NoteItem> notes;
  final String? comfortMessage;
  final List<String> imagePaths;

  JournalEntry({
    this.id,
    required this.createdAt,
    required this.summary,
    required this.tasks,
    required this.notes,
    this.comfortMessage,
    this.imagePaths = const [],
  });

  JournalEntry copyWith({List<TaskItem>? tasks, List<String>? imagePaths}) {
    return JournalEntry(
      id: id,
      createdAt: createdAt,
      summary: summary,
      tasks: tasks ?? this.tasks,
      notes: notes,
      comfortMessage: comfortMessage,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}
