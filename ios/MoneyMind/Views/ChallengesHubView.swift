import SwiftUI
import SwiftData

struct PactsView: View {
    @Query private var challenges: [SavingsChallenge]
    @Query private var profiles: [UserProfile]
    @Query private var quizResults: [QuizResult]
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumManager.self) private var premiumManager
    @State private var vm = ChallengesViewModel()
    @State private var selectedType: ChallengeType?
    @State private var activeChallenge: SavingsChallenge?
    @State private var appeared = false
    @State private var showPaywall: Bool = false
    @State private var joinCode: String = ""

    private var profile: UserProfile? { profiles.first }

    private var personality: MoneyPersonality {
        quizResults.first?.personality ?? .builder
    }

    private var activeChallenges: [SavingsChallenge] {
        challenges.filter { $0.isActive }
    }

    private var isAtFreeLimit: Bool {
        !premiumManager.hasFullAccess && activeChallenges.count >= 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    joinPactSection

                    if activeChallenges.isEmpty {
                        emptyStateCard
                            .transition(.scale.combined(with: .opacity))
                    }

                    if !activeChallenges.isEmpty {
                        activeChallengesSection
                    }

                    availableChallengesSection

                    if isAtFreeLimit {
                        premiumUpsellCard
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 80)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Pacts")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(item: $activeChallenge) { challenge in
                challengeDestination(challenge)
            }
            .overlay {
                if vm.showCelebration {
                    ChallengesCelebrationOverlay(
                        message: vm.celebrationMessage,
                        particles: vm.confettiParticles
                    ) {
                        vm.showCelebration = false
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    appeared = true
                }
            }
            .onChange(of: vm.joinState) { _, newValue in
                if case .joined = newValue {
                    joinCode = ""
                }
            }
        }
    }

    private var joinPactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .foregroundStyle(Theme.accent)
                Text("Join a Pact")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
            }

            HStack(spacing: 10) {
                TextField("Enter 6-digit code", text: $joinCode)
                    .font(.system(.body, design: .monospaced))
                    .textCase(.uppercase)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Theme.elevated, in: .rect(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Theme.border, lineWidth: 0.5)
                    )
                    .onChange(of: joinCode) { _, _ in
                        if case .error = vm.joinState { vm.resetJoinState() }
                    }

                Button {
                    Task { await vm.joinChallenge(code: joinCode, context: modelContext) }
                } label: {
                    Group {
                        if vm.joinState == .joining {
                            ProgressView()
                                .tint(Theme.buttonTextOnAccent)
                        } else {
                            Text("Join")
                                .font(Typography.headingSmall)
                                .foregroundStyle(Theme.buttonTextOnAccent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.accentGradient, in: .rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(joinCode.count < 6 || vm.joinState == .joining)
                .opacity(joinCode.count < 6 ? 0.5 : 1)
            }

            joinStateMessage
        }
    }

    @ViewBuilder
    private var joinStateMessage: some View {
        switch vm.joinState {
        case .idle, .joining:
            EmptyView()
        case .joined(let title):
            Label("Joined \(title)", systemImage: "checkmark.seal.fill")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.success)
                .padding(.top, 2)
        case .error(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.warning)
                .padding(.top, 2)
        }
    }

    private var emptyStateCard: some View {
        PersonalityEmptyStateView(
            personality: personality,
            icon: "trophy.fill",
            secondaryIcon: "flag.fill",
            headline: "Start a Pact",
            subtext: "Start a Pact with friends to\nsave money together"
        )
        .frame(height: 340)
    }

    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(icon: "flame.fill", title: "Active Pacts")

            ForEach(activeChallenges) { challenge in
                ActiveChallengeCard(
                    challenge: challenge,
                    personalityColor: personality.color
                ) {
                    activeChallenge = challenge
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)
            }
        }
    }

    private var availableChallengesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(icon: "star.fill", title: "Available Pacts")

            ForEach(Array(ChallengeType.allCases.enumerated()), id: \.element) { index, type in
                let alreadyActive = activeChallenges.contains { $0.challengeType == type }
                ChallengePickerCard(type: type, isAlreadyActive: alreadyActive, isLocked: isAtFreeLimit && !alreadyActive) {
                    if isAtFreeLimit && !alreadyActive {
                        showPaywall = true
                    } else if !alreadyActive {
                        withAnimation(Theme.spring) {
                            vm.startChallenge(type: type, context: modelContext, creator: profile)
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15 + Double(index) * 0.08), value: appeared)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: vm.hapticTrigger)
    }

    private var premiumUpsellCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                Text("Want more pacts?")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            Text("Free users can run 1 pact at a time. Upgrade to Premium for unlimited simultaneous pacts.")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Unlock Unlimited Pacts")
                        .font(Typography.headingSmall)
                }
                .foregroundStyle(Theme.buttonTextOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.goldGradient, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .splurjCard(.elevated)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    @ViewBuilder
    private func challengeDestination(_ challenge: SavingsChallenge) -> some View {
        switch challenge.challengeType {
        case .envelope100:
            EnvelopeDetailCard(challenge: challenge, vm: vm, personalityColor: personality.color)
        case .week52:
            WeekSavingsView(challenge: challenge, vm: vm, personalityColor: personality.color)
        case .noSpend:
            NoSpendChallengeView(challenge: challenge, vm: vm, personalityColor: personality.color)
        case .roundUp:
            RoundUpDetailCard(challenge: challenge, vm: vm, personalityColor: personality.color)
        }
    }
}

