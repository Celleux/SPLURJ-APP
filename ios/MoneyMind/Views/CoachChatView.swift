import SwiftUI
import SwiftData

struct CoachChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumManager.self) private var premiumManager
    @Query private var profiles: [UserProfile]
    @Query private var pgsiAssessments: [PGSIAssessment]
    @Query(filter: #Predicate<CoachInteraction> { $0.typeRaw == "curriculum" }, sort: \CoachInteraction.sessionNumber) private var curriculumSessions: [CoachInteraction]
    @State private var viewModel = CoachViewModel()
    @State private var inputText: String = ""
    @State private var showExercises = false
    @State private var showReferralGate = false
    @State private var referralDismissed = false
    @State private var showPaywall: Bool = false
    @FocusState private var inputFocused: Bool

    private var profile: UserProfile? { profiles.first }

    private var needsReferral: Bool {
        guard !referralDismissed else { return false }
        if let latest = pgsiAssessments.sorted(by: { $0.date > $1.date }).first {
            return latest.totalScore >= 15
        }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if needsReferral && !referralDismissed {
                    ReferralGateView(
                        onContinue: { referralDismissed = true },
                        onFindTherapist: {
                            if let url = URL(string: "https://findtreatment.samhsa.gov") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                } else if !viewModel.sessionActive && !viewModel.sessionEnded {
                    sessionStartView
                } else {
                    chatInterface
                }

                if viewModel.showCrisisOverlay {
                    CoachCrisisOverlay(
                        onDismiss: { viewModel.showCrisisOverlay = false }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(Theme.teal)
                        Text("Splurj Coach")
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if viewModel.sessionActive {
                            viewModel.endSession(modelContext: modelContext, profile: profile)
                        }
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.headingLarge)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                if viewModel.sessionActive {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            showExercises = true
                        } label: {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Theme.teal)
                        }
                        .accessibilityLabel("Exercises")
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showExercises) {
                CoachExercisesMenuView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            viewModel.checkAIAvailability()
            viewModel.countTodaySessions(modelContext: modelContext)
            viewModel.loadDailyMessageCount()
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var sessionStartView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.teal.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Theme.teal.opacity(0.06))
                        .frame(width: 140, height: 140)
                    Image(systemName: "brain.head.profile")
                        .font(Typography.displayLarge)
                        .foregroundStyle(Theme.teal)
                }

                Text("Splurj Coach")
                    .font(Typography.displayMedium)
                    .foregroundStyle(Theme.textPrimary)

                Text("A supportive space to explore your relationship with money. No judgment, just understanding.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                if viewModel.canStartSession {
                    Button {
                        viewModel.startSession(modelContext: modelContext)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "bubble.left.fill")
                            Text("Start Session")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.teal, in: .rect(cornerRadius: 14))
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                    .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.sessionActive)
                    .accessibilityLabel("Start coaching session")

                    Text("\(viewModel.sessionsRemaining) of \(viewModel.maxSessionsPerDay) sessions remaining today")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(Typography.displaySmall)
                            .foregroundStyle(Theme.textSecondary)
                        Text("You've used all 5 sessions today")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                        Text("Come back tomorrow for more coaching")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary.opacity(0.7))
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 24)

            if viewModel.sessionEnded {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.displaySmall)
                        .foregroundStyle(Theme.accentGreen)
                    Text("+25 XP earned")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.accentGreen)
                }
            }

            Spacer()
        }
    }

    private var chatInterface: some View {
        VStack(spacing: 0) {
            sessionTimerBar

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isTyping {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.isTyping) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
            }

            if viewModel.showPremiumPrompt {
                premiumSoftPrompt
            }

            if viewModel.hitFreeMessageLimit {
                messageLimitBanner
            } else if !viewModel.sessionEnded {
                inputBar
            } else {
                sessionEndedBar
            }
        }
    }

    private var sessionTimerBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.cardSurface)
                    .frame(height: 3)

                Rectangle()
                    .fill(Theme.teal)
                    .frame(width: geo.size.width * viewModel.sessionProgress, height: 3)
                    .animation(.linear(duration: 1), value: viewModel.sessionProgress)
            }
        }
        .frame(height: 3)
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .font(Typography.bodyMedium)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.cardSurface, in: .rect(cornerRadius: 22))
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.teal)
                .focused($inputFocused)
                .onSubmit {
                    sendCurrentMessage()
                }

            Button {
                sendCurrentMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(Typography.displayMedium)
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.textSecondary.opacity(0.3) : Theme.teal)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTyping)
            .sensoryFeedback(.impact(weight: .light), trigger: viewModel.messages.count)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.background)
    }

    private var sessionEndedBar: some View {
        HStack {
            Text("Session complete")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            if viewModel.canStartSession {
                Button("New Session") {
                    viewModel.startSession(modelContext: modelContext)
                }
                .font(Typography.headingSmall)
                .foregroundStyle(Theme.teal)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.cardSurface)
    }

    private var premiumSoftPrompt: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.gold)

            Text("Upgrade to Premium for unlimited coaching sessions.")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button {
                showPaywall = true
                viewModel.showPremiumPrompt = false
            } label: {
                Text("Upgrade")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.buttonTextOnAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.goldGradient, in: .capsule)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation { viewModel.showPremiumPrompt = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(12)
        .background(Theme.gold.opacity(0.08))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var messageLimitBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                Text("Daily free messages used")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
            }

            Text("You've used all \(viewModel.freeMessageLimit) free messages today. Upgrade to Premium for unlimited coaching.")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Unlock Unlimited Coaching")
                        .font(Typography.headingSmall)
                }
                .foregroundStyle(Theme.buttonTextOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.goldGradient, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Text("Resets tomorrow")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(16)
        .background(Theme.cardSurface)
    }

    private func sendCurrentMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        viewModel.sendMessage(text, modelContext: modelContext, profile: profile, completedSessions: curriculumSessions, hasPremium: premiumManager.hasFullAccess)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if viewModel.isTyping {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = viewModel.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

private struct MessageBubble: View {
    let message: DisplayMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.isDistortionFlag {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.gold)
                        Text("Thought Check")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.gold)
                    }
                }

                Text(message.content)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(bubbleTextColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground, in: bubbleShape)
                    .overlay(
                        message.isDistortionFlag
                            ? RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Theme.gold.opacity(0.3), lineWidth: 1)
                            : nil
                    )
            }

            if message.role != .user { Spacer(minLength: 60) }
        }
    }

    private var bubbleTextColor: Color {
        switch message.role {
        case .user: .white
        case .assistant: Theme.textPrimary
        case .system: Theme.textSecondary
        }
    }

    private var bubbleBackground: some ShapeStyle {
        switch message.role {
        case .user: AnyShapeStyle(Theme.teal)
        case .assistant: AnyShapeStyle(Theme.cardSurface)
        case .system: AnyShapeStyle(Theme.cardSurface.opacity(0.5))
        }
    }

    private var bubbleShape: UnevenRoundedRectangle {
        switch message.role {
        case .user:
            UnevenRoundedRectangle(
                topLeadingRadius: 16, bottomLeadingRadius: 16,
                bottomTrailingRadius: 4, topTrailingRadius: 16
            )
        case .assistant, .system:
            UnevenRoundedRectangle(
                topLeadingRadius: 16, bottomLeadingRadius: 4,
                bottomTrailingRadius: 16, topTrailingRadius: 16
            )
        }
    }
}

private struct TypingIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Theme.textSecondary.opacity(0.6))
                        .frame(width: 7, height: 7)
                        .offset(y: phase == index ? -4 : 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.cardSurface, in: UnevenRoundedRectangle(
                topLeadingRadius: 16, bottomLeadingRadius: 4,
                bottomTrailingRadius: 16, topTrailingRadius: 16
            ))

            Spacer(minLength: 60)
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0)) {
            phase = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                phase = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                phase = 2
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            animateDots()
        }
    }
}
