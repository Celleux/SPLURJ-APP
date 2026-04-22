import SwiftUI
import PhosphorSwift

struct CoachTabView: View {
    @State private var showCoachChat = false
    @State private var showUrgeSurf = false
    @State private var showCoolingOff = false
    @State private var showHALTCheck = false
    @State private var showExercises = false
    @State private var showEmergency = false
    @State private var showIntentions = false
    @State private var showOneSecGuide = false
    @State private var showDNSBlocking = false
    @State private var appeared = false
    @AppStorage("blockingEnabled") private var blockingEnabled = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(icon: "exclamationmark.shield.fill", title: "Right Now")
                        emergencyQuickAccess
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(icon: "calendar.badge.clock", title: "Plan Ahead")
                        impulseControlSection
                        if !blockingEnabled {
                            dnsBlockingCard
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(icon: "sparkles", title: "Reflect & Grow")
                        aiCoachCard
                    }

                    crisisSupportLink
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    appeared = true
                }
            }
            .fullScreenCover(isPresented: $showEmergency) { toolWrapper { EmergencyCrisisView() } dismissAction: { showEmergency = false } }
            .fullScreenCover(isPresented: $showUrgeSurf) { toolWrapper { UrgeSurfView() } dismissAction: { showUrgeSurf = false } }
            .fullScreenCover(isPresented: $showHALTCheck) { toolWrapper { HALTCheckView() } dismissAction: { showHALTCheck = false } }
            .fullScreenCover(isPresented: $showCoachChat) { toolWrapper { CoachChatView() } dismissAction: { showCoachChat = false } }
            .fullScreenCover(isPresented: $showCoolingOff) { toolWrapper { CoolingOffView() } dismissAction: { showCoolingOff = false } }
            .fullScreenCover(isPresented: $showIntentions) { toolWrapper { ImplementationIntentionsView() } dismissAction: { showIntentions = false } }
            .fullScreenCover(isPresented: $showOneSecGuide) { toolWrapper { OneSecBreathingGuideView() } dismissAction: { showOneSecGuide = false } }
            .fullScreenCover(isPresented: $showExercises) { toolWrapper { ACTExercisesView() } dismissAction: { showExercises = false } }
            .fullScreenCover(isPresented: $showDNSBlocking) { toolWrapper { DNSBlockingWizardView() } dismissAction: { showDNSBlocking = false } }
            .profileAvatarToolbar()
        }
    }

    // MARK: - Emergency Quick Access

    private var emergencyQuickAccess: some View {
        HStack(spacing: 10) {
            EmergencyButton(
                icon: "exclamationmark.shield.fill",
                title: "SOS",
                tint: Theme.danger,
                index: 0,
                appeared: appeared
            ) { showEmergency = true }

            EmergencyButton(
                icon: "wind",
                title: "Pause &\nBreathe",
                tint: Theme.accentSecondary,
                index: 1,
                appeared: appeared
            ) { showUrgeSurf = true }

            EmergencyButton(
                icon: "hand.raised.fill",
                title: "HALT\nCheck",
                tint: Theme.accent,
                index: 2,
                appeared: appeared
            ) { showHALTCheck = true }
        }
    }

    // MARK: - AI Coach Card

    private var aiCoachCard: some View {
        Button {
            showCoachChat = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.accentDim)
                        .frame(width: 56, height: 56)
                    PhIcon.chatDotsFill
                        .frame(width: 30, height: 30)
                        .foregroundStyle(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Money Coach")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Talk through what you're feeling")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                PhIcon.caretRight
                    .frame(width: 14, height: 14)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(18)
            .splurjCard(.hero)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: showCoachChat)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.2), value: appeared)
    }

    // MARK: - Impulse Control

    private var impulseControlSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: columns, spacing: 12) {
                CoachToolCard(
                    icon: "timer",
                    title: "Cool Down",
                    subtitle: "Wait it out with a countdown timer",
                    index: 3,
                    appeared: appeared
                ) { showCoolingOff = true }

                CoachToolCard(
                    icon: "lightbulb.fill",
                    title: "If-Then Plan",
                    subtitle: "Pre-set your response to triggers",
                    index: 4,
                    appeared: appeared
                ) { showIntentions = true }

                CoachToolCard(
                    icon: "lungs.fill",
                    title: "1-Second Rule",
                    subtitle: "Pause before opening tempting apps",
                    index: 5,
                    appeared: appeared
                ) { showOneSecGuide = true }

                CoachToolCard(
                    icon: "figure.mind.and.body",
                    title: "Exercises",
                    subtitle: "CBT & ACT techniques",
                    index: 6,
                    appeared: appeared
                ) { showExercises = true }
            }
        }
    }

    // MARK: - DNS Blocking

    private var dnsBlockingCard: some View {
        Button {
            showDNSBlocking = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 44, height: 44)
                    PhIcon.shieldFill
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Theme.iconOnAccent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Block Gambling Sites")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Set up DNS-level site blocking")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Text("+100 XP")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.accentDim, in: .capsule)
            }
            .padding(14)
            .splurjCard(.interactive)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: showDNSBlocking)
    }

    // MARK: - Crisis Support

    private var crisisSupportLink: some View {
        Button {
            showEmergency = true
        } label: {
            HStack(spacing: 6) {
                PhIcon.heartFill
                    .frame(width: 14, height: 14)
                Text("Need urgent help? Tap for immediate support")
                    .font(Typography.bodySmall)
                PhIcon.arrowRight
                    .frame(width: 14, height: 14)
            }
            .foregroundStyle(Theme.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: showEmergency)
    }

    // MARK: - Tool Wrapper

    private func toolWrapper<Content: View>(@ViewBuilder content: () -> Content, dismissAction: @escaping () -> Void) -> some View {
        NavigationStack {
            content()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismissAction()
                        } label: {
                            PhIcon.x
                                .frame(width: 16, height: 16)
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 30, height: 30)
                                .background(Theme.elevated, in: .circle)
                        }
                    }
                }
        }
    }
}

// MARK: - Emergency Button

private struct EmergencyButton: View {
    let icon: String
    let title: String
    let tint: Color
    let index: Int
    let appeared: Bool
    let action: () -> Void

    @State private var tapped = false

    var body: some View {
        Button {
            tapped.toggle()
            action()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.12), in: .rect(cornerRadius: 14))

                Text(title)
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .splurjCard(.interactive)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: tapped)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.06), value: appeared)
    }
}

// MARK: - Coach Tool Card

private struct CoachToolCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let index: Int
    let appeared: Bool
    let action: () -> Void

    @State private var tapped = false

    var body: some View {
        Button {
            tapped.toggle()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(Typography.headingLarge)
                    .foregroundStyle(Theme.iconOnAccent)
                    .frame(width: 40, height: 40)
                    .background(Theme.accent, in: .rect(cornerRadius: 10))

                Text(title)
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)

                Text(subtitle)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .splurjCard(.interactive)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: tapped)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.06), value: appeared)
    }
}
