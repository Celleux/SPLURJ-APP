import SwiftUI

enum RiveMascotSize {
    case small, medium, large

    var dimension: CGFloat {
        switch self {
        case .small: 40
        case .medium: 64
        case .large: 100
        }
    }
}

struct RiveMascotView: View {
    let mood: SplurjiMood
    let size: RiveMascotSize

    var body: some View {
        SplurjiCharacter(mood: mood, size: size.dimension)
            .frame(width: size.dimension, height: size.dimension)
    }
}
