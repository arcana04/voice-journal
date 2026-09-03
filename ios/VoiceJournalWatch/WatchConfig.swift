import Foundation

/// watchOSはFirebase SDK未対応のため、Firebase AuthのREST APIとCloud
/// Functionsを直接HTTPSで叩くために必要な値だけをここに転記している。
/// ios/Runner/GoogleService-Info.plist・functions/src/index.ts の値と
/// 一致させること（リージョンを変更したらfunctionsBaseURLも合わせる）。
enum WatchConfig {
    static let firebaseWebAPIKey = "AIzaSyDQnhFJa36ymUwBK1Mj1R3CVIqkprxchrU"
    static let firebaseProjectId = "voicejournal-bbafa"
    static let functionsBaseURL = "https://us-central1-\(firebaseProjectId).cloudfunctions.net"

    static let secureTokenSignInURL =
        URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=\(firebaseWebAPIKey)")!
    static let secureTokenRefreshURL =
        URL(string: "https://securetoken.googleapis.com/v1/token?key=\(firebaseWebAPIKey)")!
    static let processVoiceMemoURL = URL(string: "\(functionsBaseURL)/processVoiceMemo")!

    /// users/{uid}/entries/{entryId} ドキュメントへのFirestore REST API URL。
    /// lib/services/cloud_sync_service.dartが書き込む先と同じコレクション。
    static func firestoreEntryURL(uid: String, entryId: String) -> URL {
        URL(
            string: "https://firestore.googleapis.com/v1/projects/\(firebaseProjectId)/databases/(default)/documents/users/\(uid)/entries/\(entryId)"
        )!
    }
}
