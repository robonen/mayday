import SwiftUI

struct RegisterView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showVerify = false
    @State private var registeredEmail = ""

    private var isFormInvalid: Bool {
        !isFormValid || authViewModel.isLoading
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 24)

                    VStack(spacing: 10) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 76, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: .brand.opacity(0.22), radius: 12, y: 6)

                        Text("register_title")
                            .font(.largeTitle.bold())
                    }

                    VStack(spacing: 14) {
                        AppTextField(title: "Email", icon: "envelope.fill", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        AppSecureField(title: "password", icon: "lock.fill", text: $password)
                            .textContentType(.newPassword)

                        AppSecureField(title: "confirm_password", icon: "lock.rotation", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }

                    if password.count > 0 && password.count < 8 {
                        Text("password_min_length")
                            .foregroundStyle(.brand)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if confirmPassword.count > 0 && password != confirmPassword {
                        Text("passwords_mismatch")
                            .foregroundStyle(.brand)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let error = authViewModel.error {
                        Text(error)
                            .foregroundStyle(.brand)
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task {
                            let success = await authViewModel.register(email: email, password: password)
                            if success {
                                registeredEmail = email
                                showVerify = true
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.brand, Color.brand.opacity(0.82)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 52)

                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("register_button")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .disabled(isFormInvalid)
                    .opacity(isFormInvalid ? 0.6 : 1)

                    Button("register_has_account") { dismiss() }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 8)
                }
                .cardContainer()
            }
            .navigationDestination(isPresented: $showVerify) {
                VerifyEmailView(email: registeredEmail, password: password)
            }
        }
        .appBackground()
        .navigationTitle("register_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    var isFormValid: Bool {
        !email.isEmpty && password.count >= 8 && password == confirmPassword
    }
}

#Preview {
    NavigationStack {
        RegisterView()
    }
    .environment(AuthViewModel())
}
