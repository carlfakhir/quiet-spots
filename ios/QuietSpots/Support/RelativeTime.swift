/*
Abstract:
Formats the server's UTC "YYYY-MM-DD HH:MM:SS" timestamps as "5 min. ago".
*/

import Foundation

enum RelativeTime {
    private static let parser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    static func date(from serverTimestamp: String) -> Date? {
        parser.date(from: serverTimestamp)
    }

    static func string(from serverTimestamp: String) -> String {
        guard let date = date(from: serverTimestamp) else { return serverTimestamp }
        if abs(date.timeIntervalSinceNow) < 60 { return String(localized: "just now") }
        return date.formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
    }
}
