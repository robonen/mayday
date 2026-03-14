import Foundation

actor NotificationsAPIService {
    static let shared = NotificationsAPIService()
    private let client = HTTPClient.shared

    private init() {}

    // MARK: - Notifications

    func getNotifications(limit: Int = 50, offset: Int = 0, unreadOnly: Bool = false, scope: String? = nil) async throws -> NotificationsPage {
        try await client.request(.getNotifications(limit: limit, offset: offset, unreadOnly: unreadOnly, scope: scope))
    }

    func markAsRead(id: UUID) async throws {
        let _: EmptyResponse = try await client.request(.markAsRead(id: id))
    }

    func markAllAsRead(scope: String? = nil) async throws {
        let _: EmptyResponse = try await client.request(.markAllAsRead(scope: scope))
    }

    // MARK: - Devices

    func listDevices() async throws -> [DeviceToken] {
        try await client.request(.listDevices)
    }

    func registerDevice(token: String, platform: String = "ios") async throws -> DeviceToken {
        try await client.request(.registerDevice(token: token, platform: platform))
    }

    func unregisterDevice(id: UUID) async throws {
        let _: EmptyResponse = try await client.request(.unregisterDevice(id: id))
    }

    // MARK: - Preferences

    func getPreferences() async throws -> [NotificationPreference] {
        try await client.request(.getPreferences)
    }

    func upsertPreference(channel: String, enabled: Bool, config: [String: String]? = nil) async throws {
        let _: EmptyResponse = try await client.request(.upsertPreference(channel: channel, enabled: enabled, config: config))
    }

    // MARK: - SSO (User Management)

    func getSessions() async throws -> [SessionResponse] {
        try await client.request(.getSessions)
    }

    func deleteSession(id: UUID) async throws {
        let _: EmptyResponse = try await client.request(.deleteSession(id: id))
    }

    func logoutAll() async throws -> Int {
        let response: LogoutAllResponse = try await client.request(.logoutAll)
        return response.revokedSessions
    }

    func changePassword(current: String, new: String) async throws -> UserResponse {
        try await client.request(.changePassword(current: current, new: new))
    }
}

struct LogoutAllResponse: Decodable {
    let revokedSessions: Int

    enum CodingKeys: String, CodingKey {
        case revokedSessions = "revoked_sessions"
    }
}
