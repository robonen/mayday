import Foundation

struct SessionResponse: Codable, Identifiable, Sendable {
    let id: UUID
    let userAgent: String
    let ipAddress: String
    let isCurrent: Bool
    let createdAt: Date
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userAgent = "user_agent"
        case ipAddress = "ip_address"
        case isCurrent = "is_current"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}