private struct EnvelopeDetailCard: View {
    @Bindable var challenge: SavingsChallenge
    @Bindable var vm: ChallengesViewModel
    let personalityColor: Color
    @Environment(\.dismiss) private var dismiss
    @State private var flippedEnvelope: Int?
    @State private var shareTrigger = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 10)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    HStack(spacing: 20) {
                        MMProgressRing(progress: challenge.progress, lineWidth: 8, size: 90)
                            .overlay {
                                VStack(spacing: 2) {
                                    Text("\(challenge.completedItems.count)")
                                        .font(Typography.displaySmall)
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("of 100")
                                        .font(Typography.labelSmall)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }

                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Total Saved")
                                    .font(Typography.labelSmall)
                                    .foregroundStyle(Theme.textSecondary)
                                Text("$\(Int(challenge.totalSaved))")
                                    .font(Typography.displayMedium)
                                    .foregroundStyle(personalityColor)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Remaining")
                                    .font(Typography.labelSmall)
                                    .foregroundStyle(Theme.textSecondary)
                                Text("$\(Int(5050 - challenge.totalSaved))")
                                    .font(Typography.headingSmall)
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }

                        Spacer()
                    }
                    .padding(20)
                    .splurjCard(.hero)
                    .padding(.top, 8)

                    if let suggested = challenge.dailySuggestedEnvelope {
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .font(Typography.headingLarge)
                                .foregroundStyle(Theme.gold)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Today's Suggestion")
                                    .font(Typography.labelSmall)
                                    .foregroundStyle(Theme.textSecondary)
                                Text("Save $\(suggested) \u{2014} tap envelope #\(suggested)")
                                    .font(Typography.bodyMedium)
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            LinearGradient(
                                colors: [Theme.gold.opacity(0.08), Theme.card],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: .rect(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Theme.gold.opacity(0.15), lineWidth: 1)
                        )
                    }

                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(1...100, id: \.self) { number in
                            let isCompleted = challenge.completedItems.contains(number)
                            let isSuggested = challenge.dailySuggestedEnvelope == number
                            Button {
                                guard !isCompleted else { return }
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                    flippedEnvelope = number
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        vm.markEnvelope(number, challenge: challenge)
                                        flippedEnvelope = nil
                                    }
                                }
                            } label: {
                                ZStack {
                                    if isCompleted {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(personalityColor.opacity(0.25))
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(personalityColor.opacity(0.5), lineWidth: 1)
                                        Text("\(number)")
                                            .font(Typography.labelSmall)
                                            .foregroundStyle(personalityColor)
                                    } else {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(isSuggested ? Theme.gold.opacity(0.12) : Theme.elevated)
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(
                                                isSuggested ? Theme.gold.opacity(0.4) : Theme.border,
                                                lineWidth: isSuggested ? 1.5 : 0.5
                                            )
                                        Text("\(number)")
                                            .font(Typography.labelSmall)
                                            .foregroundStyle(isSuggested ? Theme.gold : Theme.textMuted)
                                    }
                                }
                                .frame(height: 32)
                                .rotation3DEffect(
                                    .degrees(flippedEnvelope == number ? 180 : 0),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isCompleted)
                            .accessibilityLabel("Envelope \(number), \(isCompleted ? "saved" : "available")")
                        }
                    }

                    Button {
                        shareTrigger = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Progress")
                        }
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent.opacity(0.1), in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .secondary, size: .medium))
                    .sheet(isPresented: $shareTrigger) {
                        let text = vm.shareChallenge(challenge)
                        ShareSheetView(items: [text])
                            .presentationDetents([.medium])
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 80)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("100 Envelopes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.headingLarge)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .overlay {
                if vm.showCelebration {
                    ChallengesCelebrationOverlay(
                        message: vm.celebrationMessage,
                        particles: vm.confettiParticles
                    ) {
                        vm.showCelebration = false
                    }
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: vm.hapticTrigger)
        }
    }
}

