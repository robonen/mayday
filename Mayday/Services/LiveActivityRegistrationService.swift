import Foundation
import ActivityKit

/// Observes Push-to-Start tokens for `AlertAttributes` activities and registers
/// them with the backend so the server can start, update and end Live Activities
/// via APNs. Also cleans up tokens on the server when activities end and when
/// the user logs out.
@MainActor
final class LiveActivityRegistrationService {
    static let shared = LiveActivityRegistrationService()

    private var startTokenObserver: Task<Void, Never>?
    private var activityObserver: Task<Void, Never>?
    private var perActivityObservers: [String: Task<Void, Never>] = [:]
    private var perActivityTokens: [String: String] = [:]
    private var lastRegisteredStartToken: String?

    private init() {}

    /// Start observing tokens. Safe to call multiple times.
    func start() {
        guard startTokenObserver == nil else { return }

        if #available(iOS 17.2, *) {
            startTokenObserver = Task { [weak self] in
                for await tokenData in Activity<AlertAttributes>.pushToStartTokenUpdates {
                    let token = DeviceTokenFormatter.hex(tokenData)
                    await self?.registerStartToken(token)
                }
            }
        }

        activityObserver = Task { [weak self] in
            for await activity in Activity<AlertAttributes>.activityUpdates {
                self?.trackActivity(activity)
            }
        }

        // Pick up tokens for activities already running (e.g. after relaunch).
        for activity in Activity<AlertAttributes>.activities {
            trackActivity(activity)
        }
    }

    /// Cancel all observers and best-effort delete server-side push tokens so
    /// the next user on this device doesn't inherit Live Activity routing.
    /// Per-activity tokens are owned by the OS (they die when the activity
    /// ends), so only the push-to-start token needs an explicit DELETE.
    func stop() {
        startTokenObserver?.cancel()
        startTokenObserver = nil
        activityObserver?.cancel()
        activityObserver = nil
        perActivityObservers.values.forEach { $0.cancel() }
        perActivityObservers.removeAll()
        perActivityTokens.removeAll()

        if let token = lastRegisteredStartToken {
            lastRegisteredStartToken = nil
            Task { await Self.unregister(token: token) }
        }
    }

    private func trackActivity(_ activity: Activity<AlertAttributes>) {
        let alertId = activity.attributes.alertId
        guard perActivityObservers[alertId] == nil else { return }

        perActivityObservers[alertId] = Task { [weak self] in
            // Spawn a child task to drain pushTokenUpdates concurrently with
            // the activityStateUpdates loop below. When the activity reaches a
            // terminal state we cancel the token loop and clean up.
            let tokenTask = Task { [weak self] in
                for await tokenData in activity.pushTokenUpdates {
                    let token = DeviceTokenFormatter.hex(tokenData)
                    await self?.registerActivityToken(token, alertId: alertId)
                }
            }

            for await state in activity.activityStateUpdates {
                if state == .ended || state == .dismissed {
                    break
                }
            }

            tokenTask.cancel()
            await self?.cleanupEndedActivity(alertId: alertId)
        }
    }

    private func cleanupEndedActivity(alertId: String) async {
        let token = perActivityTokens.removeValue(forKey: alertId)
        perActivityObservers[alertId] = nil
        if let token {
            await Self.unregister(token: token)
        }
    }

    private func registerStartToken(_ token: String) async {
        guard token != lastRegisteredStartToken else { return }
        do {
            let _: DeviceToken = try await HTTPClient.shared.request(
                .registerDevice(token: token, platform: DevicePlatform.iosLiveActivityStart)
            )
            lastRegisteredStartToken = token
        } catch {
            // Transient — next token update will retry.
        }
    }

    private func registerActivityToken(_ token: String, alertId: String) async {
        do {
            let _: DeviceToken = try await HTTPClient.shared.request(
                .registerDevice(token: token, platform: DevicePlatform.iosLiveActivityUpdate(alertId: alertId))
            )
            perActivityTokens[alertId] = token
        } catch {
            // Transient — next token update will retry.
        }
    }

    /// Fire-and-forget DELETE so tokens are reclaimed on the server.
    /// 404s and network errors are silently ignored — the worst case is one
    /// stale row that will eventually be purged via APNs 410 dead-lettering.
    private static func unregister(token: String) async {
        let _: EmptyResponse? = try? await HTTPClient.shared.request(.unregisterDeviceByToken(token: token))
    }
}
