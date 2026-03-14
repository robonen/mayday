import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var sessions: [SessionResponse] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var successMessage: String?

    private let service = NotificationsAPIService.shared

    func loadSessions() async {
        #if DEBUG
        if PreviewData.isPreviewMode {
            sessions = PreviewData.mockSessions
            return
        }
        #endif
        isLoading = true
        defer { isLoading = false }
        do {
            sessions = try await service.getSessions()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteSession(_ session: SessionResponse) async {
        #if DEBUG
        if PreviewData.isPreviewMode {
            sessions.removeAll { $0.id == session.id }
            return
        }
        #endif
        do {
            try await service.deleteSession(id: session.id)
            sessions.removeAll { $0.id == session.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func changePassword(current: String, new: String) async -> Bool {
        #if DEBUG
        if PreviewData.isPreviewMode {
            successMessage = String(localized: "password_changed_success")
            return true
        }
        #endif
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            _ = try await service.changePassword(current: current, new: new)
            successMessage = String(localized: "password_changed_success")
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}
