import SwiftUI

// MARK: - Splurj Pacts — v2 (canonical port of explorations/v2-pacts.jsx)
//
// Combined-pot hero + 3-segment (Active · N / Invites · N / History).
// PactCards show overlapping partner avatars, ON TRACK / AT RISK pill,
// title, sub, day-dot streak bar, and pot amount.

struct SplurjPactsView: View {
    var variant: SplurjVariant = .her
    var level: Int = 7
    var equippedCosmetics: Set<CosmeticID> = []

    var combinedPot: Int = 0
    var activeCount: Int = 0
    var invitesCount: Int = 0
    var friendCount: Int = 0
    var currencySymbol: String = "$"

    var activePacts: [PactCardData] = []
    var invites: [InviteData] = []
    var historyCompleted: Int = 0
    var historyWon: Int = 0
    var historyEarned: Int = 0

    var onNewPact: () -> Void = {}
    var onOpenProfile: () -> Void = {}
    var onAcceptInvite: (String) -> Void = { _ in }
    var onDeclineInvite: (String) -> Void = { _ in }
    var onOpenPact: (String) -> Void = { _ in }
    var onJoinWithCode: (String) -> Void = { _ in }
    var joinCodeStatus: JoinCodeStatus = .idle

    enum JoinCodeStatus: Equatable {
        case idle
        case joining
        case joined(String)
        case error(String)
    }

    @State private var segment: PactSegment = .active
    @State private var joinCode: String = ""

    nonisolated enum PactSegment: String, CaseIterable, Identifiable, Sendable {
        case active, invites, history
        var id: String { rawValue }
    }

    struct PactCardData: Identifiable, Hashable {
        let id: String
        let title: String
        let sub: String
        let partners: [Partner]
        let streakDay: Int
        let totalDays: Int
        let pot: Int
        let onTrack: Bool

        struct Partner: Hashable {
            let initial: String
            let tone: Tone
            enum Tone: Hashable { case pink, blue, green, honey, petal }
        }
    }

    struct InviteData: Identifiable, Hashable {
        let id: String
        let fromInitial: String
        let fromName: String
        let description: String
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    SplurjTopBar(
                        title: "Pacts",
                        variant: variant,
                        level: level,
                        stateDotColor: Theme.glow,
                        onAvatarTap: onOpenProfile
                    ) {
                        SplurjMascotPlaceholder(variant: variant)
                    }

                    heroStrip
                        .padding(.horizontal, 22)

                    segmented
                        .padding(.horizontal, 22)

                    Group {
                        switch segment {
                        case .active:  activeSection
                        case .invites: invitesSection
                        case .history: historySection
                        }
                    }
                    .padding(.horizontal, 22)

                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Hero

