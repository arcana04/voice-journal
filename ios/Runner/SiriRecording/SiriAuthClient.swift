import Foundation

enum SiriAuthError: Error {
    case network(Error)
    case invalidResponse
    case server(String)
    case notPaired
}

/// Apple Watch単体録音のFirebaseAuthClient（ios/VoiceJournalWatch/FirebaseAuthClient.swift）
/// と同じ仕組み。Runnerターゲットからは（SPM経由の間接リンクのため）Firebase Auth
/// SDKを直接importできないので、REST APIを直接叩いてトークンを管理する。
///
/// ペアリングは lib/services/siri_recording_setup_service.dart が
/// mintWatchPairingToken（functions/src/index.ts）を呼んで得たcustomTokenを
/// MethodChannel経由でこちらに渡すことで行う。
actor SiriAuthClient {
    static let shared = SiriAuthClient()

    private var cachedIdToken: String?
    private var cachedIdTokenExpiry: Date = .distantPast

    func completePairing(customToken: String, deviceId: String, deviceSecret: String) async throws {
        var request = URLRequest(url: SiriRecordingConfig.secureTokenSignInURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "token": customToken,
            "returnSecureToken": true,
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.checkOK(response, data: data)

        struct SignInResult: Decodable {
            let idToken: String
            let refreshToken: String
            let localId: String
            let expiresIn: String
        }
        let result = try JSONDecoder().decode(SignInResult.self, from: data)

        SiriKeychainStore.set(result.refreshToken, for: .refreshToken)
        SiriKeychainStore.set(result.localId, for: .uid)
        SiriKeychainStore.set(deviceId, for: .deviceId)
        SiriKeychainStore.set(deviceSecret, for: .deviceSecret)

        cachedIdToken = result.idToken
        cachedIdTokenExpiry = Date().addingTimeInterval(TimeInterval(result.expiresIn) ?? 3600)
    }

    /// 有効なidTokenを返す。期限切れ間近ならrefreshTokenで更新する。
    func validIdToken() async throws -> String {
        if let token = cachedIdToken, Date() < cachedIdTokenExpiry.addingTimeInterval(-60) {
            return token
        }
        guard let refreshToken = SiriKeychainStore.read(.refreshToken) else {
            throw SiriAuthError.notPaired
        }

        var request = URLRequest(url: SiriRecordingConfig.secureTokenRefreshURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("grant_type=refresh_token&refresh_token=\(refreshToken)".utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.checkOK(response, data: data)

        struct RefreshResult: Decodable {
            let id_token: String
            let refresh_token: String
            let expires_in: String
        }
        let result = try JSONDecoder().decode(RefreshResult.self, from: data)

        SiriKeychainStore.set(result.refresh_token, for: .refreshToken)
        cachedIdToken = result.id_token
        cachedIdTokenExpiry = Date().addingTimeInterval(TimeInterval(result.expires_in) ?? 3600)
        return result.id_token
    }

    var deviceCredentials: (deviceId: String, deviceSecret: String)? {
        guard let id = SiriKeychainStore.read(.deviceId), let secret = SiriKeychainStore.read(.deviceSecret) else {
            return nil
        }
        return (id, secret)
    }

    private static func checkOK(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw SiriAuthError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw SiriAuthError.server(String(data: data, encoding: .utf8) ?? "")
        }
    }
}
