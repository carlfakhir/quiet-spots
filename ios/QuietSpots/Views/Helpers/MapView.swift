/*
Derived from Apple's SwiftUI Landmarks sample (MapView.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
A view that presents a map of a study spot.
*/

import SwiftUI
import MapKit

struct MapView: View {
    var coordinate: CLLocationCoordinate2D

    var body: some View {
        Map(position: .constant(.region(region)))
    }

    private var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
        )
    }
}

#Preview {
    MapView(coordinate: CLLocationCoordinate2D(latitude: 33.774_35, longitude: -84.395_61))
}
