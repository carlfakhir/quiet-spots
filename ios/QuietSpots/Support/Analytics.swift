/*
Abstract:
Fire-and-forget usage events sent to POST /events (viewable at GET /stats).
*/

import Foundation
import UIKit

enum Analytics {
    private struct Event: Encodable {
        var name: String
        var props: [String: String]
        var platform: String
    }

    static func log(_ name: String, _ props: [String: String] = [:]) {
        var props = props
        props["os"] = UIDevice.current.systemVersion
        props["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let event = Event(name: name, props: props, platform: "ios")
        Task.detached(priority: .background) {
            try? await APIClient.shared.post("events", body: event)
        }
    }
}
