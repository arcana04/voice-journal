import 'emotion_tag.dart';

class TaskItem {
  final int? id;
  final int? entryId;
  final String title;
  final String? dueHint;
  final DateTime? dueDate;

  /// カレンダー同期される予定の開始日時。[reminderEndAt]と対で「開始・終了時間」を表す。
  final DateTime? reminderAt;

  /// カレンダー同期される予定の終了日時（任意）。
  final DateTime? reminderEndAt;
  final bool done;
  final String? calendarEventId;
  final bool isAllDay;

  /// 端末に届くプッシュ通知の発火時刻。[reminderAt]/[reminderEndAt]（カレンダー用の
  /// 開始・終了時間）とは完全に独立しており、どちらかを変更してももう片方には
  /// 影響しない。
  final DateTime? notifyAt;

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
    this.isAllDay = false,
    this.notifyAt,
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
    bool? isAllDay,
    DateTime? notifyAt,
    bool clearNotify = false,
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
      isAllDay: clearReminder ? false : (isAllDay ?? this.isAllDay),
      notifyAt: clearNotify ? null : (notifyAt ?? this.notifyAt),
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
      'is_all_day': isAllDay ? 1 : 0,
      'notify_at': notifyAt?.toIso8601String(),
    };
  }

  factory TaskItem.fromMap(Map<String, Object?> map) {
    final dueDateStr = map['due_date'] as String?;
    final reminderAtStr = map['reminder_at'] as String?;
    final reminderEndAtStr = map['reminder_end_at'] as String?;
    final notifyAtStr = map['notify_at'] as String?;
    return TaskItem(
      id: map['id'] as int?,
      entryId: map['entry_id'] as int?,
      title: map['title'] as String,
      dueHint: map['due_hint'] as String?,
      dueDate: dueDateStr != null ? DateTime.tryParse(dueDateStr) : null,
      reminderAt: reminderAtStr != null
          ? DateTime.tryParse(reminderAtStr)
          : null,
      reminderEndAt: reminderEndAtStr != null
          ? DateTime.tryParse(reminderEndAtStr)
          : null,
      done: (map['done'] as int? ?? 0) == 1,
      calendarEventId: map['calendar_event_id'] as String?,
      isAllDay: (map['is_all_day'] as int? ?? 0) == 1,
      notifyAt: notifyAtStr != null ? DateTime.tryParse(notifyAtStr) : null,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final dueDateStr = json['due_date'] as String?;
    final reminderAtStr = json['reminder_at'] as String?;
    final reminderEndAtStr = json['reminder_end_at'] as String?;
    final reminderAt = reminderAtStr != null
        ? DateTime.tryParse(reminderAtStr)
        : null;
    return TaskItem(
      title: (json['title'] as String? ?? '').trim(),
      dueHint: json['due_hint'] as String?,
      dueDate: dueDateStr != null ? DateTime.tryParse(dueDateStr) : null,
      reminderAt: reminderAt,
      reminderEndAt: reminderEndAtStr != null
          ? DateTime.tryParse(reminderEndAtStr)
          : null,
      // AIが時刻を抽出した直後は、通知時刻も開始時刻と同じにしておく（後から
      // TaskEditScreenで両者を独立に変更できる）。
      notifyAt: reminderAt,
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

  /// [DiaryBackground.id]。未設定（背景なし）ならnull。
  final String? backgroundId;

  NoteItem({
    this.id,
    this.entryId,
    required this.category,
    this.title,
    required this.content,
    this.fontFamilyIndex,
    this.textColorValue,
    this.fontScale,
    this.backgroundId,
  });

  NoteItem copyWith({
    String? title,
    bool clearTitle = false,
    String? content,
    int? fontFamilyIndex,
    int? textColorValue,
    bool clearTextColor = false,
    double? fontScale,
    String? backgroundId,
    bool clearBackground = false,
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
      backgroundId: clearBackground
          ? null
          : (backgroundId ?? this.backgroundId),
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
      'background_id': backgroundId,
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
      backgroundId: map['background_id'] as String?,
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

  /// 端末をまたいだクラウドバックアップ/復元で使う安定ID。ローカルの[id]は
  /// 端末ごとのSQLite連番なので端末間で一致しない。DbService.insertEntryで
  /// 未設定なら自動生成される。
  final String? remoteId;
  final DateTime createdAt;
  final String summary;
  final List<TaskItem> tasks;
  final List<NoteItem> notes;
  final String? comfortMessage;
  final EmotionTag? emotion;
  final List<String> imagePaths;

  JournalEntry({
    this.id,
    this.remoteId,
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
    EmotionTag? emotion,
    bool clearEmotion = false,
  }) {
    return JournalEntry(
      id: id,
      remoteId: remoteId,
      createdAt: createdAt,
      summary: summary,
      tasks: tasks ?? this.tasks,
      notes: notes ?? this.notes,
      comfortMessage: comfortMessage,
      emotion: clearEmotion ? null : (emotion ?? this.emotion),
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}
