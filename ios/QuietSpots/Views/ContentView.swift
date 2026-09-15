/*
Derived from Apple's SwiftUI Landmarks sample (ContentView.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
The root view: tabs for the spot list and the user's account.
*/

import SwiftUI

struct ContentView: View {
    @Environment(ModelData.self) var modelData

    var body: some View {
        TabView {
            Tab("Spots", systemImage: "list.bullet") {
                SpotList()
            }
            Tab("Account", systemImage: "person.crop.circle") {
                AccountView()
            }
        }
        .task { await modelData.refresh() }
    }
}

#Preview {
    ContentView()
        .environment(ModelData())
        .environment(AuthStore())
}
