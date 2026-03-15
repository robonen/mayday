import Foundation

struct UserResponse: Codable, Identifiable, Sendable {
    let id: UUID
    let email: String
    let status: UserStatus
    let metadata: [String: AnyCodable]?
    let emailVerifiedAt: Date?
    let roles: [String]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email, status, metadata, roles
        case emailVerifiedAt = "email_verified_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(id: UUID, email: String, status: UserStatus, metadata: [String: AnyCodable]? = nil, emailVerifiedAt: Date? = nil, roles: [String] = [], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.email = email
        self.status = status
        self.metadata = metadata
        self.emailVerifiedAt = emailVerifiedAt
        self.roles = roles
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        status = try container.decode(UserStatus.self, forKey: .status)
        metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        emailVerifiedAt = try container.decodeIfPresent(Date.self, forKey: .emailVerifiedAt)
        roles = try container.decodeIfPresent([String].self, forKey: .roles) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

enum UserStatus: String, Codable, Sendable {
    case pending
    case active
    case suspended
    case deleted
}

// Helper for Any JSON values
struct AnyCodable: Codable, @unchecked Sendable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let string = try? container.decode(String.self) {
            value = string
        } else {
            value = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let bool as Bool: try container.encode(bool)
        case let string as String: try container.encode(string)
        default: try container.encode("")
        }
    }
}
