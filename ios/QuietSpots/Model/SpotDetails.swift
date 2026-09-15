/*
Abstract:
The extra data returned by GET /spots/:id: current weather and recent reports.
*/

import Foundation

struct SpotDetails: Decodable {
    struct Weather: Decodable, Hashable {
        var tempC: Double
        var weatherDesc: String

        var symbol: String {
            switch weatherDesc {
            case "Clear": "sun.max.fill"
            case "Partly cloudy": "cloud.sun.fill"
            case "Fog": "cloud.fog.fill"
            case "Drizzle", "Rain", "Rain showers": "cloud.rain.fill"
            case "Snow", "Snow showers": "cloud.snow.fill"
            default: "cloud.bolt.rain.fill"
            }
        }
    }

    var avgDb: Double?
    var level: NoiseLevel
    var recentReports: Int
    var quietVotes: Int
    var busyVotes: Int
    var weather: Weather?
    var reports: [Report]
}

struct Report: Decodable, Identifiable, Hashable {
    var id: Int
    var db: Double
    var vote: Vote?
    var note: String?
    var distanceM: Double?
    var tempC: Double?
    var weatherDesc: String?
    var createdAt: String
    var username: String
    var mine: Bool
}

enum Vote: String, Codable, CaseIterable, Identifiable {
    case quiet, ok, busy
    var id: String { rawValue }

    var label: String {
        switch self {
        case .quiet: String(localized: "Quiet")
        case .ok: String(localized: "Okay")
        case .busy: String(localized: "Busy")
        }
    }

    var symbol: String {
        switch self {
        case .quiet: "moon.zzz.fill"
        case .ok: "hand.thumbsup.fill"
        case .busy: "person.3.fill"
        }
    }
}

struct NewReport: Encodable {
    var db: Double
    var vote: Vote?
    var note: String?
    var lat: Double?
    var lon: Double?
}
