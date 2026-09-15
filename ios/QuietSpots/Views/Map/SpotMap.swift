/*
Abstract:
A campus map with every study spot colored by its current noise level.
*/

import SwiftUI
import MapKit

struct SpotMap: View {
    @Environment(ModelData.self) var modelData
    @State private var selected: Spot?
    @State private var position = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.7762, longitude: -84.3963),
        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)))

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                UserAnnotation()
                ForEach(modelData.spots) { spot in
                    Annotation(spot.name, coordinate: spot.locationCoordinate, anchor: .bottom) {
                        Button {
                            selected = spot
                        } label: {
                            SpotPin(spot: spot)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .safeAreaInset(edge: .bottom) {
                legend
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selected) { spot in
                SpotDetail(spot: spot)
            }
            .onAppear { Analytics.log("screen_view", ["screen": "map"]) }
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            ForEach([NoiseLevel.quiet, .moderate, .loud, .unknown], id: \.self) { level in
                HStack(spacing: 4) {
                    Circle().fill(level.color).frame(width: 10, height: 10)
                    Text(level.label).font(.caption)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .padding(.bottom, 8)
    }
}

struct SpotPin: View {
    var spot: Spot

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let db = spot.avgDb {
                    Text("\(Int(db.rounded()))").font(.caption.bold().monospacedDigit())
                } else {
                    Image(systemName: spot.category.symbol).font(.caption)
                }
            }
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(spot.noiseLevel.color, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
            Image(systemName: "triangle.fill")
                .font(.system(size: 9))
                .foregroundStyle(spot.noiseLevel.color)
                .rotationEffect(.degrees(180))
                .offset(y: -3)
        }
        .shadow(radius: 2)
        .accessibilityLabel("\(spot.name), \(spot.avgDb.map { "\(Int($0)) dB" } ?? "no recent reports")")
    }
}

#Preview {
    SpotMap()
        .environment(ModelData())
        .environment(AuthStore())
}
