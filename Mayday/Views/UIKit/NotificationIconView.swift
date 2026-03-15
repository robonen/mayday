import SwiftUI

enum NotificationSeverity: String {
    case critical
    case warning
    case info
    case success

    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .warning:  return "exclamationmark.circle.fill"
        case .info:     return "info.circle.fill"
        case .success:  return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .critical: return .red
        case .warning:  return .orange
        case .info:     return .blue
        case .success:  return .green
        }
    }

    init(from metadata: [String: String]?) {
        let raw = metadata?["severity"]?.lowercased() ?? ""
        self = NotificationSeverity(rawValue: raw) ?? .info
    }
}

struct NotificationIconView: View {
    let severity: NotificationSeverity
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? .white.opacity(0.25) : severity.color.opacity(0.12))
                .frame(width: 40, height: 40)
            Image(systemName: severity.icon)
                .font(.body)
                .foregroundStyle(isActive ? .white : severity.color)
        }
    }
}
