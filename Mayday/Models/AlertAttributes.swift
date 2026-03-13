import ActivityKit
import Foundation

struct AlertAttributes: ActivityAttributes {
    let topic: String
    let alertId: String
    let severity: Severity

    struct ContentState: Codable, Hashable {
        let title: String
        let value: String?
        let status: AlertStatus
        let startedAt: Date
        let updatedAt: Date

        enum CodingKeys: String, CodingKey {
            case title, value, status
            case startedAt = "startedAt"
            case updatedAt = "updatedAt"
        }
    }
}

enum Severity: String, Codable, Hashable {
    case critical
    case warning
    case info

    var color: String {
        switch self {
        case .critical: return "red"
        case .warning: return "yellow"
        case .info: return "blue"
        }
    }

    var emoji: String {
        switch self {
        case .critical: return "🔴"
        case .warning: return "🟡"
        case .info: return "🔵"
        }
    }
}

enum AlertStatus: String, Codable, Hashable {
    case active
    case resolved
}
