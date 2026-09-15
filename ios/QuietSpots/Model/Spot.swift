/*
Derived from Apple's SwiftUI Landmarks sample (Landmark.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
A study spot on the Georgia Tech campus, with its current noise level from the server.
*/

import Foundation
import SwiftUI
import CoreLocation

struct Spot: Hashable, Codable, Identifiable {
    var id: Int
    var name: String
    var building: String
    var area: String
    var category: Category
    var description: String

    // Live stats computed by the server over the last 2 hours. Missing in the bundled offline data.
    var avgDb: Double?
    var lastReportAt: String?
    var recentReports: Int?
    var quietVotes: Int?
    var busyVotes: Int?
    var level: NoiseLevel?

    private var lat: Double
    private var lon: Double
    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    var location: CLLocation {
        CLLocation(latitude: lat, longitude: lon)
    }

    var noiseLevel: NoiseLevel { level ?? .unknown }

    enum Category: String, CaseIterable, Codable {
        case library = "Library"
        case lounge = "Lounge"
        case cafe = "Cafe"
        case outdoors = "Outdoors"

        var symbol: String {
            switch self {
            case .library: "books.vertical.fill"
            case .lounge: "sofa.fill"
            case .cafe: "cup.and.saucer.fill"
            case .outdoors: "leaf.fill"
            }
        }
    }
}

enum NoiseLevel: String, Codable {
    case quiet, moderate, loud, unknown

    /// Matches the server's thresholds in backend/src/index.ts.
    init(db: Double) {
        switch db {
        case ..<45: self = .quiet
        case ..<60: self = .moderate
        default: self = .loud
        }
    }

    var color: Color {
        switch self {
        case .quiet: .green
        case .moderate: .orange
        case .loud: .red
        case .unknown: .gray
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case .quiet: "Quiet"
        case .moderate: "Moderate"
        case .loud: "Loud"
        case .unknown: "No recent reports"
        }
    }
}
