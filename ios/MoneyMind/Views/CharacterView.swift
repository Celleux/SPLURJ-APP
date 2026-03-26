import SwiftUI

struct CharacterView: View {
    let stage: CharacterStage
    let reaction: CharacterReaction
    let level: Int
    @State private var sparklePhase: Bool = false
    @State private var breatheScale: CGFloat = 1.0
    @State private var jumpOffset: CGFloat = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            glowBackground

            sparkleParticles

            characterBody
                .offset(y: jumpOffset)

            if stage == .champion {
                companionPet
            }

            if stage == .legend {
                legendaryWings
                legendaryHalo
            }
        }
        .frame(width: stage.size + 60, height: stage.size + 80)
        .onChange(of: reaction) { _, newValue in
            handleReaction(newValue)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                sparklePhase = true
            }
            if stage == .champion || stage == .legend {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
    }

    private var glowBackground: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        stage.primaryColor.opacity(stage == .legend ? 0.35 : 0.2),
                        stage.primaryColor.opacity(0.05),
                        .clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: stage.size * 0.8
                )
            )
            .frame(width: stage.size + 50, height: stage.size + 50)
            .scaleEffect(glowPulse ? 1.12 : 1.0)
    }

    @ViewBuilder
    private var characterBody: some View {
        switch stage {
        case .seedling:
            seedlingBody
        case .sprout:
            sproutBody
        case .guardian:
            guardianBody
        case .warrior:
            warriorBody
        case .champion:
            championBody
        case .legend:
            legendBody
        }
    }

    private var seedlingBody: some View {
        ZStack {
            Circle()
                .fill(stage.primaryColor.opacity(0.3))
                .frame(width: stage.size, height: stage.size)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [stage.primaryColor.opacity(0.6), stage.secondaryColor.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: stage.size - 8, height: stage.size - 8)

            HStack(spacing: stage.size * 0.15) {
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
            }
            .offset(y: -4)

            if reaction == .breathe {
                breatheCircle
            }
        }
    }

    private var sproutBody: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [stage.primaryColor, stage.secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: stage.size, height: stage.size)

            Image(systemName: "leaf.fill")
                .font(.system(size: stage.size * 0.25))
                .foregroundStyle(.white.opacity(0.15))
                .offset(x: stage.size * 0.2, y: -stage.size * 0.15)
                .rotationEffect(.degrees(-30))

            VStack(spacing: 2) {
                HStack(spacing: stage.size * 0.18) {
                    eyeShape(size: 10)
                    eyeShape(size: 10)
                }

                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.7))
                    .frame(width: 12, height: 3)
                    .offset(y: 4)
            }

            if reaction == .breathe {
                breatheCircle
            }
        }
    }

    private var guardianBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [stage.primaryColor, stage.secondaryColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: stage.size * 0.85, height: stage.size)

            Image(systemName: "shield.fill")
                .font(.system(size: stage.size * 0.3))
                .foregroundStyle(.white.opacity(0.15))
                .offset(y: stage.size * 0.15)

            VStack(spacing: 4) {
                HStack(spacing: stage.size * 0.15) {
                    eyeShape(size: 11)
                    eyeShape(size: 11)
                }

                Image(systemName: "shield.fill")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.white.opacity(0.8))
                    .offset(y: 6)
            }
            .offset(y: -stage.size * 0.08)

            if reaction == .breathe {
                breatheCircle
            }
        }
    }

    private var warriorBody: some View {
        ZStack {
            capeShape
                .offset(y: 8)

            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [stage.primaryColor, stage.secondaryColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: stage.size * 0.8, height: stage.size * 0.9)

            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: stage.size * 0.8, height: stage.size * 0.9)

            VStack(spacing: 4) {
                HStack(spacing: stage.size * 0.14) {
                    eyeShape(size: 12)
                    eyeShape(size: 12)
                }

                Image(systemName: "shield.checkered")
                    .font(Typography.headingMedium)
                    .foregroundStyle(.white.opacity(0.9))
                    .offset(y: 8)
            }
            .offset(y: -stage.size * 0.06)

            if reaction == .breathe {
                breatheCircle
            }
        }
    }

    private var championBody: some View {
        ZStack {
            capeShape
                .offset(y: 8)

            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [stage.primaryColor, stage.secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: stage.size * 0.78, height: stage.size * 0.88)

            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.5), stage.primaryColor.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: stage.size * 0.78, height: stage.size * 0.88)

            Image(systemName: "crown.fill")
                .font(Typography.bodyLarge)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, stage.primaryColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: -stage.size * 0.5)

            VStack(spacing: 4) {
                HStack(spacing: stage.size * 0.13) {
                    eyeShape(size: 12, glow: true)
                    eyeShape(size: 12, glow: true)
                }

                Image(systemName: "crown.fill")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.white.opacity(0.6))
                    .offset(y: 10)
            }
            .offset(y: -stage.size * 0.06)

            if reaction == .breathe {
                breatheCircle
            }
        }
    }

    private var legendBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [stage.primaryColor, stage.secondaryColor, .white.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: stage.size * 0.76, height: stage.size * 0.86)

            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    AngularGradient(
                        colors: [.white.opacity(0.6), stage.primaryColor, .white.opacity(0.6)],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: stage.size * 0.76, height: stage.size * 0.86)

            VStack(spacing: 4) {
                HStack(spacing: stage.size * 0.12) {
                    eyeShape(size: 13, glow: true)
                    eyeShape(size: 13, glow: true)
                }

                Image(systemName: "sparkles")
                    .font(Typography.headingMedium)
                    .foregroundStyle(.white)
                    .offset(y: 10)
            }
            .offset(y: -stage.size * 0.04)

            if reaction == .breathe {
                breatheCircle
            }
        }
    }

    private var capeShape: some View {
        Image(systemName: "shield.fill")
            .font(.system(size: stage.size * 0.6))
            .foregroundStyle(stage.primaryColor.opacity(0.2))
            .scaleEffect(x: 1.4, y: 1.1)
            .rotationEffect(.degrees(180))
    }

    private var companionPet: some View {
        ZStack {
            Circle()
                .fill(stage.primaryColor.opacity(0.4))
                .frame(width: 20, height: 20)
            Circle()
                .fill(stage.primaryColor.opacity(0.7))
                .frame(width: 14, height: 14)
            HStack(spacing: 4) {
                Circle().fill(.white).frame(width: 3, height: 3)
                Circle().fill(.white).frame(width: 3, height: 3)
            }
        }
        .offset(x: stage.size * 0.45, y: stage.size * 0.3)
        .offset(y: sparklePhase ? -3 : 3)
    }

    private var legendaryWings: some View {
        HStack(spacing: stage.size * 0.7) {
            Image(systemName: "wing")
                .font(.system(size: stage.size * 0.35))
                .foregroundStyle(
                    LinearGradient(
                        colors: [stage.primaryColor.opacity(0.6), .white.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(0))
                .scaleEffect(x: -1)

            Image(systemName: "wing")
                .font(.system(size: stage.size * 0.35))
                .foregroundStyle(
                    LinearGradient(
                        colors: [stage.primaryColor.opacity(0.6), .white.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .offset(y: -stage.size * 0.08)
    }

    private var legendaryHalo: some View {
        Ellipse()
            .strokeBorder(
                AngularGradient(
                    colors: [stage.primaryColor, .white.opacity(0.8), stage.primaryColor],
                    center: .center
                ),
                lineWidth: 2.5
            )
            .frame(width: stage.size * 0.5, height: stage.size * 0.15)
            .offset(y: -stage.size * 0.55)
            .opacity(glowPulse ? 1.0 : 0.6)
    }

    private var sparkleParticles: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let angle = Double(i) * 60.0
                let radius = stage.size * 0.55
                let x = cos(angle * .pi / 180) * radius
                let y = sin(angle * .pi / 180) * radius

                Image(systemName: "sparkle")
                    .font(.system(size: sparklePhase ? 6 : 4))
                    .foregroundStyle(stage.primaryColor.opacity(sparklePhase ? 0.8 : 0.2))
                    .offset(x: x, y: y)
            }
        }
    }

    private var breatheCircle: some View {
        Circle()
            .strokeBorder(Theme.teal.opacity(0.4), lineWidth: 2)
            .frame(width: stage.size + 30, height: stage.size + 30)
            .scaleEffect(breatheScale)
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    breatheScale = 1.15
                }
            }
            .onDisappear {
                breatheScale = 1.0
            }
    }

    private func eyeShape(size: CGFloat, glow: Bool = false) -> some View {
        ZStack {
            if glow {
                Circle()
                    .fill(.white.opacity(0.3))
                    .frame(width: size + 4, height: size + 4)
                    .blur(radius: 3)
            }
            Circle()
                .fill(.white)
                .frame(width: size, height: size)
            Circle()
                .fill(Color.black)
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(y: reaction == .sympathize ? 1 : 0)
        }
    }

    private func handleReaction(_ reaction: CharacterReaction) {
        switch reaction {
        case .celebrate:
            withAnimation(.spring(response: 0.25, dampingFraction: 0.3)) {
                jumpOffset = -20
            }
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        jumpOffset = 0
                    }
                }
            }
        case .breathe:
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                breatheScale = 1.15
            }
        case .idle:
            withAnimation(.spring) {
                jumpOffset = 0
                breatheScale = 1.0
            }
        default:
            break
        }
    }
}

