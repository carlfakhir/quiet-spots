/*
Derived from Apple's SwiftUI Landmarks sample (ModelData.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
Storage for model data. Starts with bundled spots, then refreshes from the API.
*/

import Foundation

@Observable
class ModelData {
    var spots: [Spot] = load("spotData.json")
    var isLoading = false
    var loadError: String?
    var lastUpdated: Date?

    /// Favorites live on the device, not in the spot data, so they survive reloading spots.
    var favoriteIDs: Set<Int> = Set(UserDefaults.standard.array(forKey: "favoriteSpotIDs") as? [Int] ?? []) {
        didSet { UserDefaults.standard.set(Array(favoriteIDs), forKey: "favoriteSpotIDs") }
    }

    func isFavorite(_ spot: Spot) -> Bool {
        favoriteIDs.contains(spot.id)
    }

    func toggleFavorite(_ spot: Spot) {
        if favoriteIDs.contains(spot.id) {
            favoriteIDs.remove(spot.id)
        } else {
            favoriteIDs.insert(spot.id)
        }
    }

    @MainActor
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            spots = try await APIClient.shared.get("spots")
            loadError = nil
            lastUpdated = .now
        } catch {
            loadError = error.localizedDescription
        }
    }
}

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
