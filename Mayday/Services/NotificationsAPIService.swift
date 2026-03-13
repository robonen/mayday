import Foundation
import UIKit

actor NotificationsAPIService {
    static let shared = NotificationsAPIService()
    private let client = HTTPClient.shared

    private init() {}

    func getNotifications(page: Int = 1, perPage: Int = 20) async throws -> NotificationsPage {
        try await client.request(.getNotifications(page: page, perPage: perPage))
    }

    func markAsRead(id: UUID) async throws {
        let _: AppNotification = try await client.request(.markAsRead(id: id))
    }

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

    func updateAppBadge(_ count: Int) async {
        await UIApplication.shared.setApplicationIconBadgeNumber(count)
    }
}

struct LogoutAllResponse: Decodable {
    let revokedSessions: Int

    enum CodingKeys: String, CodingKey {
        case revokedSessions = "revoked_sessions"
    }
}
