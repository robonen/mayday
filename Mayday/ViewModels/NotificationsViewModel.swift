import Foundation
import SwiftUI

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var hasMore = true

    private let service = NotificationsAPIService.shared
    private var currentPage = 1
    private let perPage = 20
    private var pollingTask: Task<Void, Never>?

    func load() async {
        isLoading = true
        error = nil
        currentPage = 1
        defer { isLoading = false }
        do {
            let page = try await service.getNotifications(page: 1, perPage: perPage)
            notifications = page.items
            hasMore = page.items.count == perPage
            updateBadge()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadMore() async {
        guard !isLoadingMore && hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let nextPage = currentPage + 1
            let page = try await service.getNotifications(page: nextPage, perPage: perPage)
            notifications.append(contentsOf: page.items)
            currentPage = nextPage
            hasMore = page.items.count == perPage
        } catch {
            self.error = error.localizedDescription
        }
    }

    func markAsRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }
        do {
            try await service.markAsRead(id: notification.id)
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                let updated = AppNotification(
                    id: notification.id,
                    topic: notification.topic,
                    subject: notification.subject,
                    body: notification.body,
                    metadata: notification.metadata,
                    status: .read,
                    channel: notification.channel,
                    readAt: Date(),
                    createdAt: notification.createdAt,
                    updatedAt: Date()
                )
                notifications[index] = updated
            }
            updateBadge()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { break }
                await load()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func updateBadge() {
        let unreadCount = notifications.filter { !$0.isRead }.count
        Task {
            await service.updateAppBadge(unreadCount)
        }
    }
}
