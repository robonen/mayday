import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        Group {
            if authViewModel.isCheckingAuth {
                Color(.systemBackground)
                    .ignoresSafeArea()
            } else if authViewModel.isAuthenticated {
                NotificationsView()
            } else {
                LoginView()
            }
        }
        .task {
            await authViewModel.checkAuthStatus()
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