private struct RoundUpDetailCard: View {
    @Bindable var challenge: SavingsChallenge
    @Bindable var vm: ChallengesViewModel
    let personalityColor: Color
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Environment(\.dismiss) private var dismiss
    @State private var piggyScale: CGFloat = 1.0
    @State private var shareTrigger = false

    private var roundUpTransactions: [(String, Double, Date)] {
        transactions
            .filter { $0.transactionType == .expense }
            .compactMap { tx in
                let rounded = ceil(tx.amount)
                let diff = rounded - tx.amount
                guard diff > 0.001 else { return nil }
                return (tx.note.isEmpty ? tx.category : tx.note, diff, tx.date)
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(personalityColor.opacity(0.06))
                                .frame(width: 160, height: 160)
                            Circle()
                                .fill(personalityColor.opacity(0.1))
                                .frame(width: 120, height: 120)
                            Image(systemName: "dollarsign.circle.fill")
                                .font(Typography.displayLarge)
                                .foregroundStyle(personalityColor)
                                .scaleEffect(piggyScale)
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                piggyScale = 1.06
                            }
                        }

                        VStack(spacing: 6) {
                            Text("$\(String(format: "%.2f", challenge.roundUpTotal))")
                                .font(Typography.displayMedium)
                                .foregroundStyle(personalityColor)
                            Text("saved from round-ups")
                                .font(Typography.bodyMedium)
                                .foregroundStyle(Theme.textSecondary)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Theme.elevated)
                                    .frame(height: 10)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [personalityColor, Theme.secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * min(1.0, challenge.roundUpTotal / 100.0), height: 10)
                            }
                        }
                        .frame(height: 10)

                        let milestones = [10, 25, 50, 100, 250, 500, 1000]
                        let nextMilestone = milestones.first(where: { Double($0) > challenge.roundUpTotal }) ?? 1000
                        HStack {
                            Text("$0")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textMuted)
                            Spacer()
                            Text("Next milestone: $\(nextMilestone)")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .padding(24)
                    .splurjCard(.hero)
                    .padding(.top, 8)

                    HStack(spacing: 0) {
                        statItem(value: "\(challenge.daysActive)", label: "Days Active", icon: "clock.fill")
                        Divider().frame(height: 32).background(Theme.textSecondary.opacity(0.2))
                        statItem(value: "\(roundUpTransactions.count)", label: "Round-Ups", icon: "arrow.up.circle.fill")
                        Divider().frame(height: 32).background(Theme.textSecondary.opacity(0.2))
                        let avg = roundUpTransactions.isEmpty ? 0 : challenge.roundUpTotal / Double(roundUpTransactions.count)
                        statItem(value: String(format: "$%.2f", avg), label: "Avg Round-Up", icon: "chart.bar.fill")
                    }
                    .padding(16)
                    .splurjCard(.elevated)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Round-Ups")
                                .font(Typography.headingMedium)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("\(roundUpTransactions.count) total")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.textSecondary)
                        }

                        if roundUpTransactions.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(Typography.displayMedium)
                                    .foregroundStyle(Theme.textMuted)
                                Text("Add expense transactions\nand round-ups will appear here")
                                    .font(Typography.bodyMedium)
                                    .foregroundStyle(Theme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(32)
                        } else {
                            ForEach(Array(roundUpTransactions.prefix(15).enumerated()), id: \.offset) { _, item in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(personalityColor.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            Image(systemName: "arrow.up.circle.fill")
                                                .font(Typography.labelLarge)
                                                .foregroundStyle(personalityColor)
                                        }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.0)
                                            .font(Typography.bodyMedium)
                                            .foregroundStyle(Theme.textPrimary)
                                            .lineLimit(1)
                                        Text(item.2, style: .relative)
                                            .font(Typography.labelSmall)
                                            .foregroundStyle(Theme.textMuted)
                                    }
                                    Spacer()
                                    Text("+$\(String(format: "%.2f", item.1))")
                                        .font(Typography.headingSmall)
                                        .foregroundStyle(Theme.success)
                                }
                                .padding(12)
                                .background(Theme.elevated.opacity(0.5), in: .rect(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(16)
                    .splurjCard(.elevated)

                    Button {
                        shareTrigger = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Progress")
                        }
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent.opacity(0.1), in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .secondary, size: .medium))
                    .sheet(isPresented: $shareTrigger) {
                        let text = vm.shareChallenge(challenge)
                        ShareSheetView(items: [text])
                            .presentationDetents([.medium])
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 80)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Round-Up Race")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.headingLarge)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        syncRoundUps()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(Typography.headingSmall)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .overlay {
                if vm.showCelebration {
                    ChallengesCelebrationOverlay(
                        message: vm.celebrationMessage,
                        particles: vm.confettiParticles
                    ) {
                        vm.showCelebration = false
                    }
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: vm.hapticTrigger)
            .onAppear { syncRoundUps() }
        }
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(Typography.labelSmall)
                .foregroundStyle(personalityColor)
            Text(value)
                .font(Typography.headingSmall)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func syncRoundUps() {
        var newTotal: Double = 0
        for tx in transactions where tx.transactionType == .expense {
            let rounded = ceil(tx.amount)
            let diff = rounded - tx.amount
            if diff > 0.001 {
                newTotal += diff
            }
        }
        if abs(newTotal - challenge.roundUpTotal) > 0.001 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                challenge.roundUpTotal = newTotal
                challenge.totalSaved = newTotal
            }
        }
    }
}

