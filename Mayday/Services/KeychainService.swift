import Foundation
import Security

final class KeychainService: Sendable {
    static let shared = KeychainService()
    
    private let accessTokenKey = "mayday.access_token"
    private let refreshTokenKey = "mayday.refresh_token"
    private let expiresAtKey = "mayday.expires_at"

    private init() {}

    func saveTokens(_ tokens: TokenPair) throws {
        try save(tokens.accessToken, forKey: accessTokenKey)
        try save(tokens.refreshToken, forKey: refreshTokenKey)
        let expiresAtString = ISO8601DateFormatter().string(from: tokens.expiresAt)
        try save(expiresAtString, forKey: expiresAtKey)
    }

    func loadAccessToken() -> String? {
        load(forKey: accessTokenKey)
    }

    func loadRefreshToken() -> String? {
        load(forKey: refreshTokenKey)
    }

    func clearTokens() {
        delete(forKey: accessTokenKey)
        delete(forKey: refreshTokenKey)
        delete(forKey: expiresAtKey)
    }

    private func save(_ value: String, forKey key: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
}
