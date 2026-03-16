import SwiftUI

struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            LinearGradient(
                colors: [Color(.systemGroupedBackground), Color.brand.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}
