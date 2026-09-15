/*
Derived from Apple's SwiftUI Landmarks sample (LandmarkDetail.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
A view showing the details for a study spot.
*/

import SwiftUI

struct SpotDetail: View {
    @Environment(ModelData.self) var modelData
    var spot: Spot

    var body: some View {
        ScrollView {
            MapView(coordinate: spot.locationCoordinate)
                .frame(height: 300)

            CategoryBadge(category: spot.category, size: 120)
                .offset(y: -60)
                .padding(.bottom, -60)

            VStack(alignment: .leading) {
                HStack {
                    Text(spot.name)
                        .font(.title)
                    FavoriteButton(isSet: Binding(
                        get: { modelData.isFavorite(spot) },
                        set: { _ in modelData.toggleFavorite(spot) }
                    ))
                }

                HStack {
                    Text(spot.building)
                    Spacer()
                    Text(spot.area)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                Text("About this spot")
                    .font(.title2)
                Text(spot.description)
            }
            .padding()
        }
        .navigationTitle(spot.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let modelData = ModelData()
    return SpotDetail(spot: modelData.spots[0])
        .environment(modelData)
}
