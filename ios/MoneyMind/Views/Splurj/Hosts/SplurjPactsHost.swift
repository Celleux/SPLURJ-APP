import SwiftUI
import SwiftData

// MARK: - Splurj Pacts host
//
// Feeds real SavingsChallenge + ChallengeParticipant data into
// SplurjPactsView. CloudKit invite fetching stays in the legacy path —
// this host just reflects what SwiftData currently knows.

struct SplurjPactsHost: View {
    @Query private var profiles: [UserProfile]
    @Query(filter: #Predicate<SavingsChallenge> { $0.isActive })
    private var activeChallenges: [SavingsChallenge]
    @Query private var allChallenges: [SavingsChallenge]
    @Query private var participants: [ChallengeParticipant]

    @State private var showProfile = false
    @State private var showLegacyPactsHub = false

    private var profile: UserProfile? { profiles.first }
    private var variant: SplurjVariant { profile?.splurjVariant ?? .her }
    private var currencySymbol: String { profile?.currencySymbol ?? "$" }

    private var level: Int {
        max(profile?.splurjLevel ?? 1, (profile?.currentStreak ?? 0) / 3 + 1)
    }

    private var combinedPot: Int {
        Int(activeChallenges.reduce(0.0) { $0 + $1.totalSaved }.rounded())
    }

    private var uniqueFriendIDs: Set<String> {
        var set = Set<String>()
        for p in participants where activeChallenges.contains(where: { $0.inviteCode == p.challengeID }) {
            set.insert(p.userID)
        }
        return set
    }

    private var activePactData: [SplurjPactsView.PactCardData] {
        activeChallenges.map { challenge in
            let parts = participants.filter { $0.challengeID == challenge.inviteCode }
            let totalDays = totalDays(for: challenge)
            let streakDay = min(totalDays, daysSince(challenge.startDate))
            let onTrack = (parts.first?.currentStreak ?? streakDay) >= streakDay - 2
            let partners: [SplurjPactsView.PactCardData.Partner] = parts.prefix(3).enumerated().map { idx, part in
                .init(initial: String(part.displayName.prefix(1)).uppercased(), tone: tone(forIndex: idx))
            }
            let fallbackPartners: [SplurjPactsView.PactCardData.Partner] = partners.isEmpty
                ? [.init(initial: "U", tone: .green)]
                : partners
            return .init(
                id: "\(challenge.persistentModelID.hashValue)",
                title: title(for: challenge),
                sub: sub(for: challenge),
                partners: fallbackPartners,
                streakDay: streakDay,
                totalDays: totalDays,
                pot: Int(challenge.totalSaved.rounded()),
                onTrack: onTrack
            )
        }
    }

    private var completedCount: Int {
        allChallenges.filter { !$0.isActive }.count
    }

    private var wonCount: Int {
        allChallenges.filter { !$0.isActive && $0.totalSaved > 0 }.count
    }

    private var earnedTotal: Int {
        Int(allChallenges.filter { !$0.isActive }.reduce(0.0) { $0 + $1.totalSaved }.rounded())
    }

    var body: some View {
        SplurjPactsView(
            variant: variant,
            level: level,
            combinedPot: combinedPot,
            activeCount: activeChallenges.count,
            invitesCount: 0,
            friendCount: uniqueFriendIDs.count,
            currencySymbol: currencySymbol,
            activePacts: activePactData,
            invites: [],
            historyCompleted: completedCount,
            historyWon: wonCount,
            historyEarned: earnedTotal,
            onNewPact: { showLegacyPactsHub = true },
            onOpenProfile: { showProfile = true }
        )
        .sheet(isPresented: $showProfile) {
            SplurjProfileHost()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showLegacyPactsHub) {
            NavigationStack { ChallengesHubView() }
        }
    }

    private func tone(forIndex i: Int) -> SplurjPactsView.PactCardData.Partner.Tone {
        let palette: [SplurjPactsView.PactCardData.Partner.Tone] = [.pink, .blue, .green, .honey, .petal]
        return palette[i % palette.count]
    }

    private func daysSince(_ date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let now = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: start, to: now).day ?? 0
    }

    private func totalDays(for challenge: SavingsChallenge) -> Int {
        switch challenge.typeRaw.lowercased() {
        case "envelope100": return 100
        case "week52", "week":     return 52
        case "nospend", "no_spend": return 30
        case "roundup":            return 30
        default:                   return 30
        }
    }

    private func title(for challenge: SavingsChallenge) -> String {
        switch challenge.typeRaw.lowercased() {
        case "envelope100": return "Envelope 100 challenge"
        case "week52", "week":  return "52-week ladder"
        case "nospend", "no_spend": return "No-spend month"
        case "roundup":          return "Round-up drips"
        default:                  return "Splurji pact"
        }
    }

    private func sub(for challenge: SavingsChallenge) -> String {
        switch challenge.typeRaw.lowercased() {
        case "envelope100": return "Fill envelopes 1\u{2013}100 over 100 days. Keep the rhythm."
        case "week52", "week":  return "Save week N dollars each week. Hit every week, win the vault."
        case "nospend", "no_spend": return "No discretionary spend for 30 days. Splurji tracks every day."
        case "roundup":          return "Spare change auto-saved. Every tap buys you a seedling."
        default:                  return "Keep showing up. Splurji's watching."
        }
    }
}
