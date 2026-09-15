/*
Derived from Apple's SwiftUI Landmarks sample (CircleImage.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
A circular badge with a symbol for the kind of study spot, styled like the sample's circle image.
*/

import SwiftUI

struct CategoryBadge: View {
    var category: Spot.Category
    var size: CGFloat
    var tint: Color = .accentColor

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.42))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tint.gradient, in: Circle())
            .overlay {
                Circle().stroke(.white, lineWidth: size > 60 ? 4 : 2)
            }
            .shadow(radius: size > 60 ? 7 : 2)
            .accessibilityLabel(category.rawValue)
    }
}

#Preview {
    CategoryBadge(category: .library, size: 120)
}
