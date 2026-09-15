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
            CategoryBadge(category: spot.category, size: 44, tint: spot.noiseLevel.color)
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    Text(spot.name)
                    if modelData.isFavorite(spot) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                Text(spot.building)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                if let db = spot.avgDb {
                    Text("\(Int(db.rounded())) dB")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(spot.noiseLevel.color)
                } else {
                    Text("–").foregroundStyle(.secondary)
                }
                Text(spot.noiseLevel.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let lastReportAt = spot.lastReportAt {
                    Text(RelativeTime.string(from: lastReportAt))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let modelData = ModelData()
    return SpotRow(spot: modelData.spots[0])
        .environment(modelData)
}
