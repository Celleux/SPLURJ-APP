import SwiftUI
import CoreMotion

struct Parallax3DCard<Content: View>: View {
    let content: Content
    var maxRotation: Double = 15
    var enableHolographic: Bool = false
    var glowColor: Color?
    var interactive: Bool = true

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        maxRotation: Double = 15,
        enableHolographic: Bool = false,
        glowColor: Color? = nil,
        interactive: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.maxRotation = maxRotation
        self.enableHolographic = enableHolographic
        self.glowColor = glowColor
        self.interactive = interactive
    }

    private var xRotation: Double {
        guard !reduceMotion else { return 0 }
        return -Double(dragOffset.height) / 20.0 * (maxRotation / 15.0)
    }

    private var yRotation: Double {
        guard !reduceMotion else { return 0 }
        return Double(dragOffset.width) / 20.0 * (maxRotation / 15.0)
    }

    private var clampedXRotation: Double {
        min(max(xRotation, -maxRotation), maxRotation)
    }

    private var clampedYRotation: Double {
        min(max(yRotation, -maxRotation), maxRotation)
    }

    var body: some View {
        ZStack {
            if let glow = glowColor, !reduceMotion {
                RoundedRectangle(cornerRadius: 16)
                    .fill(glow.opacity(0.15))
                    .blur(radius: 20)
                    .offset(
                        x: dragOffset.width * 0.02,
                        y: dragOffset.height * 0.02
                    )
            }

            content
                .offset(
                    x: reduceMotion ? 0 : dragOffset.width * 0.05,
                    y: reduceMotion ? 0 : dragOffset.height * 0.05
                )

            if enableHolographic && !reduceMotion {
                holographicOverlay
                    .offset(
                        x: dragOffset.width * 0.1,
                        y: dragOffset.height * 0.1
                    )
                    .allowsHitTesting(false)
            }
        }
        .rotation3DEffect(
            .degrees(clampedXRotation),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
        .rotation3DEffect(
            .degrees(clampedYRotation),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .applyIf(interactive && !reduceMotion) { view in
            view.gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        isDragging = true
                        withAnimation(.interactiveSpring()) {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            dragOffset = .zero
                        }
                    }
            )
        }
    }

    private var holographicOverlay: some View {
        GeometryReader { geo in
            let angle = Angle.degrees(
                atan2(Double(dragOffset.height), Double(dragOffset.width)) * 180 / .pi
            )
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    AngularGradient(
                        colors: [
                            Theme.neonEmerald.opacity(0.12),
                            Theme.neonGold.opacity(0.12),
                            Theme.neonPurple.opacity(0.12),
                            Theme.neonBlue.opacity(0.12),
                            Theme.neonEmerald.opacity(0.12)
                        ],
                        center: .center,
                        startAngle: angle,
                        endAngle: angle + .degrees(360)
                    )
                )
                .blendMode(.overlay)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct GyroscopeParallaxModifier: ViewModifier {
    @State private var pitch: Double = 0
    @State private var roll: Double = 0
    let intensity: Double
    let motionManager = CMMotionManager()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(reduceMotion ? 0 : pitch * intensity),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .rotation3DEffect(
                .degrees(reduceMotion ? 0 : roll * intensity),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .onAppear { startMotionUpdates() }
            .onDisappear { motionManager.stopDeviceMotionUpdates() }
    }

    private func startMotionUpdates() {
        guard !reduceMotion, motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let attitude = motion?.attitude else { return }
            pitch = attitude.pitch * 180 / .pi
            roll = attitude.roll * 180 / .pi
        }
    }
}

extension View {
    func gyroscopeParallax(intensity: Double = 0.5) -> some View {
        modifier(GyroscopeParallaxModifier(intensity: intensity))
    }

    @ViewBuilder
    func applyIf<Modified: View>(_ condition: Bool, transform: (Self) -> Modified) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
