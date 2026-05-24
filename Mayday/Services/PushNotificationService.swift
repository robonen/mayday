import Foundation
import UserNotifications
import UIKit

@MainActor
final class PushNotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationService()

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func handleDeviceToken(_ tokenData: Data) {
        let token = DeviceTokenFormatter.hex(tokenData)
        Task {
            try? await HTTPClient.shared.request(.registerDevice(token: token, platform: DevicePlatform.ios)) as DeviceToken
        }
    }

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        guard let aps = userInfo["aps"] as? [String: Any] else { return }

        if let badge = aps["badge"] as? Int {
            try? await UNUserNotificationCenter.current().setBadgeCount(badge)
        }

        // Live Activity start/update/end pushes (apns-push-type: liveactivity)
        // are handled entirely by the OS via Push-to-Start tokens and per-activity
        // pushTokens — they never land in this delegate. Only regular alert/badge/sound
        // pushes reach here, and the only thing we owe them is the badge update above.
    }

    // MARK: - UNUserNotificationCenterDelegate
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

