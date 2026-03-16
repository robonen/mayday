import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showChangePassword = false
    @State private var showSessions = false
    @State private var showLogoutAllConfirm = false
    @State private var logoutAllError: String?
    @State private var showLogoutAllError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("account_section") {
                    if let user = authViewModel.currentUser {
                        LabeledContent("Email", value: user.email)
                    }
                }

                Section {
                    Button {
                        showChangePassword = true
                    } label: {
                        Text("change_password")
                    }
                    .tint(.primary)

                    Button {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("push_notifications", systemImage: "bell.badge")
                    }
                    .tint(.primary)
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
                    .tint(.primary)
                }

                Section {
                    Button("logout_button", role: .destructive) {
                        Task { await authViewModel.logout() }
                    }

                    Button("logout_all_button", role: .destructive) {
                        showLogoutAllConfirm = true
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
                                    showLogoutAllError = true
                                }
                            }
                        }
                        Button("cancel", role: .cancel) {}
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
                ChangePasswordView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSessions) {
                SessionsView(viewModel: viewModel)
            }
            .alert("error_title", isPresented: $showLogoutAllError) {
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

#Preview {
    SettingsView()
        .environment(AuthViewModel())
}
