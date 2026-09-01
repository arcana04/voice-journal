import Foundation
import Security

/// Siri/ショートカット経由のバックグラウンド録音専用の認証情報をKeychainに保存する。
/// Apple Watch用のKeychainStore（ios/VoiceJournalWatch/KeychainStore.swift）と
/// 同じ仕組みだが、iPhone本体アプリの中で完結する別領域として独立させている。
enum SiriKeychainStore {
    private static let service = "com.arcana04.voicejournal.siri.auth"

    enum Key: String, CaseIterable {
        case uid
        case refreshToken
        case deviceId
        case deviceSecret
    }

    static func set(_ value: String, for key: Key) {
        let data = Data(value.utf8)
        var query = baseQuery(for: key)
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(_ key: Key) -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func removeAll() {
        for key in Key.allCases {
            SecItemDelete(baseQuery(for: key) as CFDictionary)
        }
    }

    static var isPaired: Bool {
        read(.refreshToken) != nil && read(.deviceId) != nil && read(.deviceSecret) != nil
    }

    private static func baseQuery(for key: Key) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
    }
}
