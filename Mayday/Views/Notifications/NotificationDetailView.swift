import SwiftUI

struct NotificationDetailView: View {
    let notification: AppNotification
    let viewModel: NotificationsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header
                headerSection

                // Info cards
                VStack(spacing: 16) {
                    detailsCard
                    
                    if let metadata = notification.metadata, !metadata.isEmpty {
                        metadataCard(metadata)
                    }

                    statusCard
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
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("details_section")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.markAsRead(notification)
        }
    }

    // MARK: - Hero Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 88, height: 88)
                    .shadow(color: topicColor.opacity(0.3), radius: 12, y: 4)
                Circle()
                    .fill(topicColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: topicIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(topicColor)
            }

            VStack(spacing: 6) {
                Text(notification.subject)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            statusBadge
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        let (text, color): (String, Color) = notification.isRead
            ? (String(localized: "status_read"), .green)
            : (String(localized: "status_new"), .red)
        return Text(text)
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Details Card

    private var detailsCard: some View {
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
        .background(.white)
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
        .background(.white)
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

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("status_section", systemImage: "clock.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            VStack(spacing: 8) {
                infoRow(icon: "paperplane.fill", label: String(localized: "channel_label"), value: channelLabel)
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
        .background(.white)
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

    private var channelLabel: String {
        switch notification.channel {
        case .inApp: return String(localized: "channel_in_app")
        case .push: return "Push"
        case .email: return "Email"
        }
    }

    private var topicIcon: String {
        let lowered = notification.topic.lowercased()
        if lowered.contains("fire") || lowered.contains("пожар") || lowered.contains("огонь") {
            return "flame.fill"
        } else if lowered.contains("medical") || lowered.contains("медиц") || lowered.contains("здоров") {
            return "heart.fill"
        } else if lowered.contains("security") || lowered.contains("безопас") {
            return "shield.fill"
        } else if lowered.contains("water") || lowered.contains("вод") || lowered.contains("затоп") {
            return "drop.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }

    private var topicColor: Color {
        let lowered = notification.topic.lowercased()
        if lowered.contains("fire") || lowered.contains("пожар") || lowered.contains("огонь") {
            return .red
        } else if lowered.contains("medical") || lowered.contains("медиц") || lowered.contains("здоров") {
            return .green
        } else if lowered.contains("security") || lowered.contains("безопас") {
            return .blue
        } else if lowered.contains("water") || lowered.contains("вод") || lowered.contains("затоп") {
            return .cyan
        } else {
            return .orange
        }
    }
}
