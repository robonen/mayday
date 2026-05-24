import Foundation

/// Wire-format identifiers for the `platform` field on the notification
/// service's `/devices` endpoint. Kept in sync with the backend's
/// `model.DevicePlatform` constants.
enum DevicePlatform {
    static let ios = "ios"
    static let iosLiveActivityStart = "ios-liveactivity"

    /// Builds a per-activity update token platform tag. The suffix is the
    /// `alertId` the Activity was started for, used by the backend to target
    /// update/end pushes at a specific running Live Activity.
    static func iosLiveActivityUpdate(alertId: String) -> String {
        "ios-liveactivity-\(alertId)"
    }
}

enum DeviceTokenFormatter {
    /// APNs returns the device token as raw bytes; the HTTP/2 endpoint expects
    /// a lowercase hex string. Used uniformly for APNs, Push-to-Start and
    /// per-activity update tokens.
    static func hex(_ data: Data) -> String {
        data.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
