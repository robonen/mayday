import SwiftUI

struct NotificationDetailView: View {
    let notificationId: UUID
    var viewModel: NotificationsViewModel

    private var notification: AppNotification? {
        viewModel.notifications.first { $0.id == notificationId }
    }

    init(notification: AppNotification, viewModel: NotificationsViewModel) {
        self.notificationId = notification.id
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if let notification {
                scrollContent(notification)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("details_section")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let notification, !notification.isRead {
                await viewModel.markAsRead(notification)
            }
        }
    }

    private func scrollContent(_ notification: AppNotification) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header
                headerSection(notification)

                // Info cards
                VStack(spacing: 16) {
                    detailsCard(notification)
                    
                    if let metadata = notification.metadata, !metadata.isEmpty {
                        metadataCard(metadata)
                    }

                    statusCard(notification)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 32)

                // Mark as read button for unread notifications
                if !notification.isRead {
                    Button {
                        Task { await viewModel.markAsRead(notification) }
                    } label: {
                        Text("mark_as_read")
                            .font(.headline)
                            .foregroundStyle(.brand)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.brand.opacity(0.1))
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: - Hero Header

    private func headerSection(_ notification: AppNotification) -> some View {
        let severity = NotificationSeverity(from: notification.metadata)
        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(width: 88, height: 88)
                    .shadow(color: severity.color.opacity(0.3), radius: 12, y: 4)
                Circle()
                    .fill(severity.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: severity.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(severity.color)
            }

            VStack(spacing: 6) {
                Text(notification.subject ?? "")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            statusBadge(for: notification)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Status Badge

    private func statusBadge(for notification: AppNotification) -> some View {
        let (text, color): (String, Color) = notification.isRead
            ? (String(localized: "status_read"), .success)
            : (String(localized: "status_new"), .brand)
        return Text(text)
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Details Card

    private func detailsCard(_ notification: AppNotification) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("details_section", systemImage: "doc.text.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            Text(notification.body)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Metadata Card

    private func metadataCard(_ metadata: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("info_section", systemImage: "info.circle.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            let sortedKeys = metadata.keys.sorted()
            let columns = min(sortedKeys.count, 2)

            if columns == 1 {
                ForEach(sortedKeys, id: \.self) { key in
                    metadataItem(key: key, value: metadata[key] ?? "")
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(sortedKeys, id: \.self) { key in
                        metadataItem(key: key, value: metadata[key] ?? "")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func metadataItem(key: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Status Card

    private func statusCard(_ notification: AppNotification) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("status_section", systemImage: "clock.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            VStack(spacing: 8) {
                infoRow(icon: "paperplane.fill", label: String(localized: "channel_label"), value: channelLabel(for: notification))
                Divider()
                infoRow(icon: "clock", label: String(localized: "received_label"), value: notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                if let readAt = notification.readAt {
                    Divider()
                    infoRow(icon: "checkmark.circle.fill", label: String(localized: "read_at_label"), value: readAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Helpers

    private func channelLabel(for notification: AppNotification) -> String {
        switch notification.channel {
        case .inApp: return String(localized: "channel_in_app")
        case .apns: return "Push"
        case .email: return "Email"
        case .telegram: return "Telegram"
        case .webhook: return "Webhook"
        }
    }
}

#Preview {
    let notification = AppNotification(
        id: UUID(), userId: UUID(), scopeId: nil, channel: .inApp,
        contentType: .plain, templateId: nil, subject: "CPU Usage Critical",
        body: "Server load has exceeded 95% for the last 5 minutes. Immediate action is required to prevent service degradation.",
        source: "monitoring", metadata: ["severity": "critical", "host": "prod-01", "region": "eu-west-1"],
        status: .sent, error: nil, attempts: 1, maxAttempts: 3,
        nextRetryAt: nil, sentAt: Date(), readAt: nil, createdAt: Date()
    )
    let vm = NotificationsViewModel()
    NavigationStack {
        NotificationDetailView(notification: notification, viewModel: vm)
    }
}
