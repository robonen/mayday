import ActivityKit
import WidgetKit
import SwiftUI

struct MaydayLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlertAttributes.self) { context in
            // Lock Screen / Notification Center
            lockScreenView(context: context)
                .activityBackgroundTint(severityColor(context.attributes.severity).opacity(0.15))
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.topic, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(severityColor(context.attributes.severity))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let value = context.state.value {
                        Text(value)
                            .font(.caption.bold())
                            .foregroundStyle(severityColor(context.attributes.severity))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.title)
                                .font(.subheadline.bold())
                            Text("Начало: \(context.state.startedAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            statusBadge(context.state.status)
                            // Text(date, style: .timer) updates automatically without re-render.
                            HStack(spacing: 2) {
                                Text("Длит.:")
                                Text(context.state.startedAt, style: .timer)
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(severityColor(context.attributes.severity))
            } compactTrailing: {
                let shortTopic = context.attributes.topic.components(separatedBy: "/").last ?? context.attributes.topic
                let valueText = context.state.value.map { " · \($0)" } ?? ""
                Text("\(shortTopic)\(valueText)")
                    .font(.caption2)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(severityColor(context.attributes.severity))
            }
            .keylineTint(severityColor(context.attributes.severity))
        }
    }

    @ViewBuilder
    func lockScreenView(context: ActivityViewContext<AlertAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(severityColor(context.attributes.severity))

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.topic)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.state.title)
                    .font(.subheadline.bold())
                if let value = context.state.value {
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(severityColor(context.attributes.severity))
                }
                // Text(date, style: .relative) updates automatically without re-render.
                Text(context.state.startedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusBadge(context.state.status)
        }
        .padding()
    }

    @ViewBuilder
    func statusBadge(_ status: AlertStatus) -> some View {
        let (text, color): (String, Color) = status == .active
            ? ("активен", .red)
            : ("завершён", .green)
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(4)
    }

    func severityColor(_ severity: Severity) -> Color {
        switch severity {
        case .critical: return .red
        case .warning: return .yellow
        case .info: return .blue
        }
    }
}
