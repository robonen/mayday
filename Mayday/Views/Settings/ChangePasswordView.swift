import SwiftUI

struct ChangePasswordView: View {
    var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    private var isFormInvalid: Bool {
        !isFormValid || viewModel.isLoading
    }

    private var isFormValid: Bool {
        !currentPassword.isEmpty && newPassword.count >= 8 && newPassword == confirmPassword
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        AppSecureField(
                            title: "current_password",
                            icon: "lock.fill",
                            text: $currentPassword
                        )
                        .textContentType(.password)

                        AppSecureField(
                            title: "new_password",
                            icon: "key.fill",
                            text: $newPassword
                        )
                        .textContentType(.newPassword)

                        AppSecureField(
                            title: "confirm_new_password",
                            icon: "lock.rotation",
                            text: $confirmPassword
                        )
                        .textContentType(.newPassword)
                    }
                    .padding(.vertical, 4)
                }

                if newPassword.count > 0 && newPassword.count < 8 {
                    Section {
                        Text("password_min_length")
                            .foregroundStyle(.brand)
                            .font(.footnote)
                    }
                }

                if confirmPassword.count > 0 && newPassword != confirmPassword {
                    Section {
                        Text("passwords_mismatch")
                            .foregroundStyle(.brand)
                            .font(.footnote)
                    }
                }

                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundStyle(.brand)
                            .font(.footnote)
                    }
                }

                if let success = viewModel.successMessage {
                    Section {
                        Text(success)
                            .foregroundStyle(.success)
                            .font(.footnote)
                    }
                }

                Section {
                    Button {
                        Task {
                            let success = await viewModel.changePassword(current: currentPassword, new: newPassword)
                            if success { dismiss() }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("save_button")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isFormInvalid)
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
}

#Preview {
    ChangePasswordView(viewModel: SettingsViewModel())
}
