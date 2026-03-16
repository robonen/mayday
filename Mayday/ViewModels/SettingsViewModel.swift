import Foundation
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    var sessions: [SessionResponse] = []
    var isLoading = false
    var error: String?
    var successMessage: String?

    private let service = NotificationsAPIService.shared

    func loadSessions() async {
        isLoading = true
        defer { isLoading = false }
        do {
            sessions = try await service.getSessions()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteSession(_ session: SessionResponse) async {
        do {
            try await service.deleteSession(id: session.id)
            sessions.removeAll { $0.id == session.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func changePassword(current: String, new: String) async -> Bool {
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
