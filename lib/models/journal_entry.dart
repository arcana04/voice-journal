import 'emotion_tag.dart';
import 'entry_image.dart';

class TaskItem {
  final int? id;
  final int? entryId;
  final String title;
  final String? dueHint;
  final DateTime? dueDate;

  /// 複数日にまたがる終日の予定の最終日（例:3日間の出張なら3日目の日付）。
  /// 単日の予定はnull。[dueDate]が開始日、これが終了日で、カレンダー同期時に
  /// 1件の複数日イベントとして登録する。時刻ありの予定の開始・終了は
  /// [reminderAt]/[reminderEndAt]が担当するので、こちらは日付のみの
  /// 終日イベント専用。
  final DateTime? dueDateEnd;

  /// カレンダー同期される予定の開始日時。[reminderEndAt]と対で「開始・終了時間」を表す。
  final DateTime? reminderAt;

  /// カレンダー同期される予定の終了日時（任意）。
  final DateTime? reminderEndAt;
  final bool done;
  final String? calendarEventId;

  /// [calendarEventId]が実際に存在するカレンダーのID。「連携先カレンダー」の
  /// 現在の設定値とは独立して保持する——ユーザーが後で連携先カレンダーを
  /// 切り替えても、既存の予定に対する更新・削除は必ずこのIDを対象にする
  /// ため（切り替え後に「現在選択中のカレンダー」を見てしまうと、切り替え前の
  /// カレンダーに残った予定が二度と操作できなくなる）。
  final String? calendarId;

  /// iPhone標準のリマインダーアプリ（EventKitのEKReminder）に連携登録した際のID。
  final String? appleReminderId;

  /// [appleReminderId]が実際に存在するリマインダーリストのID。[calendarId]と
  /// 同じ理由で「連携先リスト」の現在の設定値とは独立して保持する——ユーザーが
  /// 後で連携先リストを切り替えても、既存のリマインダーに対する更新は必ず
  /// このIDが指すリストを対象にする（切り替え後に「現在選択中のリスト」を
  /// 見てしまうと、既存のリマインダーが無断で新しいリストへ移動してしまう）。
  final String? reminderListId;
  final bool isAllDay;

  /// 端末に届くプッシュ通知の発火時刻。[reminderAt]/[reminderEndAt]（カレンダー用の
  /// 開始・終了時間）とは完全に独立しており、どちらかを変更してももう片方には
  /// 影響しない。
  final DateTime? notifyAt;

  /// Notion連携で送信済みの場合の、作成されたNotionページURL。未送信はnull。
  final String? notionPageUrl;

  /// AI(processVoiceMemo/processTextMemo)が生成したタスクならtrue、
  /// 手動作成画面(AIバイパス)で作られたタスクならfalse。レビュー依頼の
  /// トリガー(「AIが作ったタスクを初めて完了した」)の判定に使う。
  final bool aiGenerated;

  TaskItem({
    this.id,
    this.entryId,
    required this.title,
    this.dueHint,
    this.dueDate,
    this.dueDateEnd,
    this.reminderAt,
    this.reminderEndAt,
    this.done = false,
    this.calendarEventId,
    this.calendarId,
    this.appleReminderId,
    this.reminderListId,
    this.isAllDay = false,
    this.notifyAt,
    this.notionPageUrl,
    this.aiGenerated = true,
  });

