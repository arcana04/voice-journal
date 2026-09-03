import Foundation

enum UploadError: Error {
    case notPaired
    case invalidResponse
    case server(code: String, message: String)
}

struct ProcessVoiceMemoTask: Codable {
    let title: String
    let due_hint: String?
    let due_date: String?
    let reminder_at: String?
    let reminder_end_at: String?
}

struct ProcessVoiceMemoNote: Codable {
    let category: String
    let title: String?
    let content: String
}

struct ProcessVoiceMemoResult: Decodable {
    let summary: String
    let tasks: [ProcessVoiceMemoTask]
    let notes: [ProcessVoiceMemoNote]
    let comfort_message: String?
    let emotion: String?
}

/// processVoiceMemoはFirebase Callable Functionsだが、watchOSにFirebase
/// SDKが無いため、Callableのワイヤープロトコル（{"data": {...}}をPOSTし
/// {"result": {...}}を受け取る）を素のURLSessionで手動実装している。
/// Authorizationヘッダーに加え、functions/src/index.tsの
/// verifyWatchDeviceSecretが検証するX-Watch-Device-*ヘッダーを付与する。
enum VoiceMemoUploader {
    static func upload(audioFileURL: URL, locale: String = "ja") async throws -> ProcessVoiceMemoResult {
        guard let creds = await FirebaseAuthClient.shared.deviceCredentials else {
            throw UploadError.notPaired
        }
        let idToken = try await FirebaseAuthClient.shared.validIdToken()
        let audioData = try Data(contentsOf: audioFileURL)

        var request = URLRequest(url: WatchConfig.processVoiceMemoURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.setValue(creds.deviceId, forHTTPHeaderField: "X-Watch-Device-Id")
        request.setValue(creds.deviceSecret, forHTTPHeaderField: "X-Watch-Device-Secret")

        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "data": [
                "audioBase64": audioData.base64EncodedString(),
                "mimeType": "audio/m4a",
                "locale": locale,
            ],
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw UploadError.invalidResponse }

        guard (200..<300).contains(http.statusCode) else {
            if let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDict = body["error"] as? [String: Any] {
                throw UploadError.server(
                    code: errorDict["status"] as? String ?? "UNKNOWN",
                    message: errorDict["message"] as? String ?? "unknown error"
                )
            }
            throw UploadError.invalidResponse
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = json["result"]
        else {
            throw UploadError.invalidResponse
        }
        let resultData = try JSONSerialization.data(withJSONObject: result)
        return try JSONDecoder().decode(ProcessVoiceMemoResult.self, from: resultData)
    }
}
