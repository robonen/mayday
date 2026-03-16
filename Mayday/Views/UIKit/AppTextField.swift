import SwiftUI

struct AppTextField: View {
    let title: LocalizedStringKey
    let icon: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            TextField(title, text: $text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    AppTextField(title: "Email", icon: "envelope.fill", text: .constant("user@example.com"))
        .padding()
}
