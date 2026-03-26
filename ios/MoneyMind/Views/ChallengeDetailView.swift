import SwiftUI
import SwiftData

private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

struct ChallengeDetailView: View {
    let challengeID: String
    let startDate: Date
    let endDate: Date
    let dailySaveAmount: Double
    let currentUserID: String
    let challengeName: String
    let goalSavingFor: String

    @Query private var participants: [ChallengeParticipant]
    @Query private var checkIns: [ChallengeCheckIn]
    @Query private var activityEvents: [ChallengeActivityEvent]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showCompareSheet = false
    @State private var calendarExpanded = true
    @State private var selectedDayIndex: Int?
    @State private var pulseRing = false
    @State private var pulseToday = false
    @State private var sentNudgeIDs: Set<String> = []
    @State private var reactedCheckInEmojis: [String: String] = [:]
    @State private var coverAnimatingParticipantID: String?
    @State private var reactionScaleID: String?
    @State private var showEliminationOverlay = false
    @State private var showCompletionOverlay = false
    @State private var showLeaveAlert = false
    @State private var eliminationIsVoluntary = false
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var previousStatus: String?
    @State private var atRiskTimer: Timer?

    private var nudgeSentKey: String {
        let dateStr = DateFormatter.yyyyMMdd.string(from: Date())
        return "nudgesSent-\(challengeID)-\(dateStr)"
    }

    private var challengeParticipants: [ChallengeParticipant] {
        participants.filter { $0.challengeID == challengeID }
    }

    private var challengeCheckIns: [ChallengeCheckIn] {
        checkIns.filter { $0.challengeID == challengeID }
    }

    private var challengeEvents: [ChallengeActivityEvent] {
        activityEvents.filter { $0.challengeID == challengeID }
            .sorted { $0.date > $1.date }
    }

    private var currentParticipant: ChallengeParticipant? {
        challengeParticipants.first { $0.userID == currentUserID }
    }

    private var activeParticipants: [ChallengeParticipant] {
        challengeParticipants.filter { $0.isActive }
    }

    private var recentCheckIns: [ChallengeCheckIn] {
        Array(
            challengeCheckIns
                .sorted { $0.date > $1.date }
                .prefix(20)
        )
    }

    private var todayCheckIns: [ChallengeCheckIn] {
        let cal = Calendar.current
        return challengeCheckIns.filter { cal.isDateInToday($0.date) }
    }

    private var checkedInTodayIDs: Set<String> {
        Set(todayCheckIns.map { $0.participantID })
    }

    private var slippedTodayIDs: Set<String> {
        Set(todayCheckIns.filter { !$0.didHold }.map { $0.participantID })
    }

    private var currentUserRank: Int {
        let sorted = challengeParticipants.sorted { $0.successfulCheckIns > $1.successfulCheckIns }
        if let idx = sorted.firstIndex(where: { $0.userID == currentUserID }) {
            return idx + 1
        }
        return 0
    }

    private var currentUserSavings: Double {
        challengeCheckIns
            .filter { $0.participantID == currentParticipant?.id }
            .reduce(0) { $0 + $1.amountSaved }
    }

    private var groupTotalSavings: Double {
        challengeCheckIns.reduce(0) { $0 + $1.amountSaved }
    }

    private var isSpectating: Bool {
        guard let me = currentParticipant else { return false }
        return me.status == "spectator" || me.status == "eliminated"
    }

    private var isChallengeComplete: Bool {
        Date() >= endDate
    }

    private var totalDays: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                whosCheckedInRow

                if isSpectating {
                    spectatorWatchingCard
                    spectatorFinalStatsCard
                } else {
                    personalStatsCard
                }

