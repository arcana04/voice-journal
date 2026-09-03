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

    /// AIの分類結果から、最初に表示する既定のカテゴリを決める。タスクが
    /// 1件でもあればタスク優先、なければnotesの最初の1件のcategoryを見る。
    static func primary(for result: ProcessVoiceMemoResult) -> EntryCategory {
        if !result.tasks.isEmpty { return .task }
        if let first = result.notes.first {
            return first.category == "アイデア" ? .idea : .diary
        }
        return .diary
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

    /// ユーザーがWatch上で分類を選び直した場合、単一のタスク/ノートに
    /// まとめ直して上書きする（分類変更だけを目的とした単純化）。
    static func recategorize(
        result: ProcessVoiceMemoResult,
        createdAt: Date,
        entryId: String,
        category: EntryCategory
    ) async throws {
        let isoFormatter = ISO8601DateFormatter()
        let createdAtString = isoFormatter.string(from: createdAt)
        let bestText = result.notes.first?.content ?? result.summary

        var tasks: [[String: Any?]] = []
        var notes: [[String: Any?]] = []

        switch category {
        case .task:
            let sourceTask = result.tasks.first
            tasks = [[
                "title": sourceTask?.title ?? result.summary,
                "due_hint": sourceTask?.due_hint,
                "due_date": sourceTask?.due_date,
                "reminder_at": sourceTask?.reminder_at,
                "reminder_end_at": sourceTask?.reminder_end_at,
                "done": 0,
                "is_all_day": 0,
                "notify_at": sourceTask?.reminder_at,
            ]]
        case .diary, .idea:
            notes = [[
                "category": category.noteCategoryValue,
                "title": result.notes.first?.title,
                "content": bestText,
                "font_family_index": nil,
                "text_color": nil,
                "font_scale": nil,
                "background_id": nil,
                "idea_status": nil,
                "pinned": 0,
                "tag": nil,
            ]]
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
