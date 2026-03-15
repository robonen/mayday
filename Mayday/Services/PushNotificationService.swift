import Foundation
import UserNotifications
import UIKit
import ActivityKit

@MainActor
class PushNotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationService()

    @Published var deviceToken: String?

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
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = token
        Task {
            try? await HTTPClient.shared.request(.registerDevice(token: token, platform: "ios")) as DeviceToken
        }
    }

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        guard let aps = userInfo["aps"] as? [String: Any] else { return }

        // Handle explicit Live Activity push (event inside aps)
        if let event = aps["event"] as? String {
            await handleLiveActivityPush(event: event, userInfo: userInfo, aps: aps)
            return
        }

        // Update badge
        if let badge = aps["badge"] as? Int {
            try? await UNUserNotificationCenter.current().setBadgeCount(badge)
        }

        // Start a Live Activity from a regular push if metadata contains severity
        if let metadata = userInfo["metadata"] as? [String: String],
           let severityStr = metadata["severity"],
           let severity = Severity(rawValue: severityStr),
           let source = userInfo["source"] as? String,
           let subject = userInfo["subject"] as? String {

            let alertId = (userInfo["notificationId"] as? String) ?? UUID().uuidString
            let contentState = AlertAttributes.ContentState(
                title: subject,
                value: metadata["value"],
                status: .active,
                startedAt: Date(),
                updatedAt: Date()
            )
            await startLiveActivity(
                userInfo: userInfo,
                contentState: contentState,
                topic: source,
                alertId: alertId,
                severity: severity
            )
        }
    }

    private func handleLiveActivityPush(event: String, userInfo: [AnyHashable: Any], aps: [String: Any]) async {
        guard let contentStateData = aps["content-state"] as? [String: Any],
              let contentStateJSON = try? JSONSerialization.data(withJSONObject: contentStateData),
              let contentState = try? JSONDecoder.iso8601.decode(AlertAttributes.ContentState.self, from: contentStateJSON)
        else { return }

        switch event {
        case "start":
            if let attributes = userInfo["attributes"] as? [String: Any],
               let topic = attributes["topic"] as? String,
               let alertId = attributes["alertId"] as? String,
               let severityStr = attributes["severity"] as? String,
               let severity = Severity(rawValue: severityStr) {
                await startLiveActivity(userInfo: userInfo, contentState: contentState, topic: topic, alertId: alertId, severity: severity)
            }
        case "update":
            await updateLiveActivity(alertId: userInfo["alertId"] as? String, contentState: contentState)
        case "end":
            await endLiveActivity(alertId: userInfo["alertId"] as? String, contentState: contentState)
        default:
            break
        }
    }

    private func startLiveActivity(userInfo: [AnyHashable: Any], contentState: AlertAttributes.ContentState, topic: String, alertId: String, severity: Severity) async {
        // Info-level alerts don't warrant a persistent Live Activity — they are low-priority
        // and should only appear as a standard banner notification.
        guard severity != .info else { return }

        // Limit to 3 concurrent activities
        let currentActivities = Activity<AlertAttributes>.activities
        if currentActivities.count >= 3 {
            // End the oldest
            if let oldest = currentActivities.min(by: {
                $0.content.state.startedAt < $1.content.state.startedAt
            }) {
                let finalState = oldest.content.state
                nonisolated(unsafe) let activity = oldest
                await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            }
        }

        let attrs = AlertAttributes(topic: topic, alertId: alertId, severity: severity)
        _ = try? Activity<AlertAttributes>.request(
            attributes: attrs,
            content: ActivityContent(state: contentState, staleDate: Date().addingTimeInterval(4 * 3600))
        )
    }

    private func updateLiveActivity(alertId: String?, contentState: AlertAttributes.ContentState) async {
        guard let alertId else { return }
        for activity in Activity<AlertAttributes>.activities where activity.attributes.alertId == alertId {
            await activity.update(ActivityContent(state: contentState, staleDate: Date().addingTimeInterval(4 * 3600)))
        }
    }

    private func endLiveActivity(alertId: String?, contentState: AlertAttributes.ContentState) async {
        guard let alertId else { return }
        for activity in Activity<AlertAttributes>.activities where activity.attributes.alertId == alertId {
            let dismissDate = Date().addingTimeInterval(5 * 60)
            await activity.end(
                ActivityContent(state: contentState, staleDate: dismissDate),
                dismissalPolicy: .after(dismissDate)
            )
        }
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

extension JSONDecoder {
    static let iso8601: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
