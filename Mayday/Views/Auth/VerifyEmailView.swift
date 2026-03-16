import SwiftUI

struct VerifyEmailView: View {
    let email: String
    let password: String

    @Environment(AuthViewModel.self) private var authViewModel
    @State private var codeDigits: [String] = Array(repeating: "", count: 6)
    @State private var resendCooldown = 0
    @State private var focusedIndex: Int?
    @State private var cooldownTask: Task<Void, Never>?

    private var code: String {
        codeDigits.joined()
    }

    var body: some View {
        ScrollView {
            contentCard
        }
        .appBackground()
        .navigationTitle("verify_nav_title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focusedIndex = 0 }
        .onDisappear { cooldownTask?.cancel() }
        .onChange(of: code) { _, newValue in
            if newValue.count == 6 {
                Task { await submitCode(newValue) }
            }
        }
    }


    private var contentCard: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 24)

            headerView
            otpFieldsView

            if let error = authViewModel.error {
                Text(error)
                    .foregroundStyle(.brand)
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if code.count == 6 {
                ProgressView()
                    .padding(.top, 2)
            }

            resendButton

            Spacer(minLength: 8)
        }
        .cardContainer()
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .brand.opacity(0.22), radius: 12, y: 6)

            Text("verify_email_title")
                .font(.largeTitle.bold())

            Text("verify_code_sent_to")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(email)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var otpFieldsView: some View {
        HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { index in
                otpField(at: index)
            }
        }
    }

    private var resendButton: some View {
        Button {
            Task { await resendCode() }
        } label: {
            Group {
                if resendCooldown > 0 {
                    Text("verify_resend_cooldown \(resendCooldown)")
                } else {
                    Text("verify_resend")
                }
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(resendCooldown > 0 ? Color.secondary : Color.brand)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemFill))
            .clipShape(Capsule())
        }
        .disabled(resendCooldown > 0)
    }

    @ViewBuilder
    private func otpField(at index: Int) -> some View {
        OTPDigitField(
            text: $codeDigits[index],
            isFocused: focusedIndex == index,
            onFocus: { focusedIndex = index },
            onInsert: {
                if index < 5 {
                    focusedIndex = index + 1
                }
            },
            onDeleteWhenEmpty: {
                handleDeleteOnEmpty(at: index)
            },
            onPaste: { digits in
                handlePaste(digits, startingAt: index)
            }
        )
            .frame(width: 46, height: 56)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        focusedIndex == index
                            ? Color.brand.opacity(0.9)
                            : Color.primary.opacity(0.10),
                        lineWidth: focusedIndex == index ? 2 : 1
                    )
            )
    }

    private func handleDeleteOnEmpty(at index: Int) {
        guard index > 0 else { return }
        codeDigits[index - 1] = ""
        focusedIndex = index - 1
    }

    private func handlePaste(_ digits: [String], startingAt startIndex: Int) {
        guard !digits.isEmpty else { return }
        for (offset, digit) in digits.enumerated() {
            let target = startIndex + offset
            guard target < codeDigits.count else { break }
            codeDigits[target] = String(digit.prefix(1))
        }
        focusedIndex = min(startIndex + digits.count, codeDigits.count - 1)
    }

    private func submitCode(_ code: String) async {
        await authViewModel.verifyEmail(email: email, code: code)
        if authViewModel.error == nil {
            await authViewModel.login(email: email, password: password)
        }
    }

    private func resendCode() async {
        do {
            try await AuthService.shared.resendCode(email: email)
            startCooldown()
        } catch {
            authViewModel.error = error.localizedDescription
        }
    }

    private func startCooldown() {
        cooldownTask?.cancel()
        cooldownTask = Task {
            for remaining in stride(from: 60, through: 1, by: -1) {
                guard !Task.isCancelled else { return }
                resendCooldown = remaining
                try? await Task.sleep(for: .seconds(1))
            }
            guard !Task.isCancelled else { return }
            resendCooldown = 0
        }
    }
}

#Preview {
    NavigationStack {
        VerifyEmailView(email: "user@example.com", password: "password123")
    }
    .environment(AuthViewModel())
}
