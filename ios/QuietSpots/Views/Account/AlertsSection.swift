/*
Abstract:
Settings for quiet-spot notifications.
*/

import SwiftUI

struct AlertsSection: View {
    @Environment(ModelData.self) var modelData
    @State private var enabled = QuietAlerts.isEnabled
    @State private var denied = false

    var body: some View {
        Section {
            Toggle("Alert me when a favorite gets quiet", isOn: $enabled)
                .onChange(of: enabled) { _, on in
                    Task {
                        if on {
                            let granted = await QuietAlerts.enable()
                            denied = !granted
                            if !granted { enabled = false }
                        } else {
                            QuietAlerts.disable()
                        }
                        Analytics.log("quiet_alerts_toggled", ["enabled": "\(enabled)"])
                    }
                }
            if enabled {
                Button("Send a test alert") {
                    let spot = modelData.spots.first { modelData.isFavorite($0) } ?? modelData.spots[0]
                    Task { await QuietAlerts.sendTest(spot: spot) }
                }
            }
        } header: {
            Text("Alerts")
        } footer: {
            if denied {
                Text("Notifications are turned off for Quiet Spots. Turn them on in Settings.")
            } else {
                Text("Checks your starred spots when the app refreshes, including in the background.")
            }
        }
    }
}
