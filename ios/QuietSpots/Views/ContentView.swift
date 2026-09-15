/*
Derived from Apple's SwiftUI Landmarks sample (ContentView.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
The root view of the app.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        SpotList()
    }
}

#Preview {
    ContentView()
        .environment(ModelData())
}
