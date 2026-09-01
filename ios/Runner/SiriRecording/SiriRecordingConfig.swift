import Foundation

/// Siriバックグラウンド録音のApp Intentsはアプリを前面化しない（openAppWhenRun =
/// false）ため、Flutter/Dartのメインアプリ実行パスを経由せずに直接Cloud Functionsを
/// 叩く必要がある。Firebase SDKはRunnerターゲットのSwiftコードから直接
/// importできない（FlutterのSPM生成物経由でのみリンクされているため）ので、
/// Apple Watch単体録音（ios/VoiceJournalWatch/WatchConfig.swift）と同じ方式で
/// REST APIを直接叩く。値は同期して保つこと。
enum SiriRecordingConfig {
    static let firebaseWebAPIKey = "AIzaSyDQnhFJa36ymUwBK1Mj1R3CVIqkprxchrU"
    static let firebaseProjectId = "voicejournal-bbafa"
    static let functionsBaseURL = "https://us-central1-\(firebaseProjectId).cloudfunctions.net"

    static let secureTokenSignInURL =
        URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=\(firebaseWebAPIKey)")!
    static let secureTokenRefreshURL =
        URL(string: "https://securetoken.googleapis.com/v1/token?key=\(firebaseWebAPIKey)")!
    static let processVoiceMemoURL = URL(string: "\(functionsBaseURL)/processVoiceMemo")!
}
