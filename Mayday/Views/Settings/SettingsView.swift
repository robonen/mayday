import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showChangePassword = false
    @State private var showSessions = false
    @State private var showLogoutAllConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Аккаунт") {
                    if let user = authViewModel.currentUser {
                        LabeledContent("Email", value: user.email)
                    }
                }

                Section {
                    Button("Сменить пароль") {
                        showChangePassword = true
                    }

                    Button {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Push-уведомления", systemImage: "bell.badge")
                            .foregroundStyle(.primary)
                    }
                }

                Section {
                    Button {
                        showSessions = true
                    } label: {
                        HStack {
                            Text("Активные сессии")
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
                    Button("Выйти из аккаунта", role: .destructive) {
                        Task { await authViewModel.logout() }
                    }

                    Button("Выйти на всех устройствах", role: .destructive) {
                        showLogoutAllConfirm = true
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
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
                "Выйти на всех устройствах?",
                isPresented: $showLogoutAllConfirm,
                titleVisibility: .visible
            ) {
                Button("Выйти везде", role: .destructive) {
                    Task {
                        _ = try? await NotificationsAPIService.shared.logoutAll()
                        await authViewModel.logout()
                    }
                }
                Button("Отмена", role: .cancel) {}
            }
            .task {
                await viewModel.loadSessions()
            }
        }
    }
}
