import Foundation

enum FirebaseAuthError: Error {
    case network(Error)
    case invalidResponse
    case server(String)
    case notPaired
}

/// Firebase Auth SDKを使わず、REST APIを直接叩いてWatch単体でトークンを
/// 管理する（watchOSはFirebase Auth SDK未対応のため）。
///
/// ペアリング時にiPhoneから中継されたcustomToken（functions/src/index.tsの
/// mintWatchPairingToken参照、デフォルトTTL1時間・ワンタイム用）を、
/// accounts:signInWithCustomTokenでWatch専用のidToken/refreshTokenに交換する。
/// 以降はrefreshTokenでidTokenを更新でき、iPhoneの状態に依存せず動作する。
actor FirebaseAuthClient {
    static let shared = FirebaseAuthClient()

    private var cachedIdToken: String?
    private var cachedIdTokenExpiry: Date = .distantPast

    func completePairing(customToken: String, deviceId: String, deviceSecret: String) async throws {
        var request = URLRequest(url: WatchConfig.secureTokenSignInURL)
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

        KeychainStore.set(result.refreshToken, for: .refreshToken)
        KeychainStore.set(result.localId, for: .uid)
        KeychainStore.set(deviceId, for: .deviceId)
        KeychainStore.set(deviceSecret, for: .deviceSecret)

        cachedIdToken = result.idToken
        cachedIdTokenExpiry = Date().addingTimeInterval(TimeInterval(result.expiresIn) ?? 3600)
    }

    /// 有効なidTokenを返す。期限切れ間近ならrefreshTokenで更新する。
    func validIdToken() async throws -> String {
        if let token = cachedIdToken, Date() < cachedIdTokenExpiry.addingTimeInterval(-60) {
            return token
        }
        guard let refreshToken = KeychainStore.read(.refreshToken) else {
            throw FirebaseAuthError.notPaired
        }

        var request = URLRequest(url: WatchConfig.secureTokenRefreshURL)
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

        // securetoken.googleapis.comはリフレッシュのたびに新しいrefreshTokenを
        // 返すことがあるため、常に最新のものを保存し直す。
        KeychainStore.set(result.refresh_token, for: .refreshToken)
        cachedIdToken = result.id_token
        cachedIdTokenExpiry = Date().addingTimeInterval(TimeInterval(result.expires_in) ?? 3600)
        return result.id_token
    }

    var deviceCredentials: (deviceId: String, deviceSecret: String)? {
        guard let id = KeychainStore.read(.deviceId), let secret = KeychainStore.read(.deviceSecret) else {
            return nil
        }
        return (id, secret)
    }

    private static func checkOK(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw FirebaseAuthError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw FirebaseAuthError.server(String(data: data, encoding: .utf8) ?? "")
        }
    }
}
