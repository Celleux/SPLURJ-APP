import SwiftUI

struct AmbientLightView<Content: View>: View {
    let content: Content
    var goldOpacity: Double = 0.06
    var tealOpacity: Double = 0.04

    init(
        goldOpacity: Double = 0.06,
        tealOpacity: Double = 0.04,
        @ViewBuilder content: () -> Content
    ) {
        self.goldOpacity = goldOpacity
        self.tealOpacity = tealOpacity
        self.content = content()
    }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Theme.accent.opacity(goldOpacity))
                .frame(width: 200, height: 100)
                .blur(radius: 60)
                .offset(x: -40, y: -20)

            Ellipse()
                .fill(Theme.accent.opacity(tealOpacity))
                .frame(width: 150, height: 80)
                .blur(radius: 50)
                .offset(x: 60, y: 30)

            content
        }
    }
}