struct XPProgressBar: View {
    let progress: Double
    let level: Int
    let stage: CharacterStage
    let currentXP: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Level \(level)")
                    .font(Typography.labelSmall)
                    .foregroundStyle(stage.primaryColor)

                Spacer()

                Text(stage.name)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.cardSurface)
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [stage.primaryColor, stage.secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(currentXP) XP")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                if level < 50 {
                    Text("\(CharacterStage.xpForNextLevel(level)) XP")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Text("MAX")
                        .font(Typography.labelSmall)
                        .foregroundStyle(stage.primaryColor)
                }
            }
        }
    }
}

struct SimpleModeView: View {
    let dayCount: Int
    let totalSaved: Double
    let level: Int

    var body: some View {
        HStack(spacing: 16) {
            simpleStat("Day \(dayCount)", icon: "calendar")
            divider
            simpleStat(totalSaved.formatted(.currency(code: "USD").precision(.fractionLength(0))), icon: "dollarsign.circle.fill")
            divider
            simpleStat("Lv. \(level)", icon: "star.fill")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .splurjCard(.elevated)
    }

    private func simpleStat(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.accentGreen)
            Text(text)
                .font(Typography.headingSmall)
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.textSecondary.opacity(0.2))
            .frame(width: 1, height: 20)
    }
}

struct SocialProofCard: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.teal)
                .frame(width: 32)

            Text(message)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textPrimary.opacity(0.85))
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(16)
        .splurjCard(.subtle)
    }
}

struct ReactionMessageBubble: View {
    let message: String
    let stage: CharacterStage

    var body: some View {
        Text(message)
            .font(Typography.bodyMedium)
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Theme.cardSurface,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(stage.primaryColor.opacity(0.2), lineWidth: 1)
            )
    }
}