    private var heroStrip: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Kicker("Combined pot", color: Theme.honey, tracking: 2.0)
                Text("\(currencySymbol)\(combinedPot)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(activeCount) active pact\(activeCount == 1 ? "" : "s") \u{00B7} \(friendCount) friend\(friendCount == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button(action: onNewPact) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .black))
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
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.honey.opacity(0.28), lineWidth: 1))
    }

    // MARK: - Segmented

    private var segmented: some View {
        HStack(spacing: 4) {
            ForEach(PactSegment.allCases) { s in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { segment = s }
                } label: {
                    Text(label(for: s))
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

    private func label(for s: PactSegment) -> String {
        switch s {
        case .active:  activeCount  > 0 ? "Active \u{00B7} \(activeCount)"   : "Active"
        case .invites: invitesCount > 0 ? "Invites \u{00B7} \(invitesCount)" : "Invites"
        case .history: "History"
        }
    }

    // MARK: - Active

    private var activeSection: some View {
        VStack(spacing: 10) {
            if activePacts.isEmpty {
                emptyActiveState
            } else {
                ForEach(activePacts) { pact in
                    pactCard(pact)
                }
            }
        }
    }

    private var emptyActiveState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.textMuted)
            Text("No active pacts yet.")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
            Text("Make a 30-day pact with someone you trust. Both keep it \u{2192} you both earn.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Button(action: onNewPact) {
                Text("Invite a friend")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color(hex: 0x1A1208))
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(Theme.honey, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private func pactCard(_ pact: PactCardData) -> some View {
        let statusColor = pact.onTrack ? Theme.glow : Theme.honey
        return Button { onOpenPact(pact.id) } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    partnerStack(pact.partners)
                    Spacer()
                    Text(pact.onTrack ? "ON TRACK" : "AT RISK")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(statusColor.opacity(0.12), in: Capsule())
                        .overlay(Capsule().strokeBorder(statusColor.opacity(0.4), lineWidth: 1))
                }
                Text(pact.title)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(pact.sub)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text("DAY \(pact.streakDay)/\(pact.totalDays)")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                    Text("POT \u{00B7} \(currencySymbol)\(pact.pot)")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.honey)
                }
                .padding(.top, 2)

                streakDots(day: pact.streakDay, total: pact.totalDays, color: statusColor)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func partnerStack(_ partners: [PactCardData.Partner]) -> some View {
        HStack(spacing: -8) {
            ForEach(Array(partners.enumerated()), id: \.offset) { idx, p in
                Text(p.initial)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color(hex: 0x0B1614))
                    .frame(width: 34, height: 34)
                    .background(
                        RadialGradient(
                            colors: color(for: p.tone),
                            center: UnitPoint(x: 0.35, y: 0.30),
                            startRadius: 0, endRadius: 22
                        ),
                        in: Circle()
                    )
                    .overlay(Circle().strokeBorder(Theme.background, lineWidth: 2))
                    .zIndex(Double(-idx))
            }
        }
    }

    private func color(for tone: PactCardData.Partner.Tone) -> [Color] {
        switch tone {
        case .pink:   [Theme.petal, Color(hex: 0xB87FA0)]
        case .blue:   [Theme.sky, Color(hex: 0x5A84B0)]
        case .green:  [Theme.glow, Color(hex: 0x4A8F3A)]
        case .honey:  [Theme.honey, Color(hex: 0xB8871E)]
        case .petal:  [Theme.petal, Color(hex: 0xCA8FA8)]
        }
    }

    private func streakDots(day: Int, total: Int, color: Color) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<max(1, total), id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(i < day ? color : Color.white.opacity(0.08))
                    .frame(maxWidth: .infinity)
                    .frame(height: 6)
                    .shadow(
                        color: (i < day && i == day - 1) ? color : .clear,
                        radius: 3
                    )
            }
        }
    }

    // MARK: - Invites

    private var invitesSection: some View {
        VStack(spacing: 12) {
            joinWithCodeCard

            if invites.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "envelope")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.textMuted)
                    Text("No open invites right now.")
                        .font(.system(size: 12.5, weight: .heavy))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Ask a friend for their 6-digit pact code above, or share yours from Settings.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
            } else {
                ForEach(invites) { inv in
                    inviteCard(inv)
                }
            }
        }
    }

    private var joinWithCodeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "number.square.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.honey)
                Kicker("Join with a code", color: Theme.honey, tracking: 2.0)
            }
            HStack(spacing: 8) {
                TextField("6-digit pact code", text: $joinCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 15, weight: .heavy, design: .monospaced))
                    .tracking(3.0)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )

                Button {
                    onJoinWithCode(joinCode.trimmingCharacters(in: .whitespaces).uppercased())
                } label: {
                    Group {
                        if case .joining = joinCodeStatus {
                            ProgressView().tint(Color(hex: 0x0B1614))
                        } else {
                            Text("Join")
                                .font(.system(size: 13, weight: .heavy))
                        }
                    }
                    .foregroundStyle(Color(hex: 0x0B1614))
                    .frame(minWidth: 64, minHeight: 44)
                    .background(isJoinDisabled ? Theme.honey.opacity(0.45) : Theme.honey, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isJoinDisabled)
            }

            joinCodeStatusLine
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Theme.honey.opacity(0.08), Theme.cardTint],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.honey.opacity(0.28), lineWidth: 1))
    }

    private var isJoinDisabled: Bool {
        let trimmed = joinCode.trimmingCharacters(in: .whitespaces)
        if case .joining = joinCodeStatus { return true }
        return trimmed.count < 6
    }

    @ViewBuilder
    private var joinCodeStatusLine: some View {
        switch joinCodeStatus {
        case .idle, .joining:
            EmptyView()
        case .joined(let code):
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.glow)
                Text("Joined \(code).")
                    .foregroundStyle(Theme.glow)
            }
            .font(.system(size: 11, weight: .heavy))
        case .error(let message):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.danger)
                Text(message)
                    .foregroundStyle(Theme.danger)
            }
            .font(.system(size: 11, weight: .heavy))
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func inviteCard(_ inv: InviteData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text(inv.fromInitial)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Color(hex: 0x0B1614))
                    .frame(width: 40, height: 40)
                    .background(
                        RadialGradient(
                            colors: [Theme.sky, Color(hex: 0x5A84B0)],
                            center: UnitPoint(x: 0.35, y: 0.30),
                            startRadius: 0, endRadius: 26
                        ),
                        in: Circle()
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(inv.fromName) invited you")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\u{201C}\(inv.description)\u{201D}")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
            HStack(spacing: 6) {
                Button { onAcceptInvite(inv.id) } label: {
                    Text("Accept")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Color(hex: 0x0B1614))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Theme.glow, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                Button { onDeclineInvite(inv.id) } label: {
                    Text("Decline")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Color.clear, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 12)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardTint, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.border, lineWidth: 1))
    }

    // MARK: - History

    private var historySection: some View {
        VStack(spacing: 10) {
            if historyCompleted == 0 {
                VStack(spacing: 8) {
                    Text("\u{1F331}")
                        .font(.system(size: 34))
                    Text("No pacts completed yet.")
                        .font(.system(size: 12.5, weight: .heavy))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Finish your first and it lives here.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 6) {
                    Text("\u{1F331}")
                        .font(.system(size: 30))
                    Text("\(historyCompleted) pacts completed \u{00B7} \(historyWon) won \u{00B7} \(currencySymbol)\(historyEarned) earned")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
        }
    }
}

#if DEBUG
#Preview("Pacts · active") {
    SplurjPactsView(
        level: 7,
        combinedPot: 340,
        activeCount: 3,
        invitesCount: 1,
        friendCount: 2,
        activePacts: [
            .init(id: "p1", title: "No scroll-shop after 10pm",
                  sub: "Lock your cart between 10pm\u{2013}7am. Break it, Sam wins the pot.",
                  partners: [.init(initial: "M", tone: .pink), .init(initial: "S", tone: .blue)],
                  streakDay: 18, totalDays: 30, pot: 120, onTrack: true),
            .init(id: "p2", title: "Save $50/week, 8 weeks",
                  sub: "Both hit every week, you both get your money back + a bonus leaf.",
                  partners: [.init(initial: "M", tone: .pink), .init(initial: "J", tone: .green)],
                  streakDay: 5, totalDays: 8, pot: 160, onTrack: true),
            .init(id: "p3", title: "No DoorDash in November",
                  sub: "You slipped twice. One more and Maya keeps the pot.",
                  partners: [.init(initial: "M", tone: .pink), .init(initial: "A", tone: .honey)],
                  streakDay: 22, totalDays: 30, pot: 60, onTrack: false),
        ]
    )
}
#Preview("Pacts · empty") { SplurjPactsView() }
#endif