  /// 終日タスクにユーザーが明示的な通知時刻を設定していない場合の既定値
  /// （期限日の前日[hour]時、設定画面で変更可能・デフォルト16時）。
  /// 期限が今日（「今日、この後、牛乳を買う」のような当日・時刻指定なし
  /// タスク）だと前日[hour]時はすでに過去になるため、代わりに「今から2時間後」
  /// を既定値にする——固定時刻だと録音した時間帯によってはそれ自体が既に
  /// 過去ということが起こり得るが、相対時間なら常に未来になる。「この後」
  /// という言い回し自体が近い未来を指すニュアンスとも合う。
  /// 期限が明日以降であっても、[hour]が既存のsettings値(例:16時)より遅い
  /// 時間帯（例:21時）に録音した場合、「前日[hour]時」は同様にすでに過去に
  /// なる——この場合も同じ「今から2時間後」のフォールバックを使う（実際に
  /// 発生した不具合: 21時に「明日歯医者」を録音すると前日16時＝今日16時が
  /// 既に過去のため、通知が一切飛ばなかった）。
  /// 期限が過去（すでに期日超過）の場合は、通知時刻を推測する意味が無いため
  /// 既定値を設定しない（null＝通知なし、従来どおりの挙動）。
  static DateTime? defaultAllDayNotifyAt(DateTime dueDate, {int hour = 16}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (dueDay.isBefore(today)) return null;
    if (dueDay.isAtSameMomentAs(today)) {
      return now.add(const Duration(hours: 2));
    }
    final dayBefore = dueDay.subtract(const Duration(days: 1));
    final candidate = DateTime(dayBefore.year, dayBefore.month, dayBefore.day, hour);
    return candidate.isBefore(now) ? now.add(const Duration(hours: 2)) : candidate;
  }

  TaskItem copyWith({
    bool? done,
    String? title,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? dueDateEnd,
    bool clearDueDateEnd = false,
    DateTime? reminderAt,
    bool clearReminder = false,
    DateTime? reminderEndAt,
    bool clearReminderEndAt = false,
    String? calendarEventId,
    bool clearCalendarEventId = false,
    String? calendarId,
    String? appleReminderId,
    bool clearAppleReminderId = false,
    String? reminderListId,
    bool? isAllDay,
    DateTime? notifyAt,
    bool clearNotify = false,
    String? notionPageUrl,
    bool clearNotionPageUrl = false,
  }) {
    return TaskItem(
      id: id,
      entryId: entryId,
      title: title ?? this.title,
      dueHint: dueHint,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueDateEnd: clearDueDate || clearDueDateEnd
          ? null
          : (dueDateEnd ?? this.dueDateEnd),
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      reminderEndAt: clearReminder || clearReminderEndAt
          ? null
          : (reminderEndAt ?? this.reminderEndAt),
      done: done ?? this.done,
      calendarEventId: clearCalendarEventId
          ? null
          : (calendarEventId ?? this.calendarEventId),
      calendarId: clearCalendarEventId
          ? null
          : (calendarId ?? this.calendarId),
      appleReminderId: clearAppleReminderId
          ? null
          : (appleReminderId ?? this.appleReminderId),
      reminderListId: clearAppleReminderId
          ? null
          : (reminderListId ?? this.reminderListId),
      isAllDay: clearReminder ? false : (isAllDay ?? this.isAllDay),
      notifyAt: clearNotify ? null : (notifyAt ?? this.notifyAt),
      notionPageUrl: clearNotionPageUrl
          ? null
          : (notionPageUrl ?? this.notionPageUrl),
      aiGenerated: aiGenerated,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'entry_id': entryId,
      'title': title,
      'due_hint': dueHint,
      'due_date': dueDate?.toIso8601String(),
      'due_date_end': dueDateEnd?.toIso8601String(),
      'reminder_at': reminderAt?.toIso8601String(),
      'reminder_end_at': reminderEndAt?.toIso8601String(),
      'done': done ? 1 : 0,
      'calendar_event_id': calendarEventId,
      'calendar_id': calendarId,
      'apple_reminder_id': appleReminderId,
      'apple_reminder_list_id': reminderListId,
      'is_all_day': isAllDay ? 1 : 0,
      'notify_at': notifyAt?.toIso8601String(),
      'notion_page_url': notionPageUrl,
      'ai_generated': aiGenerated ? 1 : 0,
    };
  }

