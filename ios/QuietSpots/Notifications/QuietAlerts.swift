/*
Abstract:
Local notifications when a favorite spot becomes quiet.

These are *local* notifications: the app itself notices the change (while open, or during a background
app refresh) and asks iOS to show an alert. A server-sent push (APNs, or Firebase Cloud Messaging on top
of it) would reach the phone even when iOS doesn't give the app background time, but it needs a paid
Apple Developer Program membership for the push certificate plus a server that tracks device tokens.
*/

import Foundation
import UserNotifications
import BackgroundTasks

enum QuietAlerts {
    static let refreshTaskID = "edu.gatech.cfakhir3.QuietSpots.refresh"
    private static let enabledKey = "quietAlertsEnabled"
    private static let lastLevelsKey = "lastKnownLevels"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// Asks for permission. Returns whether alerts can be shown.
    static func enable() async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
        isEnabled = granted
        if granted { scheduleBackgroundRefresh() }
        return granted
    }

    static func disable() {
        isEnabled = false
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshTaskID)
    }

    /// Compares fresh spot data with the last levels we saw and notifies for favorites that turned quiet.
    static func check(spots: [Spot], favoriteIDs: Set<Int>) async {
        let previous = UserDefaults.standard.dictionary(forKey: lastLevelsKey) as? [String: String] ?? [:]
        var current: [String: String] = [:]
        for spot in spots { current["\(spot.id)"] = spot.noiseLevel.rawValue }
        UserDefaults.standard.set(current, forKey: lastLevelsKey)

        guard isEnabled, !previous.isEmpty else { return }
        for spot in spots where favoriteIDs.contains(spot.id) {
            let before = previous["\(spot.id)"]
            if spot.noiseLevel == .quiet, before != nil, before != NoiseLevel.quiet.rawValue {
                await notify(spot)
            }
        }
    }

    static func notify(_ spot: Spot, isTest: Bool = false) async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "\(spot.name) is quiet now")
        if isTest {
            content.body = String(localized: "This is a test alert. Real alerts come when a starred spot turns quiet.")
        } else if let db = spot.avgDb {
            content.body = String(localized: "Around \(Int(db.rounded())) dB based on recent reports. Good time to head over.")
        }
        content.sound = .default
        let request = UNNotificationRequest(identifier: "quiet-\(spot.id)", content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
        Analytics.log("quiet_alert_sent", ["spot_id": "\(spot.id)", "test": "\(isTest)"])
    }

    /// Sends a sample alert so the feature can be demoed without waiting for real data to change.
    static func sendTest(spot: Spot) async {
        await notify(spot, isTest: true)
    }

    static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
