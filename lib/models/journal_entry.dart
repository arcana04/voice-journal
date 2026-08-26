import 'emotion_tag.dart';

class TaskItem {
  final int? id;
  final int? entryId;
  final String title;
  final String? dueHint;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final DateTime? reminderEndAt;
  final bool done;
  final String? calendarEventId;

  TaskItem({
    this.id,
    this.entryId,
    required this.title,
    this.dueHint,
    this.dueDate,
    this.reminderAt,
    this.reminderEndAt,
    this.done = false,
    this.calendarEventId,
  });

  TaskItem copyWith({
    bool? done,
    String? title,
    DateTime? reminderAt,
    bool clearReminder = false,
    DateTime? reminderEndAt,
    bool clearReminderEndAt = false,
    String? calendarEventId,
    bool clearCalendarEventId = false,
  }) {
    return TaskItem(
      id: id,
      entryId: entryId,
      title: title ?? this.title,
      dueHint: dueHint,
      dueDate: dueDate,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      reminderEndAt: clearReminder || clearReminderEndAt
          ? null
          : (reminderEndAt ?? this.reminderEndAt),
      done: done ?? this.done,
      calendarEventId: clearCalendarEventId
          ? null
          : (calendarEventId ?? this.calendarEventId),
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
      'reminder_end_at': reminderEndAt?.toIso8601String(),
      'done': done ? 1 : 0,
      'calendar_event_id': calendarEventId,
    };
  }

  factory TaskItem.fromMap(Map<String, Object?> map) {
    final dueDateStr = map['due_date'] as String?;
    final reminderAtStr = map['reminder_at'] as String?;
    final reminderEndAtStr = map['reminder_end_at'] as String?;
    return TaskItem(
      id: map['id'] as int?,
      entryId: map['entry_id'] as int?,
      title: map['title'] as String,
      dueHint: map['due_hint'] as String?,
      dueDate: dueDateStr != null ? DateTime.tryParse(dueDateStr) : null,
      reminderAt: reminderAtStr != null ? DateTime.tryParse(reminderAtStr) : null,
      reminderEndAt:
          reminderEndAtStr != null ? DateTime.tryParse(reminderEndAtStr) : null,
      done: (map['done'] as int? ?? 0) == 1,
      calendarEventId: map['calendar_event_id'] as String?,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final dueDateStr = json['due_date'] as String?;
    final reminderAtStr = json['reminder_at'] as String?;
    final reminderEndAtStr = json['reminder_end_at'] as String?;
    return TaskItem(
      title: (json['title'] as String? ?? '').trim(),
      dueHint: json['due_hint'] as String?,
      dueDate: dueDateStr != null ? DateTime.tryParse(dueDateStr) : null,
      reminderAt: reminderAtStr != null ? DateTime.tryParse(reminderAtStr) : null,
      reminderEndAt:
          reminderEndAtStr != null ? DateTime.tryParse(reminderEndAtStr) : null,
    );
  }
}

class NoteItem {
  final int? id;
  final int? entryId;
  final String category;
  final String? title;
  final String content;
  final int? fontFamilyIndex;
  final int? textColorValue;
  final double? fontScale;

  NoteItem({
    this.id,
    this.entryId,
    required this.category,
    this.title,
    required this.content,
    this.fontFamilyIndex,
    this.textColorValue,
    this.fontScale,
  });

  NoteItem copyWith({
    String? title,
    bool clearTitle = false,
    String? content,
    int? fontFamilyIndex,
    int? textColorValue,
    bool clearTextColor = false,
    double? fontScale,
  }) {
    return NoteItem(
      id: id,
      entryId: entryId,
      category: category,
      title: clearTitle ? null : (title ?? this.title),
      content: content ?? this.content,
      fontFamilyIndex: fontFamilyIndex ?? this.fontFamilyIndex,
      textColorValue: clearTextColor
          ? null
          : (textColorValue ?? this.textColorValue),
      fontScale: fontScale ?? this.fontScale,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'entry_id': entryId,
      'category': category,
      'title': title,
      'content': content,
      'font_family_index': fontFamilyIndex,
      'text_color': textColorValue,
      'font_scale': fontScale,
    };
  }

  factory NoteItem.fromMap(Map<String, Object?> map) {
    return NoteItem(
      id: map['id'] as int?,
      entryId: map['entry_id'] as int?,
      category: map['category'] as String,
      title: map['title'] as String?,
      content: map['content'] as String,
      fontFamilyIndex: map['font_family_index'] as int?,
      textColorValue: map['text_color'] as int?,
      fontScale: (map['font_scale'] as num?)?.toDouble(),
    );
  }

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String?)?.trim();
    return NoteItem(
      category: (json['category'] as String? ?? 'メモ').trim(),
      title: (title == null || title.isEmpty) ? null : title,
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
  final EmotionTag? emotion;
  final List<String> imagePaths;

  JournalEntry({
    this.id,
    required this.createdAt,
    required this.summary,
    required this.tasks,
    required this.notes,
    this.comfortMessage,
    this.emotion,
    this.imagePaths = const [],
  });

  JournalEntry copyWith({
    List<TaskItem>? tasks,
    List<NoteItem>? notes,
    List<String>? imagePaths,
  }) {
    return JournalEntry(
      id: id,
      createdAt: createdAt,
      summary: summary,
      tasks: tasks ?? this.tasks,
      notes: notes ?? this.notes,
      comfortMessage: comfortMessage,
      emotion: emotion,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}
