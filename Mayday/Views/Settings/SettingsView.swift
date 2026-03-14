import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showChangePassword = false
    @State private var showSessions = false
    @State private var showLogoutAllConfirm = false
    @State private var logoutAllError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("account_section") {
                    if let user = authViewModel.currentUser {
                        LabeledContent("Email", value: user.email)
                    }
                }

                Section {
                    Button("change_password") {
                        showChangePassword = true
                    }

                    Button {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("push_notifications", systemImage: "bell.badge")
                            .foregroundStyle(.primary)
                    }
                }

                Section {
                    Button {
                        showSessions = true
                    } label: {
                        HStack {
                            Text("active_sessions")
                            Spacer()
                            if !viewModel.sessions.isEmpty {
                                Text("(\(viewModel.sessions.count))")
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section {
                    Button("logout_button", role: .destructive) {
                        Task { await authViewModel.logout() }
                    }

                    Button("logout_all_button", role: .destructive) {
                        showLogoutAllConfirm = true
                    }
                }
            }
            .navigationTitle("settings_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done_button") { dismiss() }
                }
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
            }
            .sheet(isPresented: $showSessions) {
                SessionsView()
                    .environmentObject(viewModel)
            }
            .confirmationDialog(
                "logout_all_confirm",
                isPresented: $showLogoutAllConfirm,
                titleVisibility: .visible
            ) {
                Button("logout_all_action", role: .destructive) {
                    Task {
                        do {
                            _ = try await NotificationsAPIService.shared.logoutAll()
                            await authViewModel.logout()
                        } catch {
                            logoutAllError = error.localizedDescription
                        }
                    }
                }
                Button("cancel", role: .cancel) {}
            }
            .alert(
                "error_title",
                isPresented: Binding(
                    get: { logoutAllError != nil },
                    set: { if !$0 { logoutAllError = nil } }
                )
            ) {
                Button("OK") { logoutAllError = nil }
            } message: {
                Text(logoutAllError ?? "")
            }
            .task {
                await viewModel.loadSessions()
            }
        }
    }
}
