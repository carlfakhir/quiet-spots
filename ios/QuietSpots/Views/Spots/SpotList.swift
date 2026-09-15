/*
Derived from Apple's SwiftUI Landmarks sample (LandmarkList.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
A view showing a list of study spots.
*/

import SwiftUI

struct SpotList: View {
    @Environment(ModelData.self) var modelData
    @State private var showFavoritesOnly = false

    var filteredSpots: [Spot] {
        modelData.spots.filter { spot in
            (!showFavoritesOnly || modelData.isFavorite(spot))
        }
    }

    var body: some View {
        NavigationSplitView {
            List {
                Toggle(isOn: $showFavoritesOnly) {
                    Text("Favorites only")
                }

                ForEach(filteredSpots) { spot in
                    NavigationLink {
                        SpotDetail(spot: spot)
                    } label: {
                        SpotRow(spot: spot)
                    }
                }
            }
            .animation(.default, value: filteredSpots)
            .navigationTitle("Quiet Spots")
        } detail: {
            Text("Select a study spot")
        }
    }
}

#Preview {
    SpotList()
        .environment(ModelData())
}