  factory TaskItem.fromMap(Map<String, Object?> map) {
    final dueDateStr = map['due_date'] as String?;
    final dueDateEndStr = map['due_date_end'] as String?;
    final reminderAtStr = map['reminder_at'] as String?;
    final reminderEndAtStr = map['reminder_end_at'] as String?;
    final notifyAtStr = map['notify_at'] as String?;
    return TaskItem(
      id: map['id'] as int?,
      entryId: map['entry_id'] as int?,
      title: (map['title'] as String?) ?? '',
      dueHint: map['due_hint'] as String?,
      dueDate: dueDateStr != null ? DateTime.tryParse(dueDateStr) : null,
      dueDateEnd: dueDateEndStr != null ? DateTime.tryParse(dueDateEndStr) : null,
      reminderAt: reminderAtStr != null
          ? DateTime.tryParse(reminderAtStr)
          : null,
      reminderEndAt: reminderEndAtStr != null
          ? DateTime.tryParse(reminderEndAtStr)
          : null,
      done: (map['done'] as int? ?? 0) == 1,
      calendarEventId: map['calendar_event_id'] as String?,
      calendarId: map['calendar_id'] as String?,
      appleReminderId: map['apple_reminder_id'] as String?,
      reminderListId: map['apple_reminder_list_id'] as String?,
      isAllDay: (map['is_all_day'] as int? ?? 0) == 1,
      notifyAt: notifyAtStr != null ? DateTime.tryParse(notifyAtStr) : null,
      notionPageUrl: map['notion_page_url'] as String?,
      aiGenerated: (map['ai_generated'] as int? ?? 1) == 1,
    );
  }

  /// [autoNotificationsEnabled]がfalseの場合、AIが時刻を抽出できていても
  /// 通知は一切設定しない（カレンダー/リマインダーアプリへの反映だけしたい
  /// ユーザー向けの設定）。[reminderOffsetMinutes]は「開始何分前に通知するか」
  /// （0なら開始時刻ちょうど）、[allDayReminderHour]は終日タスクの既定通知時刻。
  /// いずれも設定画面のデフォルト値で、後からTaskEditScreenで個別に変更できる
  /// 点は変わらない。
  factory TaskItem.fromJson(
    Map<String, dynamic> json, {
    bool autoNotificationsEnabled = true,
    int reminderOffsetMinutes = 0,
    int allDayReminderHour = 16,
  }) {
    final dueDateStr = json['due_date'] as String?;
    final dueDateEndStr = json['due_date_end'] as String?;
    final reminderAtStr = json['reminder_at'] as String?;
    final reminderEndAtStr = json['reminder_end_at'] as String?;
    final reminderAt = reminderAtStr != null
        ? DateTime.tryParse(reminderAtStr)
        : null;
    // AIは「15時に」のように時刻だけで明示的な日付表現が無い場合due_dateを
    // nullにするが、reminder_atには具体的な日付が入っている。その日付を
    // dueDateにも反映しないと「今日/今週」フィルタから漏れてしまう。
    final parsedDueDate = dueDateStr != null
        ? DateTime.tryParse(dueDateStr)
        : null;
    final dueDate =
        parsedDueDate ??
        (reminderAt != null
            ? DateTime(reminderAt.year, reminderAt.month, reminderAt.day)
            : null);
    // AIが期限日だけを抽出し、時刻を抽出できなかった場合は終日タスク扱いにする。
    final isAllDay = dueDate != null && reminderAt == null;
    final parsedDueDateEnd = dueDateEndStr != null
        ? DateTime.tryParse(dueDateEndStr)
        : null;
    // 終了日が開始日より前になることは無いはずだが（コード側で確定計算済み）、
    // 万一の不整合に備えて開始日以前ならnull扱い（単日タスクにフォールバック）。
    final dueDateEnd = (parsedDueDateEnd != null && dueDate != null && parsedDueDateEnd.isAfter(dueDate))
        ? parsedDueDateEnd
        : null;
    return TaskItem(
      title: (json['title'] as String? ?? '').trim(),
      dueHint: json['due_hint'] as String?,
      dueDate: dueDate,
      dueDateEnd: dueDateEnd,
      reminderAt: reminderAt,
      reminderEndAt: reminderEndAtStr != null
          ? DateTime.tryParse(reminderEndAtStr)
          : null,
      isAllDay: isAllDay,
      // AIが時刻を抽出した直後の通知時刻の既定値。終日タスクは
      // 「前日[allDayReminderHour]時」、時刻ありタスクは「開始時刻から
      // [reminderOffsetMinutes]分前」（どちらも設定画面のデフォルト値、
      // 後からTaskEditScreenで個別に変更できる点は変わらない）。
      // autoNotificationsEnabledがfalseなら通知そのものを設定しない。
      notifyAt: !autoNotificationsEnabled
          ? null
          : isAllDay
          ? TaskItem.defaultAllDayNotifyAt(dueDate, hour: allDayReminderHour)
          : reminderAt?.subtract(Duration(minutes: reminderOffsetMinutes)),
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

  /// [IdeaStatus.id]。アイデア（[kNoteCategoryIdea]）のみで使う検討状況。未設定はnull。
  final String? ideaStatus;

  /// アイデア画面の上部に固定表示するための手動フラグ。
  final bool pinned;

  /// アイデアの自由入力タグ（種類分け用）。未設定はnull。
  final String? tag;

  /// Notion連携で送信済みの場合の、作成されたNotionページURL。未送信はnull。
  final String? notionPageUrl;

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
    this.ideaStatus,
    this.pinned = false,
    this.tag,
    this.notionPageUrl,
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
    String? ideaStatus,
    bool clearIdeaStatus = false,
    bool? pinned,
    String? tag,
    bool clearTag = false,
    String? notionPageUrl,
    bool clearNotionPageUrl = false,
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
      ideaStatus: clearIdeaStatus ? null : (ideaStatus ?? this.ideaStatus),
      pinned: pinned ?? this.pinned,
      tag: clearTag ? null : (tag ?? this.tag),
      notionPageUrl: clearNotionPageUrl
          ? null
          : (notionPageUrl ?? this.notionPageUrl),
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
      'idea_status': ideaStatus,
      'pinned': pinned ? 1 : 0,
      'tag': tag,
      'notion_page_url': notionPageUrl,
    };
  }