private struct ActiveChallengeCard: View {
    let challenge: SavingsChallenge
    let personalityColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                MMProgressRing(progress: challenge.progress, lineWidth: 6, size: 60)
                    .overlay {
                        Image(systemName: challenge.challengeType.icon)
                            .font(Typography.bodyLarge)
                            .foregroundStyle(personalityColor)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(challenge.challengeType.title)
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        Label("\(challenge.daysActive)d", systemImage: "clock.fill")
                        if challenge.challengeType != .noSpend {
                            Label("$\(Int(challenge.totalSaved))", systemImage: "dollarsign.circle.fill")
                        } else {
                            Label("\(challenge.noSpendStreak) streak", systemImage: "flame.fill")
                        }
                    }
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.elevated)
                                .frame(height: 4)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [personalityColor, Theme.secondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * challenge.progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                }

                Image(systemName: "chevron.right")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary.opacity(0.4))
            }
            .padding(16)
            .splurjCard(.interactive)
        }
        .buttonStyle(.plain)
    }
}

private struct ChallengePickerCard: View {
    let type: ChallengeType
    let isAlreadyActive: Bool
    var isLocked: Bool = false
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: type.icon)
                        .font(Typography.headingLarge)
                        .foregroundStyle(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(type.title)
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textPrimary)
                    Text(type.subtitle)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 16) {
                Label(type.durationLabel, systemImage: "clock")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)

                HStack(spacing: 2) {
                    ForEach(0..<type.difficulty, id: \.self) { _ in
                        Text("🔥")
                            .font(Typography.labelSmall)
                    }
                }

                if type.totalGoal > 0 {
                    Text("$\(Int(type.totalGoal))")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.success)
                }

                Spacer()

                if isAlreadyActive {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Active")
                    }
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.success)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.success.opacity(0.12), in: .capsule)
                } else if isLocked {
                    Button(action: action) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text("PRO")
                        }
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.gold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Theme.gold.opacity(0.12), in: .capsule)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: action) {
                        Text("Start")
                            .font(Typography.labelSmall)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Theme.accent, in: .capsule)
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .small))
                }
            }
        }
        .padding(16)
        .splurjCard(.elevated)
    }
}
