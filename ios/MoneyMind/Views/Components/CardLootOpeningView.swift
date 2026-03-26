import SwiftUI

struct CardLootOpeningView: View {
    let card: CardDefinition
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Int = 0
    @State private var beamScale: CGFloat = 0
    @State private var beamOpacity: Double = 0
    @State private var pulseCount: Int = 0
    @State private var cardScale: CGFloat = 0.3
    @State private var cardOpacity: Double = 0
    @State private var cardRotationY: Double = 0
    @State private var starsRevealed: Int = 0
    @State private var nameOpacity: Double = 0
    @State private var tipOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var bgColorShift: Bool = false
    @State private var showParticles: Bool = false

    private var isLegendary: Bool { card.rarity == .legendary }
    private var beamColor: Color { isLegendary ? Theme.neonGold : Theme.neonPurple }
    private var starCount: Int {
        switch card.rarity {
        case .legendary: return 5
        case .epic: return 4
        default: return 3
        }
    }

    var body: some View {
        ZStack {
            backgroundLayer

            if phase >= 1 && phase < 4 {
                beamLayer
            }

            if phase >= 3 {
                cardLayer
            }

            if phase >= 5 {
                infoLayer
            }

            if showParticles {
                ParticleBurstView(
                    particleCount: 40,
                    colors: isLegendary
                        ? [Theme.neonGold, Theme.gold, .white, Color(hex: 0xFFEE58)]
                        : [Theme.neonPurple, Theme.lavender, .white, Color(hex: 0x8B5CF6)],
                    duration: 2.5,
                    style: isLegendary ? .coins : .stars,
                    trigger: showParticles
                )
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
        .onTapGesture {
            if phase >= 5 {
                onDismiss()
            } else if phase >= 1 {
                skipToEnd()
            }
        }
        .onAppear {
            if reduceMotion {
                skipToEnd()
            } else {
                startSequence()
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if bgColorShift {
                RadialGradient(
                    colors: [
                        beamColor.opacity(0.15),
                        beamColor.opacity(0.05),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 400
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
    }

    private var beamLayer: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let centerY = geo.size.height / 2

            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [beamColor.opacity(0), beamColor.opacity(0.8), beamColor.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: beamScale * 60 + 4, height: geo.size.height)
                    .position(x: centerX, y: centerY)
                    .opacity(beamOpacity)
                    .blur(radius: 8)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.6), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: geo.size.height)
                    .position(x: centerX, y: centerY)
                    .opacity(beamOpacity)
            }
        }
    }

    private var cardLayer: some View {
        CardArtView(card: card)
            .frame(width: 240, height: 340)
            .rotation3DEffect(.degrees(cardRotationY), axis: (x: 0, y: 1, z: 0))
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .neonGlow(color: beamColor, radius: 24)
            .depthPop(intensity: isLegendary ? 2.0 : 1.5)
            .holographicSheen(isActive: phase >= 4)
    }

    private var infoLayer: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack(spacing: 4) {
                ForEach(0..<starCount, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(Typography.labelLarge)
                        .foregroundStyle(card.rarity.color)
                        .opacity(i < starsRevealed ? 1 : 0)
                        .scaleEffect(i < starsRevealed ? 1.0 : 0.3)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5).delay(Double(i) * 0.15), value: starsRevealed)
                }
            }
            .padding(.top, 16)

            Text(card.name)
                .font(Typography.displaySmall)
                .foregroundStyle(card.rarity.color)
                .opacity(nameOpacity)
                .padding(.top, 12)

            Text(card.tip)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(tipOpacity)
                .padding(.top, 8)

            Text(card.set.rawValue)
                .font(Typography.labelSmall)
                .foregroundStyle(card.set.accentColor.opacity(0.6))
                .opacity(tipOpacity)
                .padding(.top, 4)

            Button {
                onDismiss()
            } label: {
                Text("Add to Collection")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(card.rarity.color, in: .rect(cornerRadius: 14))
                    .shadow(color: card.rarity.color.opacity(0.3), radius: 12, y: 4)
            }
            .padding(.horizontal, 40)
            .padding(.top, 24)
            .opacity(buttonOpacity)

            Spacer().frame(height: 60)
        }
    }

    private func startSequence() {
        Task {
            // Phase 1: Beam shoots up
            phase = 1
            if isLegendary { SplurjHaptics.bossDamage() }
            else { SplurjHaptics.epicReveal() }

            withAnimation(.easeOut(duration: 0.3)) {
                beamScale = 0.5
                beamOpacity = 1.0
            }

            try? await Task.sleep(for: .milliseconds(300))

            // Phase 2: Beam pulses 3 times
            phase = 2
            for i in 0..<3 {
                let pulseScale: CGFloat = CGFloat(i + 1) * 0.4 + 0.5
                withAnimation(.easeInOut(duration: 0.2)) {
                    beamScale = pulseScale
                }
                SplurjHaptics.rewardItemReveal()
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(.easeInOut(duration: 0.15)) {
                    beamScale = 0.3
                }
                try? await Task.sleep(for: .milliseconds(150))
            }

            // Phase 3: Beam explodes, card emerges
            phase = 3
            showParticles = true
            if isLegendary { SplurjHaptics.legendaryReveal() }
            else { SplurjHaptics.epicReveal() }

            withAnimation(.easeOut(duration: 0.3)) {
                beamScale = 8
                beamOpacity = 0
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                cardScale = 1.0
                cardOpacity = 1.0
                bgColorShift = true
            }

            try? await Task.sleep(for: .milliseconds(400))

            // Phase 4: Card 360° rotation
            phase = 4
            withAnimation(.easeInOut(duration: 1.0)) {
                cardRotationY = 360
            }

            try? await Task.sleep(for: .milliseconds(1000))

            // Phase 5: Info reveals
            phase = 5
            withAnimation(.easeOut(duration: 0.3)) {
                starsRevealed = starCount
            }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeOut(duration: 0.3)) {
                nameOpacity = 1.0
            }

            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeOut(duration: 0.3)) {
                tipOpacity = 1.0
            }

            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeOut(duration: 0.3)) {
                buttonOpacity = 1.0
            }
        }
    }

    private func skipToEnd() {
        phase = 5
        beamScale = 0
        beamOpacity = 0
        cardScale = 1.0
        cardOpacity = 1.0
        cardRotationY = 0
        bgColorShift = true
        starsRevealed = starCount
        nameOpacity = 1.0
        tipOpacity = 1.0
        buttonOpacity = 1.0
    }
}
