import SwiftUI

// MARK: - Splurj Pacts — v2
//
// Port of explorations/v2-pacts.jsx. Hero strip with combined pot
// + New-pact button, segmented Active / Invites / History, pact cards
// with overlapping partner avatars, "ON TRACK / AT RISK" pill, and a
// streak bar.

struct SplurjPactsView: View {
    var variant: SplurjVariant = .her
    var level: Int = 7

    @State private var segment: PactSegment = .active

    nonisolated enum PactSegment: String, CaseIterable, Identifiable, Sendable {
        case active, invites, history
        var id: String { rawValue }
        var label: String {
            switch self {
            case .active:  "Active · 3"
            case .invites: "Invites · 1"
            case .history: "History"
            }
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    SplurjTopBar(title: "Pacts", variant: variant, level: level) {
                        SplurjMascotPlaceholder(variant: variant)
                    }

                    heroStrip
                        .padding(.horizontal, 22)

                    segmentPicker
                        .padding(.horizontal, 22)

                    Group {
                        switch segment {
                        case .active:  activeList
                        case .invites: invitesList
                        case .history: historyContent
                        }
                    }
                    .padding(.horizontal, 22)

                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Hero strip

    private var heroStrip: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Kicker("Combined pot", tracking: 1.6)
                Text("$340")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("3 active pacts · 2 friends")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button { } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .black))
                    Text("New pact")
                        .font(.system(size: 12, weight: .heavy))
                }
                .foregroundStyle(Color(hex: 0x1A1208))
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Theme.honey, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Theme.honey.opacity(0.15), Theme.honey.opacity(0.03)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Theme.honey.opacity(0.27), lineWidth: 1)
        )
    }

    private var segmentPicker: some View {
        HStack(spacing: 4) {
            ForEach(PactSegment.allCases) { s in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        segment = s
                    }
                } label: {
                    Text(s.label)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(segment == s ? Theme.textPrimary : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(segment == s ? AnyShapeStyle(Theme.cardTintHi) : AnyShapeStyle(Color.clear))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - Active

    private var activeList: some View {
        VStack(spacing: 10) {
            PactCard(
                title: "No scroll-shop after 10pm",
                sub: "Lock your cart between 10pm–7am. Break it, Sam wins the pot.",
                partners: [.init(initial: "M", color: Theme.petal), .init(initial: "S", color: Theme.sky)],
                streak: 18, days: 30, pot: 120, onTrack: true
            )
            PactCard(
                title: "Save $50/week, 8 weeks",
                sub: "Both hit every week, you both get your money back + a bonus leaf.",
                partners: [.init(initial: "M", color: Theme.petal), .init(initial: "J", color: Theme.glow)],
                streak: 5, days: 8, pot: 160, onTrack: true
            )
            PactCard(
                title: "No DoorDash in November",
                sub: "You slipped twice. One more and Maya keeps the pot.",
                partners: [.init(initial: "M", color: Theme.petal), .init(initial: "A", color: Theme.honey)],
                streak: 22, days: 30, pot: 60, onTrack: false
            )
        }
    }

    // MARK: - Invites

    private var invitesList: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    PartnerAvatar(.init(initial: "S", color: Theme.sky), size: 40)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Sam invited you")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\u{201C}Skip the morning latte, 14 days, $30 stake\u{201D}")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                HStack(spacing: 6) {
                    Button {} label: {
                        Text("Accept")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(Color(hex: 0x0B1614))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Theme.glow, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    Button {} label: {
                        Text("Decline")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color.clear, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Theme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.border, lineWidth: 1))
        }
    }

    // MARK: - History

    private var historyContent: some View {
        VStack(spacing: 10) {
            Text("\u{1F331}")
                .font(.system(size: 36))
                .padding(.top, 12)
            Text("12 pacts completed · 8 won · $680 earned")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Pact card

private struct PactCard: View {
    let title: String
    let sub: String
    let partners: [PactPartner]
    let streak: Int
    let days: Int
    let pot: Int
    let onTrack: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: -8) {
                    ForEach(Array(partners.enumerated()), id: \.offset) { _, p in
                        PartnerAvatar(p, size: 34)
                            .overlay(Circle().strokeBorder(Theme.background, lineWidth: 2))
                    }
                }
                Spacer()
                Pill(onTrack ? "ON TRACK" : "AT RISK", color: onTrack ? Theme.glow : Theme.honey)
            }
            Text(title)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
            Text(sub)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Kicker("Day \(streak)/\(days)", tracking: 1.4, color: Theme.textMuted)
                Spacer()
                Text("POT · $\(pot)")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(1.0)
                    .foregroundStyle(Theme.honey)
            }
            .padding(.top, 2)

            HStack(spacing: 2) {
                ForEach(0..<days, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < streak ? (onTrack ? Theme.glow : Theme.honey) : Color.white.opacity(0.08))
                        .frame(height: 6)
                        .shadow(
                            color: (i < streak && i == streak - 1) ? (onTrack ? Theme.glow : Theme.honey) : .clear,
                            radius: 4
                        )
                }
            }
        }
        .padding(16)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.border, lineWidth: 1))
    }
}

struct PactPartner {
    let initial: String
    let color: Color
}

private struct PartnerAvatar: View {
    let partner: PactPartner
    let size: CGFloat

    init(_ partner: PactPartner, size: CGFloat) {
        self.partner = partner
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [partner.color, partner.color.opacity(0.55)],
                    center: UnitPoint(x: 0.35, y: 0.3),
                    startRadius: 0,
                    endRadius: size
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Text(partner.initial)
                    .font(.system(size: size * 0.45, weight: .black))
                    .foregroundStyle(Color(hex: 0x0B1614))
            )
    }
}

#if DEBUG
#Preview("Splurj Pacts") {
    SplurjPactsView()
}
#endif
