import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = NotificationsViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView()
                } else if let error = viewModel.error, viewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "Ошибка загрузки",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "Нет уведомлений",
                        systemImage: "bell.slash",
                        description: Text("Новые уведомления появятся здесь")
                    )
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Уведомления")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
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
        List {
            ForEach(viewModel.notifications) { notification in
                NavigationLink(destination: NotificationDetailView(notification: notification, viewModel: viewModel)) {
                    NotificationRowView(notification: notification)
                }
                .swipeActions(edge: .leading) {
                    if !notification.isRead {
                        Button {
                            Task { await viewModel.markAsRead(notification) }
                        } label: {
                            Label("Прочитано", systemImage: "checkmark")
                        }
                        .tint(.blue)
                    }
                }
                .onAppear {
                    if notification.id == viewModel.notifications.last?.id {
                        Task { await viewModel.loadMore() }
                    }
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .listStyle(.plain)
    }
}

struct NotificationRowView: View {
    let notification: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(notification.isRead ? Color.clear : Color.blue)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.topic)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(notification.subject)
                    .font(.body)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                Text(notification.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
