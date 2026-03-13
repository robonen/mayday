import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserResponse?
    @Published var isLoading = false
    @Published var error: String?

    private let auth = AuthService.shared
    private let keychain = KeychainService.shared

    func checkAuthStatus() async {
        guard keychain.loadAccessToken() != nil else {
            isAuthenticated = false
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            currentUser = try await auth.getMe()
            isAuthenticated = true
            await requestPushIfNeeded()
        } catch APIError.unauthorized {
            isAuthenticated = false
        } catch {
            isAuthenticated = false
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            currentUser = try await auth.login(email: email, password: password)
            isAuthenticated = true
            await requestPushIfNeeded()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func register(email: String, password: String) async -> Bool {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            _ = try await auth.register(email: email, password: password)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func verifyEmail(email: String, code: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            _ = try await auth.verifyEmail(email: email, code: code)
            // Auto-login after verification is handled by calling login from view
        } catch {
            self.error = error.localizedDescription
        }
    }

    func logout() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.logout()
        } catch {
            // Clear anyway
            keychain.clearTokens()
        }
        isAuthenticated = false
        currentUser = nil
    }

    private func requestPushIfNeeded() async {
        let granted = await PushNotificationService.shared.requestPermission()
        if granted {
            PushNotificationService.shared.registerForRemoteNotifications()
        }
    }
}
