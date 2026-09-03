import Foundation

/// 日記(感情ログ)/アイデア/タスクの3分類。lib/models/journal_entry.dartの
/// kNoteCategoryFeeling/kNoteCategoryIdea、およびタスクの有無に対応する。
enum EntryCategory: String, CaseIterable {
    case task
    case diary
    case idea

    var noteCategoryValue: String? {
        switch self {
        case .task: return nil
        case .diary: return "感情ログ"
        case .idea: return "アイデア"
        }
    }

    var label: String {
        switch self {
        case .task: return "タスク"
        case .diary: return "日記"
        case .idea: return "アイデア"
        }
    }

    /// iPhone側のボトムナビゲーションと合わせたSF Symbol(checklist/book.closed/lightbulb)。
    var iconName: String {
        switch self {
        case .task: return "checklist"
        case .diary: return "book.closed.fill"
        case .idea: return "lightbulb.fill"
        }
    }

    /// タップのたびに次の分類へ順送りする(watchOSでは`Picker`/`Menu`の表示が
    /// 崩れたため、単純な巡回ボタンに置き換えている)。
    var next: EntryCategory {
        let all = EntryCategory.allCases
        let index = all.firstIndex(of: self)!
        return all[(index + 1) % all.count]
    }
}

/// Watch上で確認・編集する1項目。タスク/日記/アイデアいずれかの分類と、
/// 中身のテキストだけを編集可能にする(日時などタスクの詳細設定は
/// iPhone側に委ねる)。[originalTask]は、分類をタスクのまま変えなかった
/// 場合にdue_hint等の日時情報を保存時に引き継ぐために保持しておく。
struct DraftItem: Identifiable {
    let id = UUID()
    var category: EntryCategory
    var text: String
    var originalTask: ProcessVoiceMemoTask?
}

extension ProcessVoiceMemoResult {
    var totalItemCount: Int { tasks.count + notes.count }

    /// Watch上で1項目ずつ分類変更・編集できるドラフト一覧に変換する。
    func draftItems() -> [DraftItem] {
        var items: [DraftItem] = []
        for task in tasks {
            items.append(DraftItem(category: .task, text: task.title, originalTask: task))
        }
        for note in notes {
            let category: EntryCategory = note.category == "アイデア" ? .idea : .diary
            items.append(DraftItem(category: category, text: note.content, originalTask: nil))
        }
        return items
    }

    /// カテゴリごとの件数の内訳（表示順はEntryCategory.allCasesの順）。
    var categoryBreakdown: [(category: EntryCategory, count: Int)] {
        var counts: [EntryCategory: Int] = [:]
        if !tasks.isEmpty { counts[.task, default: 0] += tasks.count }
        for note in notes {
            let category: EntryCategory = note.category == "アイデア" ? .idea : .diary
            counts[category, default: 0] += 1
        }
        return EntryCategory.allCases.compactMap { category in
            guard let count = counts[category] else { return nil }
            return (category, count)
        }
    }

    /// 「タスク1件・日記1件」のような、複数項目に仕分けられたときの内訳表示。
    var breakdownSummary: String {
        categoryBreakdown.map { "\($0.category.label)\($0.count)件" }.joined(separator: "・")
    }
}

enum EntryStoreError: Error {
    case notPaired
    case invalidResponse
    case server(String)
}

/// Firestoreの `users/{uid}/entries/{entryId}` へ、iPhone側
/// (CloudSyncService._entryToFirestoreMap)と同じ形のドキュメントを
/// REST APIで直接書き込む（watchOSはFirebase SDK未対応のため）。
enum EntryStore {
    private static let idChars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")

    static func generateEntryId() -> String {
        String((0..<20).map { _ in idChars.randomElement()! })
    }

    /// AIの分類結果をそのまま(複数のtasks/notesを保ったまま)保存する。
    @discardableResult
    static func save(
        result: ProcessVoiceMemoResult,
        createdAt: Date,
        entryId: String
    ) async throws -> String {
        let isoFormatter = ISO8601DateFormatter()
        let createdAtString = isoFormatter.string(from: createdAt)

        let tasks: [[String: Any?]] = result.tasks.map { task in
            [
                "title": task.title,
                "due_hint": task.due_hint,
                "due_date": task.due_date,
                "reminder_at": task.reminder_at,
                "reminder_end_at": task.reminder_end_at,
                "done": 0,
                "is_all_day": 0,
                "notify_at": task.reminder_at,
            ]
        }
        let notes: [[String: Any?]] = result.notes.map { note in
            [
                "category": note.category,
                "title": note.title,
                "content": note.content,
                "font_family_index": nil,
                "text_color": nil,
                "font_scale": nil,
                "background_id": nil,
                "idea_status": nil,
                "pinned": 0,
                "tag": nil,
            ]
        }

        let fields: [String: Any?] = [
            "summary": result.summary,
            "created_at": createdAtString,
            "comfort_message": result.comfort_message,
            "emotion": result.emotion,
            "tasks": tasks,
            "notes": notes,
        ]

        try await write(entryId: entryId, fields: fields)
        return entryId
    }

