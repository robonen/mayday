import SwiftUI

struct ChangePasswordView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Текущий пароль", text: $currentPassword)
                        .textContentType(.password)
                    SecureField("Новый пароль", text: $newPassword)
                        .textContentType(.newPassword)
                    SecureField("Подтвердите новый пароль", text: $confirmPassword)
                        .textContentType(.newPassword)
                }

                if let error = viewModel.error {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }

                if let success = viewModel.successMessage {
                    Section {
                        Text(success).foregroundStyle(.green)
                    }
                }

                Section {
                    Button("Сохранить") {
                        Task {
                            let success = await viewModel.changePassword(current: currentPassword, new: newPassword)
                            if success { dismiss() }
                        }
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Сменить пароль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }

    var isFormValid: Bool {
        !currentPassword.isEmpty && newPassword.count >= 8 && newPassword == confirmPassword
    }
}