  factory NoteItem.fromMap(Map<String, Object?> map) {
    return NoteItem(
      id: map['id'] as int?,
      entryId: map['entry_id'] as int?,
      category: (map['category'] as String?) ?? kNoteCategoryFeeling,
      title: map['title'] as String?,
      content: (map['content'] as String?) ?? '',
      fontFamilyIndex: map['font_family_index'] as int?,
      textColorValue: map['text_color'] as int?,
      fontScale: (map['font_scale'] as num?)?.toDouble(),
      backgroundId: map['background_id'] as String?,
      ideaStatus: map['idea_status'] as String?,
      pinned: (map['pinned'] as int? ?? 0) == 1,
      tag: map['tag'] as String?,
      notionPageUrl: map['notion_page_url'] as String?,
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

  /// このエントリの内容(summary/tasks/notes/emotion/comfort_message、つまり
  /// [CloudSyncService]がpush/pullする範囲)が最後に変更された時刻。
  /// [fullSync]が同じremoteIdのエントリが端末とリモートの両方に存在する場合に
  /// どちらが新しいかを判定する基準として使う([JournalStore.fullSync]参照)。
  /// 未指定なら[createdAt]と同じ扱いにする(新規作成時は「作成=更新」のため)。
  final DateTime updatedAt;
  final String summary;
  final List<TaskItem> tasks;
  final List<NoteItem> notes;
  final String? comfortMessage;
  final EmotionTag? emotion;
  final List<EntryImage> images;

  /// 位置・サイズ情報を必要としない呼び出し元向けの、パスだけの一覧。
  List<String> get imagePaths => images.map((i) => i.path).toList();

  JournalEntry({
    this.id,
    this.remoteId,
    required this.createdAt,
    DateTime? updatedAt,
    required this.summary,
    required this.tasks,
    required this.notes,
    this.comfortMessage,
    this.emotion,
    this.images = const [],
  }) : updatedAt = updatedAt ?? createdAt;

  JournalEntry copyWith({
    List<TaskItem>? tasks,
    List<NoteItem>? notes,
    List<EntryImage>? images,
    EmotionTag? emotion,
    bool clearEmotion = false,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id,
      remoteId: remoteId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      summary: summary,
      tasks: tasks ?? this.tasks,
      notes: notes ?? this.notes,
      comfortMessage: comfortMessage,
      emotion: clearEmotion ? null : (emotion ?? this.emotion),
      images: images ?? this.images,
    );
  }
}
