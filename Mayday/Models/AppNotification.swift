import Foundation

struct AppNotification: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let scopeId: UUID?
    let channel: NotificationChannel
    let contentType: ContentType
    let templateId: UUID?
    let subject: String?
    let body: String
    let source: String?
    let metadata: [String: String]?
    let status: NotificationStatus
    let error: String?
    let attempts: Int
    let maxAttempts: Int
    let nextRetryAt: Date?
    let sentAt: Date?
    let readAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case scopeId = "scope_id"
        case channel
        case contentType = "content_type"
        case templateId = "template_id"
        case subject, body, source, metadata, status, error, attempts
        case maxAttempts = "max_attempts"
        case nextRetryAt = "next_retry_at"
        case sentAt = "sent_at"
        case readAt = "read_at"
        case createdAt = "created_at"
    }

    var isRead: Bool { readAt != nil }

    func withReadAt(_ date: Date) -> AppNotification {
        AppNotification(
            id: id, userId: userId, scopeId: scopeId, channel: channel,
            contentType: contentType, templateId: templateId, subject: subject,
            body: body, source: source, metadata: metadata, status: .read,
            error: error, attempts: attempts, maxAttempts: maxAttempts,
            nextRetryAt: nextRetryAt, sentAt: sentAt, readAt: date, createdAt: createdAt
        )
    }
}

enum NotificationStatus: String, Codable, Sendable {
    case pending
    case sent
    case failed
    case read
}

enum NotificationChannel: String, Codable, Sendable {
    case email
    case telegram
    case inApp = "in_app"
    case webhook
    case apns
}

enum ContentType: String, Codable, Sendable {
    case plain
    case html
    case markdown
}

struct NotificationsPage: Codable, Sendable {
    let notifications: [AppNotification]
    let total: Int
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case notifications, total
        case unreadCount = "unread_count"
    }
}

struct DeviceToken: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let platform: String
    let token: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case platform, token
        case createdAt = "created_at"
    }
}

struct NotificationPreference: Codable, Sendable {
    let userId: UUID
    let channel: NotificationChannel
    let enabled: Bool
    let config: [String: String]?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case channel, enabled, config
    }
}
