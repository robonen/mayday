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
            successMessage = "Пароль успешно изменён"
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}
