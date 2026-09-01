import Foundation

enum SiriUploadError: Error {
    case notPaired
    case invalidResponse
    case server(code: String, message: String)
}

struct SiriProcessVoiceMemoResult: Decodable {
    let summary: String
}

/// Apple Watch単体録音のVoiceMemoUploader（ios/VoiceJournalWatch/VoiceMemoUploader.swift）
/// と同じ実装。processVoiceMemoはFirebase Callable Functionsだが、RunnerからFirebase
/// SDKを直接importできないため、Callableのワイヤープロトコル（{"data": {...}}を
/// POSTし{"result": {...}}を受け取る）を素のURLSessionで手動実装している。
enum SiriVoiceMemoUploader {
    static func upload(audioFileURL: URL, locale: String = "ja") async throws -> SiriProcessVoiceMemoResult {
        guard let creds = await SiriAuthClient.shared.deviceCredentials else {
            throw SiriUploadError.notPaired
        }
        let idToken = try await SiriAuthClient.shared.validIdToken()
        let audioData = try Data(contentsOf: audioFileURL)

        var request = URLRequest(url: SiriRecordingConfig.processVoiceMemoURL)
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
        guard let http = response as? HTTPURLResponse else { throw SiriUploadError.invalidResponse }

        guard (200..<300).contains(http.statusCode) else {
            if let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDict = body["error"] as? [String: Any] {
                throw SiriUploadError.server(
                    code: errorDict["status"] as? String ?? "UNKNOWN",
                    message: errorDict["message"] as? String ?? "unknown error"
                )
            }
            throw SiriUploadError.invalidResponse
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = json["result"]
        else {
            throw SiriUploadError.invalidResponse
        }
        let resultData = try JSONSerialization.data(withJSONObject: result)
        return try JSONDecoder().decode(SiriProcessVoiceMemoResult.self, from: resultData)
    }
}
