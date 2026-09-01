import Foundation
import Security

/// watchOS単体でのFirebase認証状態（refreshToken等）をKeychainに保存する。
/// iPhone側のKeychainとは別領域なので、ここに保存したものはWatch単体で
/// 完結し、iPhoneの状態（ペア解除・再インストール等）には依存しない。
enum KeychainStore {
    private static let service = "com.arcana04.voicejournal.watch.auth"

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
