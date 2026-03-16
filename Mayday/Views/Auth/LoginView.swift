import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    private var isFormInvalid: Bool {
        email.isEmpty || password.isEmpty || authViewModel.isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer(minLength: 24)

                        VStack(spacing: 10) {
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 84, height: 84)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(color: .brand.opacity(0.25), radius: 12, y: 6)

                            Text("Mayday")
                                .font(.largeTitle.bold())

                            Text("login_subtitle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)

                        VStack(spacing: 14) {
                            AppTextField(
                                title: "Email",
                                icon: "envelope.fill",
                                text: $email
                            )
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                            AppSecureField(
                                title: "password",
                                icon: "lock.fill",
                                text: $password
                            )
                            .textContentType(.password)
                        }

                        if let error = authViewModel.error {
                            Text(error)
                                .foregroundStyle(.brand)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await authViewModel.login(email: email, password: password) }
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
                                    Text("login_button")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .disabled(isFormInvalid)
                        .opacity(isFormInvalid ? 0.6 : 1)

                        Button("login_no_account") {
                            showRegister = true
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                        Spacer(minLength: 8)
                    }
                    .cardContainer()
                }
            }
            .appBackground()
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
