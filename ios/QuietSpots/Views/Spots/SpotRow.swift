/*
Derived from Apple's SwiftUI Landmarks sample (LandmarkRow.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
A single row to be displayed in a list of study spots.
*/

import SwiftUI

struct SpotRow: View {
    @Environment(ModelData.self) var modelData
    var spot: Spot

    var body: some View {
        HStack {
            CategoryBadge(category: spot.category, size: 44)
            VStack(alignment: .leading) {
                Text(spot.name)
                Text(spot.building)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if modelData.isFavorite(spot) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
    }
}

#Preview {
    let modelData = ModelData()
    return SpotRow(spot: modelData.spots[0])
        .environment(modelData)
}
