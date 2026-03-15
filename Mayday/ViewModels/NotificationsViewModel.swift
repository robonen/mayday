import Foundation
import SwiftUI
import UIKit

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount = 0
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var hasMore = true
    private var hasLoadedOnce = false

    private let service = NotificationsAPIService.shared
    private let limit = 50
    private var currentOffset = 0
    private var pollingTask: Task<Void, Never>?

    func load() async {
        isLoading = !hasLoadedOnce
        error = nil
        currentOffset = 0
        defer {
            isLoading = false
            hasLoadedOnce = true
        }
        do {
            let page = try await service.getNotifications(limit: limit, offset: 0)
            notifications = page.notifications
            unreadCount = page.unreadCount
            hasMore = notifications.count < page.total
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
            let nextOffset = notifications.count
            let page = try await service.getNotifications(limit: limit, offset: nextOffset)
            notifications.append(contentsOf: page.notifications)
            unreadCount = page.unreadCount
            currentOffset = nextOffset
            hasMore = notifications.count < page.total
        } catch {
            self.error = error.localizedDescription
        }
    }

    func markAsRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }

        // Optimistic update — reflect read state immediately so the list
        // shows the correct card style even if the user navigates back
        // before the API call completes.
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = notification.withReadAt(Date())
            unreadCount = max(0, unreadCount - 1)
            updateBadge()
        }

        do {
            try await service.markAsRead(id: notification.id)
        } catch is CancellationError {
            // View disappeared before the request finished — keep
            // optimistic state; polling will reconcile if needed.
        } catch {
            // Rollback on real failure
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = notification
                unreadCount += 1
                updateBadge()
            }
            self.error = error.localizedDescription
        }
    }

    func markAllAsRead() async {
        do {
            try await service.markAllAsRead()
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func startPolling() {
        guard pollingTask == nil else { return }
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
        UNUserNotificationCenter.current().setBadgeCount(unreadCount)
    }
}
