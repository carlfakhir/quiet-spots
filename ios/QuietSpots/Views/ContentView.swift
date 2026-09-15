/*
Derived from Apple's SwiftUI Landmarks sample (ContentView.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
The root view: tabs for the spot list, the campus map, and the user's account.
*/

import SwiftUI

struct ContentView: View {
    @Environment(ModelData.self) var modelData

    var body: some View {
        TabView {
            Tab("Spots", systemImage: "list.bullet") {
                SpotList()
            }
            Tab("Map", systemImage: "map") {
                SpotMap()
            }
            Tab("Account", systemImage: "person.crop.circle") {
                AccountView()
            }
        }
        .task {
            Analytics.log("app_open")
            await modelData.refresh()
        }
    }
}

#Preview {
    ContentView()
        .environment(ModelData())
        .environment(AuthStore())
}
