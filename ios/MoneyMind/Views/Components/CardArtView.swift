import SwiftUI

struct CardArtView: View {
    let card: CardDefinition
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var holoPulse: Bool = false
    @State private var patternPulse: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            card.rarity.color.opacity(0.3),
                            Theme.surface,
                            Theme.background
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if !reduceMotion {
                setPatternOverlay
                    .clipShape(.rect(cornerRadius: 12))
            }

            rarityBorder

            VStack(spacing: 10) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(card.rarity.color.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .blur(radius: card.rarity == .legendary ? 12 : 6)

                    Image(systemName: card.set.icon)
                        .font(Typography.displayLarge)
                        .foregroundStyle(card.rarity.color)
                        .shadow(color: card.rarity.color.opacity(card.rarity == .legendary ? 0.6 : 0.3), radius: card.rarity == .legendary ? 12 : 4)
                        .rotationEffect(card.rarity == .legendary && !reduceMotion ? .degrees(holoPulse ? 2 : -2) : .zero)
                        .animation(card.rarity == .legendary && !reduceMotion ? .easeInOut(duration: 3).repeatForever(autoreverses: true) : .default, value: holoPulse)
                }

                Text(card.name)
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)

                Text(card.rarity.label)
                    .font(Typography.labelSmall)
                    .foregroundStyle(card.rarity.color)

                Text(card.tip)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 10)

                Spacer()

                Text(card.set.rawValue)
                    .font(Typography.labelSmall)
                    .foregroundStyle(card.set.accentColor.opacity(0.6))
                    .padding(.bottom, 10)
            }
            .padding(.vertical, 8)

            if !reduceMotion {
                legendaryHoloOverlay
            }
        }
        .clipShape(.rect(cornerRadius: 12))
        .onAppear {
            guard !reduceMotion else { return }
            holoPulse = true
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                patternPulse = true
            }
        }
    }

    @ViewBuilder
    private var setPatternOverlay: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let opacity: Double = patternPulse ? 0.06 : 0.03
                context.opacity = opacity

                switch card.set {
                case .saversGuild:
                    drawHexGrid(context: context, size: size)
                case .compoundInterest:
                    drawSpiral(context: context, size: size)
                case .budgetWarriors:
                    drawChevrons(context: context, size: size)
                case .debtSlayers:
                    drawLightningBolts(context: context, size: size)
                case .impulseDefenders:
                    drawRipples(context: context, size: size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var rarityBorder: some View {
        switch card.rarity {
        case .common:
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Theme.glassBorder, lineWidth: 0.5)
        case .uncommon:
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Theme.accent.opacity(0.4), lineWidth: 1.5)
        case .rare:
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Theme.axisEmotional.opacity(0.6), lineWidth: 2)
                .shadow(color: Theme.axisEmotional.opacity(0.2), radius: 4)
        case .epic:
            if reduceMotion {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.lavender, lineWidth: 2)
                    .shadow(color: Theme.lavender.opacity(0.35), radius: 8)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    let angle = (elapsed / 3.0).truncatingRemainder(dividingBy: 1.0) * 360
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            AngularGradient(
                                colors: [Theme.lavender, Color(hex: 0x8B5CF6), Theme.lavender],
                                center: .center,
                                startAngle: .degrees(angle),
                                endAngle: .degrees(angle + 360)
                            ),
                            lineWidth: 2
                        )
                        .shadow(color: Theme.lavender.opacity(0.35), radius: 8)
                }
            }
        case .legendary:
            if reduceMotion {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.gold, lineWidth: 3)
                    .shadow(color: Theme.gold.opacity(0.5), radius: 16)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    let angle = (elapsed / 2.5).truncatingRemainder(dividingBy: 1.0) * 360
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            AngularGradient(
                                colors: [Theme.gold, Color(hex: 0xFFA500), Theme.gold, Color(hex: 0xFFEE58), Theme.gold],
                                center: .center,
                                startAngle: .degrees(angle),
                                endAngle: .degrees(angle + 360)
                            ),
                            lineWidth: 3
                        )
                        .shadow(color: Theme.gold.opacity(0.5), radius: 16)
                }
            }
        }
    }

    @ViewBuilder
    private var legendaryHoloOverlay: some View {
        if card.rarity == .legendary {
            TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                let hue = (elapsed / 6.0).truncatingRemainder(dividingBy: 1.0) * 360
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                Theme.gold.opacity(holoPulse ? 0.1 : 0.04),
                                .clear,
                                Theme.accent.opacity(holoPulse ? 0.08 : 0.03),
                                .clear
                            ]),
                            center: .center
                        )
                    )
                    .hueRotation(.degrees(hue))
                    .blendMode(.overlay)
                    .drawingGroup()
            }
        } else if card.rarity == .epic {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.lavender.opacity(holoPulse ? 0.06 : 0.02))
                .blendMode(.overlay)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        holoPulse = true
                    }
                }
        }
    }

    private func drawHexGrid(context: GraphicsContext, size: CGSize) {
        let hexSize: CGFloat = 20
        let rows = Int(size.height / (hexSize * 1.5)) + 2
        let cols = Int(size.width / (hexSize * 1.73)) + 2
        for row in 0..<rows {
            for col in 0..<cols {
                let xOff: CGFloat = row % 2 == 0 ? 0 : hexSize * 0.866
                let cx = CGFloat(col) * hexSize * 1.732 + xOff
                let cy = CGFloat(row) * hexSize * 1.5
                var path = Path()
                for i in 0..<6 {
                    let angle = CGFloat(i) * .pi / 3 - .pi / 6
                    let px = cx + hexSize * 0.8 * cos(angle)
                    let py = cy + hexSize * 0.8 * sin(angle)
                    if i == 0 { path.move(to: CGPoint(x: px, y: py)) }
                    else { path.addLine(to: CGPoint(x: px, y: py)) }
                }
                path.closeSubpath()
                context.stroke(path, with: .color(Theme.accent), lineWidth: 0.5)
            }
        }
    }

    private func drawSpiral(context: GraphicsContext, size: CGSize) {
        var path = Path()
        let cx = size.width / 2
        let cy = size.height / 2
        for i in 0..<200 {
            let t = CGFloat(i) * 0.1
            let r = t * 3
            let x = cx + r * cos(t)
            let y = cy + r * sin(t)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        context.stroke(path, with: .color(Theme.gold), lineWidth: 0.5)
    }

    private func drawChevrons(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 24
        let rows = Int(size.height / spacing) + 1
        for row in 0..<rows {
            let y = CGFloat(row) * spacing
            var path = Path()
            let cols = Int(size.width / spacing) + 1
            for col in 0..<cols {
                let x = CGFloat(col) * spacing
                path.move(to: CGPoint(x: x, y: y + 8))
                path.addLine(to: CGPoint(x: x + 8, y: y))
                path.addLine(to: CGPoint(x: x + 16, y: y + 8))
            }
            context.stroke(path, with: .color(Theme.axisEmotional), lineWidth: 0.5)
        }
    }

    private func drawLightningBolts(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 40
        let cols = Int(size.width / spacing) + 1
        let rows = Int(size.height / spacing) + 1
        for row in 0..<rows {
            for col in 0..<cols {
                let x = CGFloat(col) * spacing + (row % 2 == 0 ? 0 : spacing / 2)
                let y = CGFloat(row) * spacing
                var path = Path()
                path.move(to: CGPoint(x: x + 4, y: y))
                path.addLine(to: CGPoint(x: x, y: y + 10))
                path.addLine(to: CGPoint(x: x + 6, y: y + 8))
                path.addLine(to: CGPoint(x: x + 2, y: y + 18))
                context.stroke(path, with: .color(Theme.bossRed), lineWidth: 0.5)
            }
        }
    }

    private func drawRipples(context: GraphicsContext, size: CGSize) {
        let cx = size.width / 2
        let cy = size.height / 2
        for i in 1...8 {
            let r = CGFloat(i) * 20
            let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
            context.stroke(Circle().path(in: rect), with: .color(Theme.lavender), lineWidth: 0.5)
        }
    }
}
