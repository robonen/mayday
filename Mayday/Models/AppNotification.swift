import Foundation

struct AppNotification: Codable, Identifiable {
    let id: UUID
    let topic: String
    let subject: String
    let body: String
    let metadata: [String: String]?
    let status: NotificationStatus
    let channel: NotificationChannel
    let readAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, topic, subject, body, metadata, status, channel
        case readAt = "read_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isRead: Bool { readAt != nil }
}

enum NotificationStatus: String, Codable {
    case sent
    case delivered
    case read
}

enum NotificationChannel: String, Codable {
    case inApp = "in_app"
    case push
    case email
}

struct NotificationsPage: Codable {
    let items: [AppNotification]
    let total: Int
    let page: Int
    let perPage: Int

    enum CodingKeys: String, CodingKey {
        case items, total, page
        case perPage = "per_page"
    }
}