    /// Watch上で編集済みのドラフト一覧を、タスク/ノートの配列へ組み立て直して
    /// 上書き保存する。分類をタスクのまま変えていない項目は元のdue_hint/
    /// due_date/reminder_at等を引き継ぎ、新たにタスクへ変更された項目は
    /// 日時情報を持たない素のタスクとして保存する（日時編集はiPhone側に委ねる）。
    static func saveDraftItems(
        _ items: [DraftItem],
        summary: String,
        comfortMessage: String?,
        emotion: String?,
        createdAt: Date,
        entryId: String
    ) async throws {
        var tasks: [[String: Any?]] = []
        var notes: [[String: Any?]] = []

        for item in items {
            let text = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            switch item.category {
            case .task:
                let original = item.originalTask
                tasks.append([
                    "title": text,
                    "due_hint": original?.due_hint,
                    "due_date": original?.due_date,
                    "reminder_at": original?.reminder_at,
                    "reminder_end_at": original?.reminder_end_at,
                    "done": 0,
                    "is_all_day": 0,
                    "notify_at": original?.reminder_at,
                ])
            case .diary, .idea:
                notes.append([
                    "category": item.category.noteCategoryValue,
                    "title": nil,
                    "content": text,
                    "font_family_index": nil,
                    "text_color": nil,
                    "font_scale": nil,
                    "background_id": nil,
                    "idea_status": nil,
                    "pinned": 0,
                    "tag": nil,
                ])
            }
        }

        let isoFormatter = ISO8601DateFormatter()
        let fields: [String: Any?] = [
            "summary": summary,
            "created_at": isoFormatter.string(from: createdAt),
            "comfort_message": comfortMessage,
            "emotion": emotion,
            "tasks": tasks,
            "notes": notes,
        ]

        try await write(entryId: entryId, fields: fields)
    }

    private static func write(entryId: String, fields: [String: Any?]) async throws {
        guard await FirebaseAuthClient.shared.deviceCredentials != nil else {
            throw EntryStoreError.notPaired
        }
        let idToken = try await FirebaseAuthClient.shared.validIdToken()
        let uid = try await FirebaseAuthClient.shared.currentUid()

        // updateMask.fieldPathsを付けず素のPATCHを投げると、ドキュメント全体を
        // 指定フィールドだけで置き換えてしまい、サーバー側で計算されるembedding等の
        // 他フィールドを消してしまう（cloud_sync_service.dartのpushEntryが
        // SetOptions(merge: true)を使っている理由と同じ）。updateMaskで
        // 「指定したフィールドだけ書き換える」マージ相当の挙動にする。
        var components = URLComponents(
            url: WatchConfig.firestoreEntryURL(uid: uid, entryId: entryId),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = fields.keys.map { URLQueryItem(name: "updateMask.fieldPaths", value: $0) }

        var request = URLRequest(url: components.url!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "fields": FirestoreValueEncoder.encodeFields(fields),
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw EntryStoreError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw EntryStoreError.server(String(data: data, encoding: .utf8) ?? "unknown error")
        }
    }
}

/// SwiftのDictionary/配列を、Firestore REST APIが要求する型付きJSON
/// （{"stringValue": ...}のような形）へ変換する最小限のエンコーダ。
enum FirestoreValueEncoder {
    static func encodeFields(_ fields: [String: Any?]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in fields {
            result[key] = encodeValue(value)
        }
        return result
    }

    static func encodeValue(_ value: Any?) -> [String: Any] {
        guard let value else { return ["nullValue": NSNull()] }

        switch value {
        case let s as String:
            return ["stringValue": s]
        case let i as Int:
            return ["integerValue": String(i)]
        case let b as Bool:
            return ["booleanValue": b]
        case let arr as [[String: Any?]]:
            let values = arr.map { ["mapValue": ["fields": encodeFields($0)]] }
            return ["arrayValue": ["values": values]]
        default:
            return ["nullValue": NSNull()]
        }
    }
}
