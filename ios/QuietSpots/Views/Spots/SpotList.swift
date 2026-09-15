/*
Derived from Apple's SwiftUI Landmarks sample (LandmarkList.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
A view showing a list of study spots, quietest first.
*/

import SwiftUI

struct SpotList: View {
    @Environment(ModelData.self) var modelData
    @State private var showFavoritesOnly = false

    var filteredSpots: [Spot] {
        modelData.spots
            .filter { spot in
                (!showFavoritesOnly || modelData.isFavorite(spot))
            }
            .sorted { ($0.avgDb ?? .infinity) < ($1.avgDb ?? .infinity) }
    }

    var body: some View {
        NavigationSplitView {
            List {
                if let error = modelData.loadError {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Can't reach the server")
                            Text(error).font(.caption).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "wifi.exclamationmark").foregroundStyle(.orange)
                    }
                }

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
            .refreshable { await modelData.refresh() }
            .overlay {
                if showFavoritesOnly && filteredSpots.isEmpty {
                    ContentUnavailableView(
                        "No favorites yet",
                        systemImage: "star",
                        description: Text("Open a spot and tap the star to add it here."))
                }
            }
        } detail: {
            Text("Select a study spot")
        }
    }
}

#Preview {
    SpotList()
        .environment(ModelData())
        .environment(AuthStore())
}
