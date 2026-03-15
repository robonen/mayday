import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = NotificationsViewModel()
    @State private var showSettings = false

    private var unreadNotifications: [AppNotification] {
        viewModel.notifications.filter { !$0.isRead }
    }

    private var readNotifications: [AppNotification] {
        viewModel.notifications.filter { $0.isRead }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView()
                } else if let error = viewModel.error, viewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "loading_error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "no_notifications",
                        systemImage: "bell.slash",
                        description: Text("no_notifications_description")
                    )
                } else {
                    notificationsList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("notifications_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authViewModel)
            }
            .task {
                await viewModel.load()
                viewModel.startPolling()
            }
            .onDisappear {
                viewModel.stopPolling()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }

    var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if !unreadNotifications.isEmpty {
                    sectionHeader(String(localized: "notifications_active"))
                    ForEach(unreadNotifications) { notification in
                        NavigationLink(destination: NotificationDetailView(notification: notification, viewModel: viewModel)) {
                            ActiveNotificationCard(notification: notification)
                        }
                        .id("\(notification.id)-\(notification.isRead)")
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .onAppear {
                            if notification.id == viewModel.notifications.last?.id {
                                Task { await viewModel.loadMore() }
                            }
                        }
                    }
                }

                if !readNotifications.isEmpty {
                    sectionHeader(String(localized: "notifications_completed"))
                    ForEach(readNotifications) { notification in
                        NavigationLink(destination: NotificationDetailView(notification: notification, viewModel: viewModel)) {
                            ResolvedNotificationCard(notification: notification)
                        }
                        .id("\(notification.id)-\(notification.isRead)")
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .onAppear {
                            if notification.id == viewModel.notifications.last?.id {
                                Task { await viewModel.loadMore() }
                            }
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, 20)
                }
            }
            .padding(.top, 4)
        }
    }

    func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Active (Unread) Card

struct ActiveNotificationCard: View {
    let notification: AppNotification

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                NotificationIconView(severity: NotificationSeverity(from: notification.metadata), isActive: true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(notification.subject ?? "")
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let source = notification.source {
                        Text(source)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                Spacer()

                Text(notification.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            if !notification.body.isEmpty {
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }

            HStack {
                Spacer()
                Text("open_button")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Spacer()
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.red, Color.red.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
    }
}

// MARK: - Resolved (Read) Card

struct ResolvedNotificationCard: View {
    let notification: AppNotification

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                NotificationIconView(severity: NotificationSeverity(from: notification.metadata), isActive: false)

                VStack(alignment: .leading, spacing: 2) {
                    Text(notification.subject ?? "")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let source = notification.source {
                        Text(source)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(notification.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(notification.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if !notification.body.isEmpty {
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let readAt = notification.readAt {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text("notification_read_at \(readAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}
