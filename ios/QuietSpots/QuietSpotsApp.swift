/*
Derived from Apple's SwiftUI Landmarks sample (LandmarksApp.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
The top-level definition of the Quiet Spots app.
*/

import SwiftUI

@main
struct QuietSpotsApp: App {
    @State private var modelData = ModelData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(modelData)
        }
    }
}
