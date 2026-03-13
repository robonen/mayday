import SwiftUI

struct VerifyEmailView: View {
    let email: String

    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var codeDigits: [String] = Array(repeating: "", count: 6)
    @State private var resendCooldown = 0
    @FocusState private var focusedIndex: Int?
    @State private var resendTimer: Timer?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Подтвердите email")
                    .font(.largeTitle.bold())
                Text("Код отправлен на")
                    .foregroundStyle(.secondary)
                Text(email)
                    .fontWeight(.semibold)
            }

            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    TextField("", text: $codeDigits[index])
                        .frame(width: 44, height: 52)
                        .multilineTextAlignment(.center)
                        .font(.title2.bold())
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedIndex == index ? Color.accentColor : Color.secondary, lineWidth: 2)
                        )
                        .focused($focusedIndex, equals: index)
                        .onChange(of: codeDigits[index]) { _, newValue in
                            handleDigitChange(index: index, value: newValue)
                        }
                }
            }

            if let error = authViewModel.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            Button {
                Task { await resendCode() }
            } label: {
                if resendCooldown > 0 {
                    Text("Отправить повторно (\(resendCooldown) сек)")
                } else {
                    Text("Отправить повторно")
                }
            }
            .disabled(resendCooldown > 0)

            Spacer()
        }
        .padding()
        .navigationTitle("Подтверждение")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focusedIndex = 0 }
    }

    private func handleDigitChange(index: Int, value: String) {
        let filtered = value.filter { $0.isNumber }
        if filtered.count > 1 {
            // Paste handling
            let digits = Array(filtered.prefix(6))
            for (i, d) in digits.enumerated() where i < 6 {
                codeDigits[i] = String(d)
            }
            focusedIndex = min(digits.count, 5)
        } else {
            codeDigits[index] = filtered.isEmpty ? "" : String(filtered.last!)
            if !filtered.isEmpty && index < 5 {
                focusedIndex = index + 1
            }
        }

        let code = codeDigits.joined()
        if code.count == 6 {
            Task { await submitCode(code) }
        }
    }

    private func submitCode(_ code: String) async {
        await authViewModel.verifyEmail(email: email, code: code)
        if authViewModel.error == nil {
            // Auto-login after verification - in a real flow we'd re-login here
            // since verify doesn't return tokens
        }
    }

    private func resendCode() async {
        do {
            try await AuthService.shared.resendCode(email: email)
            resendCooldown = 60
            startCooldownTimer()
        } catch {
            authViewModel.error = error.localizedDescription
        }
    }

    private func startCooldownTimer() {
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                resendTimer?.invalidate()
            }
        }
    }
}