                participantsSection
                activityFeedSection
                challengeCalendarSection
                compareButton
            }
            .padding(.horizontal)
            .padding(.bottom, 80)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !isSpectating && !isChallengeComplete {
                    Menu {
                        Button(role: .destructive) {
                            showLeaveAlert = true
                        } label: {
                            Label("Leave Pact", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .onAppear {
            loadSentNudges()
            previousStatus = currentParticipant?.status
            checkChallengeCompletion()
            checkAtRiskStatus()
            startAtRiskTimer()
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulseRing = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseToday = true
            }
        }
        .onDisappear {
            atRiskTimer?.invalidate()
            atRiskTimer = nil
        }
        .onChange(of: currentParticipant?.status) { oldValue, newValue in
            if newValue == "eliminated" && oldValue != "eliminated" {
                eliminationIsVoluntary = false
                showEliminationOverlay = true
            }
        }
        .sheet(isPresented: $showCompareSheet) {
            CompareGridSheet(
                participants: challengeParticipants,
                checkIns: challengeCheckIns,
                startDate: startDate,
                endDate: endDate
            )
        }
        .fullScreenCover(isPresented: $showEliminationOverlay) {
            if let me = currentParticipant {
                ChallengeEliminationView(
                    participant: me,
                    moneySaved: currentUserSavings,
                    totalDays: totalDays,
                    groupTotalSavings: groupTotalSavings,
                    challengeName: challengeName,
                    isVoluntary: eliminationIsVoluntary,
                    onContinueAsSpectator: {
                        showEliminationOverlay = false
                    },
                    onShare: { image in
                        shareImage = image
                        showEliminationOverlay = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showShareSheet = true
                        }
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showCompletionOverlay) {
            ChallengeCompletionView(
                participants: challengeParticipants,
                groupTotalSavings: groupTotalSavings,
                challengeName: challengeName,
                goalSavingFor: goalSavingFor,
                startDate: startDate,
                endDate: endDate,
                currentUserIsSpectator: isSpectating,
                currentUserSavings: currentUserSavings,
                onDismiss: {
                    showCompletionOverlay = false
                },
                onShare: { image in
                    shareImage = image
                    showCompletionOverlay = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showShareSheet = true
                    }
                }
            )
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetView(items: [image])
            }
        }
        .alert(
            "Are you sure?",
            isPresented: $showLeaveAlert
        ) {
            Button("Stay", role: .cancel) {}
            Button("Leave", role: .destructive) {
                performLeaveChallenge()
            }
        } message: {
            Text("You've saved $\(Int(currentUserSavings)) so far.\n\nYour savings stay in the group wallet and you can still watch the pact as a spectator.")
        }
    }

    // MARK: - Spectator Mode Cards

    private var spectatorWatchingCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.textMuted)

            VStack(alignment: .leading, spacing: 2) {
                Text("You are watching this pact")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
                Text("You can still react, cheer on friends, and view stats")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()
        }
        .splurjCard(.elevated)
    }

    @ViewBuilder
    private var spectatorFinalStatsCard: some View {
        if let me = currentParticipant {
            VStack(spacing: 12) {
                HStack {
                    Text("Your Run")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }

                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("\(me.successfulCheckIns)")
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.textPrimary)
                        Text("days held")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("$\(Int(currentUserSavings))")
                            .font(Typography.moneySmall)
                            .foregroundStyle(Theme.gold)
                        Text("saved")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            Text("🔥")
                                .font(.system(size: 12))
                            Text("\(me.longestStreak)")
                                .font(Typography.headingMedium)
                                .foregroundStyle(Theme.textPrimary)
                        }
                        Text("best streak")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("\(Int(me.completionRate * 100))%")
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.textPrimary)
                        Text("success")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
            .splurjCard(.elevated)
        }
    }

    // MARK: - Leave Challenge & Captain Transfer

    private func performLeaveChallenge() {
        guard let me = currentParticipant else { return }
        HapticManager.notification(.warning)

        var mutable = ChallengeParticipant(
            challengeID: me.challengeID,
            userID: me.userID,
            displayName: me.displayName,
            emoji: me.emoji
        )
        mutable.totalCheckIns = me.totalCheckIns
        mutable.successfulCheckIns = me.successfulCheckIns
        mutable.longestStreak = me.longestStreak

        ChallengeLivesEngine.voluntaryQuit(participant: &mutable)

        me.status = mutable.status
        me.eliminationDate = mutable.eliminationDate
        me.exitSummary = mutable.exitSummary

        if me.isCreator {
            handleCreatorDeparture(creator: me)
        }

        let leaveEvent = ChallengeActivityEvent(
            challengeID: challengeID,
            message: "\(me.displayName) stepped back from the pact. Their $\(Int(currentUserSavings)) stays with us.",
            iconName: "arrow.right.circle"
        )
        modelContext.insert(leaveEvent)

        Task {
            try? await ChallengeCloudKitService.shared.saveParticipant(me)
        }

        eliminationIsVoluntary = true
        showEliminationOverlay = true
    }

    private func handleCreatorDeparture(creator: ChallengeParticipant) {
        let newCaptain = ChallengeLivesEngine.transferCaptain(
            from: creator,
            allParticipants: challengeParticipants
        )

        if let captain = newCaptain {
            let transferEvent = ChallengeActivityEvent(
                challengeID: challengeID,
                message: "\(creator.displayName) stepped back. \(captain.displayName) is now leading the pact.",
                iconName: "star.circle"
            )
            modelContext.insert(transferEvent)

            Task {
                try? await ChallengeCloudKitService.shared.saveParticipant(creator)
                try? await ChallengeCloudKitService.shared.saveParticipant(captain)
            }
        }
    }

    // MARK: - Challenge Completion Check

    private func checkChallengeCompletion() {
        guard isChallengeComplete else { return }

        let hasActiveParticipants = challengeParticipants.contains { $0.isActive }
        guard hasActiveParticipants else { return }

        let alreadyCompleted = challengeParticipants.contains { $0.status == "completed" }
        guard !alreadyCompleted else { return }

        ChallengeLivesEngine.completeChallenge(participants: challengeParticipants)

        Task {
            for p in challengeParticipants where p.status == "completed" {
                try? await ChallengeCloudKitService.shared.saveParticipant(p)
            }
        }

        awardChampionBadge()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCompletionOverlay = true
        }
    }

    // MARK: - At Risk Timer (Fix 1)

    private func checkAtRiskStatus() {
        guard let me = currentParticipant, me.status == "active" else { return }
        let hour = Calendar.current.component(.hour, from: Date())
        guard hour >= 20 else { return }
        guard !checkedInTodayIDs.contains(me.id) else { return }

        me.status = "atRisk"
        Task {
            try? await ChallengeCloudKitService.shared.saveParticipant(me)
        }
    }

    private func startAtRiskTimer() {
        atRiskTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task { @MainActor in
                checkAtRiskStatus()
            }
        }
    }

    // MARK: - Champion Badge (Fix 7)

    private func awardChampionBadge() {
        guard let me = currentParticipant, me.status == "completed" else { return }
        let descriptor = FetchDescriptor<Achievement>(predicate: #Predicate { $0.name == "Challenge Champion" })
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        let badge = Achievement.badge(
            name: "Challenge Champion",
            category: "Skill",
            badgeDescription: "Completed a Friend Challenge",
            iconName: "trophy.fill"
        )
        badge.isEarned = true
        badge.dateEarned = Date()
        modelContext.insert(badge)
    }

    // MARK: - 1) Who's Checked In Today

    private var whosCheckedInRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: -8) {
                ForEach(challengeParticipants, id: \.id) { p in
                    participantAvatar(p)
                }
                Spacer()
            }
            .padding(.leading, 4)

            let checkedCount = challengeParticipants.filter { checkedInTodayIDs.contains($0.id) }.count
            Text("\(checkedCount) of \(challengeParticipants.count) checked in today")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func participantAvatar(_ p: ChallengeParticipant) -> some View {
        let ringColor = avatarRingColor(for: p)
        let isPending = !checkedInTodayIDs.contains(p.id) && p.isActive && p.status != "shielded"

        ZStack {
            Circle()
                .strokeBorder(ringColor, lineWidth: 3)
                .frame(width: 36, height: 36)
                .opacity(isPending ? (pulseRing ? 1.0 : 0.4) : 1.0)

            Text(p.emoji.isEmpty ? "👤" : p.emoji)
                .font(.system(size: 16))

            if p.status == "completed" {
                Image(systemName: "crown.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.gold)
                    .offset(y: -16)
            }

            if p.status == "shielded" {
                Image(systemName: "snowflake")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(2)
                    .background(Theme.accentTertiary, in: Circle())
                    .offset(x: 12, y: -12)
            }

            if p.status == "spectator" || p.status == "eliminated" {
                Image(systemName: "eye.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(2)
                    .background(Theme.textMuted, in: Circle())
                    .offset(x: 12, y: -12)
            }

            if p.status == "onThinIce" {
                Circle()
                    .fill(Color(hex: 0x87CEEB).opacity(0.25))
                    .frame(width: 36, height: 36)
                Image(systemName: "snowflake")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: 0x87CEEB).opacity(0.8))
            }

            if p.status == "slipped" || slippedTodayIDs.contains(p.id) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Theme.danger)
                    .padding(2)
                    .background(Theme.background.opacity(0.8), in: Circle())
                    .offset(x: 12, y: 12)
            }
        }
        .frame(width: 42, height: 42)
    }

    private func avatarRingColor(for p: ChallengeParticipant) -> Color {
        if p.status == "completed" {
            return Theme.gold
        }
        if p.isEliminated || p.status == "spectator" {
            return Theme.textMuted
        }
        if p.status == "shielded" {
            return Theme.accentTertiary
        }
        if p.status == "slipped" || slippedTodayIDs.contains(p.id) {
            return Theme.danger
        }
        if checkedInTodayIDs.contains(p.id) {
            return Color(hex: 0x2ECC71)
        }
        if p.status == "onThinIce" {
            return Color(hex: 0x87CEEB)
        }
        if p.status == "atRisk" {
            return Theme.warning
        }
        return Theme.warning
    }

    // MARK: - 2) Personal Stats Card

    @ViewBuilder
    private var personalStatsCard: some View {
        if let me = currentParticipant {
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 18))
                        Text("\(me.currentStreak)")
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.gold)
                    }

                    Spacer()

                    livesDisplay(remaining: me.livesRemaining)

                    Spacer()

                    shieldsDisplay(available: me.streakShieldsAvailable)
                }

                HStack(spacing: 16) {
                    Text("$\(Int(currentUserSavings))")
                        .font(Typography.moneySmall)
                        .foregroundStyle(Theme.gold)

                    Spacer()

                    Text("\(currentUserRank) of \(challengeParticipants.count)")
                        .font(Typography.labelMedium)
                        .foregroundStyle(Theme.textSecondary)

                    Spacer()

                    Text("\(Int(me.completionRate * 100))% success")
                        .font(Typography.labelMedium)
                        .foregroundStyle(Theme.textSecondary)
                }

                if me.status == "onThinIce" {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.danger)
                        Text("On Thin Ice! 1 more slip = eliminated")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.danger)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Theme.danger.opacity(0.1), in: .rect(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Theme.danger.opacity(0.3), lineWidth: 1)
                    )
                }

                if me.streakShieldsAvailable > 0 && !me.shieldActiveToday {
                    Button {
                        var mutable = me
                        _ = ChallengeLivesEngine.activateShield(participant: &mutable)
                        me.shieldActiveToday = mutable.shieldActiveToday
                        me.status = mutable.status
                        me.streakShieldsAvailable = mutable.streakShieldsAvailable
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "snowflake")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Equip Streak Shield for tomorrow")
                                .font(Typography.labelSmall)
                        }
                        .foregroundStyle(Theme.accentTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.accentTertiary.opacity(0.1), in: .rect(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .splurjCard(.elevated)
            .overlay(
                Group {
                    if me.status == "onThinIce" {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Theme.danger.opacity(0.4), lineWidth: 1.5)
                    }
                }
            )
        }
    }

    private func livesDisplay(remaining: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: i < remaining ? "shield.fill" : "shield")
                    .font(.system(size: 13))
                    .foregroundStyle(i < remaining ? Theme.accent : Theme.textMuted)
            }
        }
    }

    private func shieldsDisplay(available: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<2, id: \.self) { i in
                Image(systemName: "snowflake")
                    .font(.system(size: 12))
                    .foregroundStyle(i < available ? Theme.accentTertiary : Theme.textMuted.opacity(0.4))
            }
        }
    }

    // MARK: - 3) Participants Section with Nudge

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(Theme.accent)
                Text("Participants")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            ForEach(challengeParticipants, id: \.id) { p in
                participantRow(p)
            }
        }
        .splurjCard(.elevated)
    }

    @ViewBuilder
    private func participantRow(_ p: ChallengeParticipant) -> some View {
        let hasCheckedIn = checkedInTodayIDs.contains(p.id)
        let isCurrentUser = p.userID == currentUserID
        let pIsSpectator = p.status == "spectator" || p.status == "eliminated"
        let showNudge = !hasCheckedIn && p.isActive && !isCurrentUser && p.status != "shielded"
        let showCheer = pIsSpectator && !isCurrentUser && isSpectating
        let alreadySent = sentNudgeIDs.contains(p.id)

        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(avatarRingColor(for: p).opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(p.emoji.isEmpty ? "👤" : p.emoji)
                    .font(.system(size: 18))

                if p.status == "completed" {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Theme.gold)
                        .offset(y: -18)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(p.displayName)
                        .font(Typography.labelMedium)
                        .foregroundStyle(pIsSpectator ? Theme.textSecondary : Theme.textPrimary)
                    if pIsSpectator {
                        Text("(Spectator)")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textMuted)
                    }
                    if hasCheckedIn {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: 0x2ECC71))
                    }
                }
                HStack(spacing: 4) {
                    Text("🔥 \(p.currentStreak)")
                        .font(Typography.labelSmall)
                        .foregroundStyle(pIsSpectator ? Theme.textMuted : Theme.gold)
                    Text("·")
                        .foregroundStyle(Theme.textMuted)
                    Text(statusLabel(for: p))
                        .font(Typography.labelSmall)
                        .foregroundStyle(statusColor(for: p))
                }
            }

            Spacer()

            if showNudge || showCheer {
                Button {
                    guard !alreadySent else { return }
                    sendNudge(to: p, isCheer: showCheer)
                } label: {
                    HStack(spacing: 4) {
                        if alreadySent {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Sent!")
                                .font(Typography.labelSmall)
                        } else {
                            Text(showCheer ? "Cheer On" : "Nudge")
                                .font(Typography.labelSmall)
                        }
                    }
                    .foregroundStyle(alreadySent ? Theme.textMuted : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        alreadySent ? Theme.elevated : Theme.accentSecondary,
                        in: .capsule
                    )
                }
                .buttonStyle(.plain)
                .disabled(alreadySent)
            }
        }
        .padding(.vertical, 4)
    }

    private func statusLabel(for p: ChallengeParticipant) -> String {
        switch p.status {
        case "active": return "Active"
        case "shielded": return "Shielded"
        case "atRisk": return "At Risk"
        case "slipped": return "Slipped"
        case "onThinIce": return "Thin Ice"
        case "eliminated": return "Spectator"
        case "spectator": return "Spectator"
        case "completed": return "Champion"
        default: return p.status.capitalized
        }
    }

    private func statusColor(for p: ChallengeParticipant) -> Color {
        switch p.status {
        case "active": return Theme.accentSecondary
        case "shielded": return Theme.accentTertiary
        case "atRisk": return Theme.warning
        case "slipped": return Theme.danger
        case "onThinIce": return Color(hex: 0x87CEEB)
        case "eliminated": return Theme.textMuted
        case "spectator": return Theme.textSecondary
        case "completed": return Theme.gold
        default: return Theme.textSecondary
        }
    }

    private func sendNudge(to participant: ChallengeParticipant, isCheer: Bool) {
        guard let me = currentParticipant else { return }
        HapticManager.impact(.light)

        let nudge = ChallengeNudge(
            challengeID: challengeID,
            senderName: me.displayName,
            senderEmoji: me.emoji,
            receiverName: participant.displayName,
            type: isCheer ? "cheerOn" : "nudge"
        )
        modelContext.insert(nudge)

        if isCheer {
            ChallengeNotificationService.scheduleCheerOn(senderEmoji: me.emoji, senderName: me.displayName)
        } else {
            ChallengeNotificationService.scheduleNudge(senderEmoji: me.emoji, senderName: me.displayName, challengeName: challengeName)
        }

        withAnimation(Theme.spring) {
            sentNudgeIDs.insert(participant.id)
        }
        saveSentNudges()

        Task {
            try? await ChallengeCloudKitService.shared.saveNudge(nudge)
        }
    }

    private func loadSentNudges() {
        if let data = UserDefaults.standard.data(forKey: nudgeSentKey),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            sentNudgeIDs = ids
        }
    }

    private func saveSentNudges() {
        if let data = try? JSONEncoder().encode(sentNudgeIDs) {
            UserDefaults.standard.set(data, forKey: nudgeSentKey)
        }
    }

    // MARK: - 4) Activity Feed with Reactions

    private var activityFeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Theme.accent)
                Text("Recent Activity")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            if recentCheckIns.isEmpty && challengeEvents.isEmpty {
                Text("No activity yet")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(challengeEvents.prefix(5), id: \.id) { event in
                    eventRow(event)
                }
                ForEach(recentCheckIns, id: \.id) { checkIn in
                    activityRow(checkIn)
                }
            }
        }
        .splurjCard(.elevated)
    }

    private func eventRow(_ event: ChallengeActivityEvent) -> some View {
        HStack(spacing: 10) {
            Image(systemName: event.iconName)
                .font(.system(size: 16))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 24)

            Text(event.message)
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
                .italic()

            Spacer()
        }
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            Theme.divider.frame(height: 0.5)
        }
    }

    @ViewBuilder
    private func activityRow(_ checkIn: ChallengeCheckIn) -> some View {
        let participant = challengeParticipants.first { $0.id == checkIn.participantID }
        let isSlip = !checkIn.didHold

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(participant?.emoji ?? "👤")
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(participant?.displayName ?? "Unknown")
                            .font(Typography.labelMedium)
                            .foregroundStyle(Theme.textPrimary)
                        if isSlip {
                            Text("slipped")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.danger)
                        } else {
                            Text("held strong")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Color(hex: 0x2ECC71))
                        }
                    }
                    Text(checkIn.date.formatted(.relative(presentation: .named)))
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                if !isSlip {
                    Text("$\(Int(checkIn.amountSaved))")
                        .font(Typography.moneySmall)
                        .foregroundStyle(Theme.gold)
                }
            }

            reactionBar(for: checkIn, isSlip: isSlip)

            if isSlip, let participant, !isSpectating {
                coverFriendButton(for: participant)
            }
        }
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            Theme.divider.frame(height: 0.5)
        }
    }

    // MARK: - Reaction Bar

    private static let allReactionEmojis: [(key: String, emoji: String)] = [
        ("fire", "🔥"), ("flex", "💪"), ("party", "🎉"), ("heart", "❤️"), ("clap", "👏")
    ]

    private static let supportiveReactionEmojis: [(key: String, emoji: String)] = [
        ("heart", "❤️"), ("clap", "👏")
    ]

    @ViewBuilder
    private func reactionBar(for checkIn: ChallengeCheckIn, isSlip: Bool) -> some View {
        let emojis = isSlip ? Self.supportiveReactionEmojis : Self.allReactionEmojis
        let currentUserName = currentParticipant?.displayName ?? ""
        let myReaction = reactedCheckInEmojis[checkIn.id] ?? existingReaction(in: checkIn, userName: currentUserName)

        HStack(spacing: 6) {
            ForEach(emojis, id: \.key) { reaction in
                let count = reactionCount(for: reaction.key, in: checkIn)
                let isSelected = myReaction == reaction.key
                let scaleUp = reactionScaleID == "\(checkIn.id)-\(reaction.key)"

                Button {
                    toggleReaction(reaction.key, on: checkIn)
                } label: {
                    HStack(spacing: 2) {
                        Text(reaction.emoji)
                            .font(.system(size: 16))
                            .scaleEffect(scaleUp ? 1.4 : 1.0)
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(isSelected ? Theme.gold : Theme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        isSelected ? Theme.accent.opacity(0.15) : Theme.surface,
                        in: .capsule
                    )
                    .overlay {
                        if isSelected {
                            Capsule()
                                .strokeBorder(Theme.accent.opacity(0.3), lineWidth: 1)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private func existingReaction(in checkIn: ChallengeCheckIn, userName: String) -> String? {
        for r in checkIn.reactions {
            let parts = r.split(separator: ":", maxSplits: 1)
            if parts.count == 2, String(parts[1]) == userName {
                return String(parts[0])
            }
        }
        return nil
    }

    private func reactionCount(for key: String, in checkIn: ChallengeCheckIn) -> Int {
        checkIn.reactions.filter { $0.hasPrefix("\(key):") }.count
    }

    private func toggleReaction(_ key: String, on checkIn: ChallengeCheckIn) {
        guard let me = currentParticipant else { return }
        HapticManager.impact(.light)

        let previousKey = reactedCheckInEmojis[checkIn.id] ?? existingReaction(in: checkIn, userName: me.displayName)

        var updated = checkIn.reactions
        if let prev = previousKey {
            updated.removeAll { $0 == "\(prev):\(me.displayName)" }
        }

        if previousKey == key {
            reactedCheckInEmojis[checkIn.id] = nil
        } else {
            let myEntry = "\(key):\(me.displayName)"
            updated.append(myEntry)
            reactedCheckInEmojis[checkIn.id] = key

            let emojiMap: [String: String] = ["fire": "🔥", "flex": "💪", "party": "🎉", "heart": "❤️", "clap": "👏"]
            ChallengeNotificationService.scheduleReaction(senderName: me.displayName, emoji: emojiMap[key] ?? key)

            let scaleID = "\(checkIn.id)-\(key)"
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                reactionScaleID = scaleID
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    if reactionScaleID == scaleID { reactionScaleID = nil }
                }
            }
        }

        checkIn.reactions = updated

        Task {
            try? await ChallengeCloudKitService.shared.updateCheckInReactions(
                checkInID: checkIn.id,
                reactions: updated
            )
        }
    }

    // MARK: - Cover Friend Button

    @ViewBuilder
    private func coverFriendButton(for participant: ChallengeParticipant) -> some View {
        if let me = currentParticipant,
           me.id != participant.id,
           me.livesRemaining >= 2,
           !me.hasCoveredFriendIDs.contains(participant.id) {
            ZStack {
                Button {
                    performCover(participant: participant)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 12))
                        Text("Cover \(participant.displayName)")
                            .font(Typography.labelSmall)
                    }
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.accent.opacity(0.12), in: .capsule)
                    .overlay(
                        Capsule().strokeBorder(Theme.accent.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if coverAnimatingParticipantID == participant.id {
                    CoverShieldAnimation()
                }
            }
        }
    }

    private func performCover(participant: ChallengeParticipant) {
        guard let me = currentParticipant else { return }
        var giverCopy = ChallengeParticipant(
            challengeID: me.challengeID,
            userID: me.userID,
            displayName: me.displayName,
            emoji: me.emoji
        )
        giverCopy.livesRemaining = me.livesRemaining
        giverCopy.hasCoveredFriendIDs = me.hasCoveredFriendIDs

        var receiverCopy = ChallengeParticipant(
            challengeID: participant.challengeID,
            userID: participant.userID,
            displayName: participant.displayName,
            emoji: participant.emoji
        )
        receiverCopy.id = participant.id
        receiverCopy.livesRemaining = participant.livesRemaining
        receiverCopy.wasCoveredToday = participant.wasCoveredToday
        receiverCopy.status = participant.status

        let success = ChallengeLivesEngine.coverFriend(giver: &giverCopy, receiver: &receiverCopy)
        guard success else { return }

        HapticManager.notification(.success)
        ChallengeNotificationService.scheduleCoverReceived(senderName: me.displayName)

        me.livesRemaining = giverCopy.livesRemaining
        me.hasCoveredFriendIDs = giverCopy.hasCoveredFriendIDs

        participant.livesRemaining = receiverCopy.livesRemaining
        participant.wasCoveredToday = receiverCopy.wasCoveredToday
        participant.status = receiverCopy.status

        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            coverAnimatingParticipantID = participant.id
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) { coverAnimatingParticipantID = nil }
        }

        Task {
            try? await ChallengeCloudKitService.shared.saveParticipant(me)
            try? await ChallengeCloudKitService.shared.saveParticipant(participant)
        }
    }

    // MARK: - 5) Challenge Calendar

    private var allDays: [Date] {
        let cal = Calendar.current
        var days: [Date] = []
        var current = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: endDate)
        while current <= end {
            days.append(current)
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return days
    }

    private var leadingPadding: Int {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: allDays.first ?? startDate)
        let mondayBased = (weekday + 5) % 7
        return mondayBased
    }

    private var myCheckInsByDay: [String: ChallengeCheckIn] {
        guard let me = currentParticipant else { return [:] }
        let formatter = DateFormatter.yyyyMMdd
        var dict: [String: ChallengeCheckIn] = [:]
        for ci in challengeCheckIns where ci.participantID == me.id {
            let key = formatter.string(from: ci.date)
            dict[key] = ci
        }
        return dict
    }

    private var challengeCalendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(Theme.spring) { calendarExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(Theme.accent)
                    Text("Pact Calendar")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: calendarExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if calendarExpanded {
                calendarGrid
            }
        }
        .splurjCard(.elevated)
    }

    private let weekdayHeaders = ["M", "T", "W", "T", "F", "S", "S"]
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var calendarGrid: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let formatter = DateFormatter.yyyyMMdd
        let days = allDays

        return VStack(spacing: 4) {
            LazyVGrid(columns: gridColumns, spacing: 4) {
                ForEach(weekdayHeaders.indices, id: \.self) { i in
                    Text(weekdayHeaders[i])
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textMuted)
                        .frame(height: 20)
                }
            }

            LazyVGrid(columns: gridColumns, spacing: 4) {
                ForEach(0..<leadingPadding, id: \.self) { _ in
                    Color.clear.frame(width: 32, height: 32)
                }

                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    let key = formatter.string(from: day)
                    let checkIn = myCheckInsByDay[key]
                    let isToday = cal.isDate(day, inSameDayAs: today)
                    let isFuture = day > today
                    let dayNum = cal.component(.day, from: day)

                    calendarCell(
                        dayNum: dayNum,
                        checkIn: checkIn,
                        isToday: isToday,
                        isFuture: isFuture,
                        index: index
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func calendarCell(dayNum: Int, checkIn: ChallengeCheckIn?, isToday: Bool, isFuture: Bool, index: Int) -> some View {
        let cellColor = dayCellColor(checkIn: checkIn, isToday: isToday, isFuture: isFuture, index: index)
        let isShieldDay = checkIn?.shieldUsed == true

        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(cellColor)
                .frame(width: 32, height: 32)

            if isFuture {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Theme.elevated, lineWidth: 1)
                    .frame(width: 32, height: 32)
            }

            if isToday {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Theme.accent, lineWidth: 2)
                    .frame(width: 32, height: 32)
                    .opacity(pulseToday ? 1.0 : 0.3)
            }

            Text("\(dayNum)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isFuture ? Theme.textMuted : Theme.textPrimary)

            if isShieldDay {
                Image(systemName: "snowflake")
                    .font(.system(size: 7))
                    .foregroundStyle(.white)
                    .offset(x: 8, y: -8)
            }
        }
        .onTapGesture {
            guard !isFuture, checkIn != nil || !isFuture else { return }
            withAnimation(Theme.spring) {
                selectedDayIndex = selectedDayIndex == index ? nil : index
            }
        }
        .overlay(alignment: .top) {
            if selectedDayIndex == index, !isFuture {
                dayTooltip(checkIn: checkIn)
                    .offset(y: -30)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(10)
            }
        }
    }

    private func dayCellColor(checkIn: ChallengeCheckIn?, isToday: Bool, isFuture: Bool, index: Int) -> Color {
        if isFuture { return Theme.surface }
        guard let ci = checkIn else {
            return isToday ? Theme.surface : Theme.elevated.opacity(0.5)
        }
        if ci.shieldUsed {
            return Theme.accentTertiary.opacity(0.6)
        }
        if !ci.didHold {
            return Theme.danger.opacity(0.6)
        }
        if isOnHotStreak(at: index) {
            return Color(hex: 0x2ECC71).opacity(0.7)
        }
        return Theme.accent.opacity(0.6)
    }

    private func isOnHotStreak(at index: Int) -> Bool {
        let days = allDays
        let formatter = DateFormatter.yyyyMMdd
        var consecutiveHeld = 0
        var i = index
        while i >= 0 {
            let key = formatter.string(from: days[i])
            if let ci = myCheckInsByDay[key], ci.didHold {
                consecutiveHeld += 1
                i -= 1
            } else {
                break
            }
        }
        return consecutiveHeld >= 7
    }

    @ViewBuilder
    private func dayTooltip(checkIn: ChallengeCheckIn?) -> some View {
        if let ci = checkIn {
            Text(ci.didHold ? "$\(Int(ci.amountSaved)) saved" : "Slipped")
                .font(Typography.labelSmall)
                .foregroundStyle(ci.didHold ? Theme.gold : Theme.danger)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.modal, in: .capsule)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        } else {
            Text("No check-in")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.modal, in: .capsule)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        }
    }

    // MARK: - 6) Compare Button

    private var compareButton: some View {
        Button {
            showCompareSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                Text("Compare All")
            }
            .font(Typography.headingSmall)
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent.opacity(0.1), in: .rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Theme.accent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CoverShieldAnimation: View {
    @State private var phase: CGFloat = 0
    @State private var glowRadius: CGFloat = 4
    @State private var landed = false

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(Theme.accent.opacity(0.3 - Double(i) * 0.04))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: -20 + CGFloat(i) * 6,
                        y: sin(phase * .pi + CGFloat(i) * 0.5) * 10 - 15 + phase * 30
                    )
                    .opacity(phase > 0.2 ? max(0, 1 - Double(i) * 0.2) : 0)
            }

            Image(systemName: "shield.fill")
                .font(.system(size: landed ? 28 : 20))
                .foregroundStyle(Theme.accent)
                .shadow(color: Theme.accent.opacity(0.7), radius: glowRadius)
                .shadow(color: Theme.gold.opacity(0.4), radius: glowRadius * 1.5)
                .offset(y: -30 + phase * 50)
                .scaleEffect(landed ? 1.15 : 0.8 + phase * 0.2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                phase = 1
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                glowRadius = 12
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    landed = true
                }
            }
        }
    }
}

