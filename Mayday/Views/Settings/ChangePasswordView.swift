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
                    SecureField("current_password", text: $currentPassword)
                        .textContentType(.password)
                    SecureField("new_password", text: $newPassword)
                        .textContentType(.newPassword)
                    SecureField("confirm_new_password", text: $confirmPassword)
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
                    Button("save_button") {
                        Task {
                            let success = await viewModel.changePassword(current: currentPassword, new: newPassword)
                            if success { dismiss() }
                        }
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("change_password_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("cancel") { dismiss() }
                }
            }
        }
    }

    var isFormValid: Bool {
        !currentPassword.isEmpty && newPassword.count >= 8 && newPassword == confirmPassword
    }
}
