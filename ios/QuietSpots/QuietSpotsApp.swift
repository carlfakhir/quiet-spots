/*
Derived from Apple's SwiftUI Landmarks sample (LandmarksApp.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
The top-level definition of the Quiet Spots app.
*/

import SwiftUI
import UserNotifications

@main
struct QuietSpotsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var modelData = ModelData()
    @State private var auth = AuthStore()

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(modelData)
                .environment(auth)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background, QuietAlerts.isEnabled {
                QuietAlerts.scheduleBackgroundRefresh()
            }
            if phase == .active {
                Task { await modelData.refresh() }
            }
        }
        .backgroundTask(.appRefresh(QuietAlerts.refreshTaskID)) {
            // iOS decides when this runs (roughly every 15+ minutes at best).
            QuietAlerts.scheduleBackgroundRefresh()
            await modelData.refresh()
        }
    }
}
