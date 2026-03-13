import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showVerify = false
    @State private var registeredEmail = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Регистрация")
                .font(.largeTitle.bold())

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                SecureField("Пароль", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)

                SecureField("Подтвердите пароль", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
            }

            if password.count > 0 && password.count < 8 {
                Text("Пароль должен содержать не менее 8 символов")
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            if confirmPassword.count > 0 && password != confirmPassword {
                Text("Пароли не совпадают")
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            if let error = authViewModel.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
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
                if authViewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Создать аккаунт").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid || authViewModel.isLoading)

            Button("Уже есть аккаунт?") { dismiss() }
                .font(.footnote)

            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $showVerify) {
            VerifyEmailView(email: registeredEmail)
        }
        .navigationTitle("Регистрация")
        .navigationBarTitleDisplayMode(.inline)
    }

    var isFormValid: Bool {
        !email.isEmpty && password.count >= 8 && password == confirmPassword
    }
}
