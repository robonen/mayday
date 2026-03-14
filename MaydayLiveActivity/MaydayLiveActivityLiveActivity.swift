import ActivityKit
import WidgetKit
import SwiftUI

struct MaydayLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlertAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(severityColor(context.attributes.severity).opacity(0.12))
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: severityIcon(context.attributes.severity))
                            .font(.caption)
                        Text(context.attributes.topic)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(severityColor(context.attributes.severity))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    statusBadge(context.state.status)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(context.state.title)
                                    .font(.subheadline.bold())
                                if let value = context.state.value {
                                    Text(value)
                                        .font(.caption)
                                        .foregroundStyle(severityColor(context.attributes.severity))
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                HStack(spacing: 3) {
                                    Image(systemName: "clock")
                                        .font(.caption2)
                                    Text(context.state.startedAt, style: .timer)
                                        .font(.caption.monospacedDigit())
                                }
                                .foregroundStyle(.secondary)
                                Text(context.state.startedAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: severityIcon(context.attributes.severity))
                    .foregroundStyle(severityColor(context.attributes.severity))
            } compactTrailing: {
                let shortTopic = context.attributes.topic.components(separatedBy: "/").last ?? context.attributes.topic
                let valueText = context.state.value.map { " · \($0)" } ?? ""
                Text("\(shortTopic)\(valueText)")
                    .font(.caption2)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: severityIcon(context.attributes.severity))
                    .foregroundStyle(severityColor(context.attributes.severity))
            }
            .keylineTint(severityColor(context.attributes.severity))
        }
    }

    @ViewBuilder
    func lockScreenView(context: ActivityViewContext<AlertAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(severityColor(context.attributes.severity).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: severityIcon(context.attributes.severity))
                        .font(.title3)
                        .foregroundStyle(severityColor(context.attributes.severity))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(context.state.title)
                        .font(.subheadline.bold())
                    Text(context.attributes.topic)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                statusBadge(context.state.status)
            }

            HStack(spacing: 16) {
                if let value = context.state.value {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(severityColor(context.attributes.severity))
                            .frame(width: 6, height: 6)
                        Text(value)
                            .font(.caption.bold())
                            .foregroundStyle(severityColor(context.attributes.severity))
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(context.state.startedAt, style: .relative)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }

    @ViewBuilder
    func statusBadge(_ status: AlertStatus) -> some View {
        let (text, color): (String, Color) = status == .active
            ? ("активен", .red)
            : ("завершён", .green)
        Text(text)
            .font(.caption2.bold())
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    func severityColor(_ severity: Severity) -> Color {
        switch severity {
        case .critical: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }

    func severityIcon(_ severity: Severity) -> String {
        switch severity {
        case .critical: return "flame.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}
