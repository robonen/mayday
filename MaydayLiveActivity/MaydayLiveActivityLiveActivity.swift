import ActivityKit
import SwiftUI
import WidgetKit

struct MaydayLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlertAttributes.self) { context in
            // MARK: - Lock Screen / Banner / StandBy

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(severityColor(context.attributes.severity))
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(context.attributes.topic)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(context.state.startedAt, style: .relative)
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(.tertiary)
                            .contentTransition(.numericText(countsDown: false))
                    }

                    Text(context.state.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    HStack(alignment: .firstTextBaseline) {
                        if let value = context.state.value {
                            Text(value)
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundStyle(severityColor(context.attributes.severity))
                                .contentTransition(.numericText())
                        }

                        Spacer()

                        statusLabel(context.state.status)
                    }
                }
            }
            .padding(14)
            .activityBackgroundTint(severityColor(context.attributes.severity).opacity(0.12))
            .activitySystemActionForegroundColor(severityColor(context.attributes.severity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(context.attributes.severity.rawValue) alert: \(context.state.title)")

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded

                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 5) {
                        Image(systemName: severityIcon(context.attributes.severity))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(severityColor(context.attributes.severity))
                            .fixedSize()

                        Text(context.attributes.topic)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 90, alignment: .leading)
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startedAt, style: .relative)
                        .font(.caption)
                        .fontWeight(.medium)
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.6))
                        .contentTransition(.numericText(countsDown: false))
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom, priority: 1) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.state.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            if let value = context.state.value {
                                Text(value)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(severityColor(context.attributes.severity))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        severityColor(context.attributes.severity).opacity(0.2),
                                        in: ContainerRelativeShape()
                                    )
                                    .contentTransition(.numericText())
                            }

                            Spacer()

                            statusLabel(context.state.status)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
                }

            } compactLeading: {
                // MARK: - Compact
                HStack(spacing: 4) {
                    Image(systemName: severityIcon(context.attributes.severity))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(severityColor(context.attributes.severity))
                        .fixedSize()

                    Text(context.attributes.topic)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 70, alignment: .leading)
                }
                .padding(.leading, 4)

            } compactTrailing: {
                Text(context.state.startedAt, style: .timer)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.8))
                    .contentTransition(.numericText(countsDown: false))
                    .frame(maxWidth: 40, alignment: .trailing)
                    .padding(.trailing, 4)

            } minimal: {
                Image(systemName: severityIcon(context.attributes.severity))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(severityColor(context.attributes.severity))
            }
            .keylineTint(severityColor(context.attributes.severity))
        }
    }
}

// MARK: - Helpers

private func severityColor(_ severity: Severity) -> Color {
    switch severity {
    case .critical: .red
    case .warning: .orange
    case .info: .cyan
    }
}

private func severityIcon(_ severity: Severity) -> String {
    switch severity {
    case .critical: "exclamationmark.triangle.fill"
    case .warning: "exclamationmark.circle.fill"
    case .info: "info.circle.fill"
    }
}

@ViewBuilder
private func statusLabel(_ status: AlertStatus) -> some View {
    HStack(spacing: 4) {
        Circle()
            .fill(status == .active ? Color.red : Color.green)
            .frame(width: 5, height: 5)

        Text(status == .active ? "Active" : "Resolved")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(status == .active ? .red : .green)
    }
}

#Preview("Live Activity", as: .content, using: AlertAttributes(
    topic: "server-health",
    alertId: "alert-001",
    severity: .critical
)) {
    MaydayLiveActivityLiveActivity()
} contentStates: {
    AlertAttributes.ContentState(
        title: "CPU Usage Exceeded 95%",
        value: "Current: 97.3%",
        status: .active,
        startedAt: .now.addingTimeInterval(-300),
        updatedAt: .now
    )
    AlertAttributes.ContentState(
        title: "CPU Usage Normalized",
        value: "Current: 42.1%",
        status: .resolved,
        startedAt: .now.addingTimeInterval(-600),
        updatedAt: .now
    )
}
