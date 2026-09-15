/*
Derived from Apple's SwiftUI Landmarks sample (Landmark.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
A study spot on the Georgia Tech campus.
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

    private var lat: Double
    private var lon: Double
    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

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
