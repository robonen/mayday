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
            case title, value, status, startedAt, updatedAt
        }

        init(title: String, value: String?, status: AlertStatus, startedAt: Date, updatedAt: Date) {
            self.title = title
            self.value = value
            self.status = status
            self.startedAt = startedAt
            self.updatedAt = updatedAt
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            title = try c.decode(String.self, forKey: .title)
            value = try c.decodeIfPresent(String.self, forKey: .value)
            status = try c.decode(AlertStatus.self, forKey: .status)
            startedAt = try Self.decodeDate(from: c, forKey: .startedAt)
            updatedAt = try Self.decodeDate(from: c, forKey: .updatedAt)
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(title, forKey: .title)
            try c.encodeIfPresent(value, forKey: .value)
            try c.encode(status, forKey: .status)
            try c.encode(Self.isoFormatter.string(from: startedAt), forKey: .startedAt)
            try c.encode(Self.isoFormatter.string(from: updatedAt), forKey: .updatedAt)
        }

        // ActivityKit uses the default JSONDecoder when materialising ContentState
        // from a remote push payload, so dates round-trip as ISO8601 strings
        // matching the backend's time.RFC3339[Nano] output. Both formatters are
        // pre-built and treated as immutable; ISO8601DateFormatter is documented
        // thread-safe for read use.
        nonisolated(unsafe) private static let isoWithFractional: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
        nonisolated(unsafe) private static let isoWithoutFractional: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            return f
        }()
        // Single shared encoder format: ISO8601 without fractional seconds,
        // since iOS reconstructs Date from string and sub-second precision is
        // irrelevant for the alert timestamps we surface.
        private static var isoFormatter: ISO8601DateFormatter { isoWithoutFractional }

        private static func decodeDate(from c: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
            let s = try c.decode(String.self, forKey: key)
            if let d = isoWithFractional.date(from: s) ?? isoWithoutFractional.date(from: s) {
                return d
            }
            throw DecodingError.dataCorruptedError(forKey: key, in: c, debugDescription: "Invalid ISO8601 date: \(s)")
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
