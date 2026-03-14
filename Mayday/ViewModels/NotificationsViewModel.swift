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

    private let service = NotificationsAPIService.shared
    private let limit = 50
    private var currentOffset = 0
    private var pollingTask: Task<Void, Never>?

    func load() async {
        #if DEBUG
        if PreviewData.isPreviewMode {
            notifications = PreviewData.mockNotifications
            hasMore = false
            return
        }
        #endif
        isLoading = true
        error = nil
        currentOffset = 0
        defer { isLoading = false }
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
        #if DEBUG
        if PreviewData.isPreviewMode { return }
        #endif
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
        #if DEBUG
        if PreviewData.isPreviewMode {
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = notification.withReadAt(Date())
            }
            return
        }
        #endif
        do {
            try await service.markAsRead(id: notification.id)
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = notification.withReadAt(Date())
            }
            updateBadge()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func markAllAsRead() async {
        #if DEBUG
        if PreviewData.isPreviewMode { return }
        #endif
        do {
            try await service.markAllAsRead()
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func startPolling() {
        #if DEBUG
        if PreviewData.isPreviewMode { return }
        #endif
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
