import SwiftUI

@main
struct MaydayApp: App {
    @State private var authViewModel = AuthViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
        }
    }
}
