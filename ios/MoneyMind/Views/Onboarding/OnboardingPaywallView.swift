import SwiftUI
import SwiftData
import PhosphorSwift

struct OnboardingPaywallView: View {
    let dna: FinancialDNA
    let onComplete: () -> Void

    @Environment(PremiumManager.self) private var premiumManager
    @State private var selectedPlan: PlanType = .annual
    @State private var appeared: Bool = false
    @State private var closeVisible: Bool = false
    @State private var ctaPulse: Bool = false
    @State private var ctaTapped: Bool = false
    @State private var planTapped: Bool = false

    private var archetype: FinancialArchetype { dna.primaryArchetype }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    hero
                    dnaCard
                        .padding(.top, -12)
                    planSelector
                        .padding(.top, 28)
                    featureList
                        .padding(.top, 28)
                    trustRow
                        .padding(.top, 24)
                    Spacer().frame(height: 160)
                }
            }
            .scrollIndicators(.hidden)

            stickyFooter

            if closeVisible {
                skipButton
                    .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            startCTAPulse()
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeOut(duration: 0.4)) { closeVisible = true }
            }
        }
    }

    // MARK: - Skip

    private var skipButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    onComplete()
                } label: {
                    Text("Skip")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.elevated.opacity(0.8), in: Capsule())
                }
                .padding(.top, 12)
                .padding(.trailing, 20)
            }
            Spacer()
        }
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    Theme.background, Theme.background, Theme.background,
                    archetype.color.opacity(0.06), Theme.background, Theme.accent.opacity(0.04),
                    Theme.background, archetype.color.opacity(0.03), Theme.background
                ]
            )
            .frame(height: 320)
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer().frame(height: 56)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [archetype.color.opacity(0.2), archetype.color.opacity(0.04), .clear],
                                center: .center,
                                startRadius: 8,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [archetype.color.opacity(0.4), archetype.color.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 84, height: 84)

                    Image(systemName: archetype.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(archetype.color)
                        .shadow(color: archetype.color.opacity(0.5), radius: 10)
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)

                VStack(spacing: 8) {
                    Text("Your \(archetype.rawValue)\nRecovery Plan is Ready")
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("Unlock tools designed for your financial DNA")
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Theme.textSecondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
            .padding(.bottom, 32)
        }
        .frame(height: 320)
    }

    // MARK: - DNA Card

    private var dnaCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "dna")
                    .font(Typography.labelSmall)
                    .foregroundStyle(archetype.color)
                Text("YOUR RESULT")
                    .font(Typography.labelSmall)
                    .foregroundStyle(archetype.color)
                    .tracking(2)
                Spacer()
            }

            HStack(spacing: 14) {
                Image(systemName: archetype.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(archetype.color)
                    .frame(width: 48, height: 48)
                    .background(archetype.color.opacity(0.12), in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(archetype.rawValue)
                        .font(Typography.headingMedium)
                        .foregroundStyle(.white)
                    Text(archetype.tagline)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    axisDot(value: dna.spendingAxis, color: Theme.accent)
                    axisDot(value: dna.emotionalAxis, color: Theme.axisEmotional)
                    axisDot(value: dna.riskAxis, color: Theme.axisRisk)
                    axisDot(value: dna.socialAxis, color: Theme.axisSocial)
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(archetype.color.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.15), value: appeared)
    }

    private func axisDot(value: Double, color: Color) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.elevated)
                .frame(width: 4, height: 24)
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: 24 * max(0.1, value))
        }
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        VStack(spacing: 14) {
            annualPlanCard
            monthlyPlanCard
            lifetimeLink
        }
        .padding(.horizontal, 20)
        .sensoryFeedback(.selection, trigger: planTapped)
    }

    private var annualPlanCard: some View {
        let isSelected = selectedPlan == .annual
        return Button {
            withAnimation(Theme.springSnappy) { selectedPlan = .annual }
            planTapped.toggle()
        } label: {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .strokeBorder(isSelected ? Theme.accent : Theme.border, lineWidth: isSelected ? 2 : 1.5)
                            .frame(width: 22, height: 22)
                        if isSelected {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 12, height: 12)
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Annual")
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.textPrimary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$9.99/mo")
                                .font(Typography.bodySmall)
                                .strikethrough(true, color: Theme.textMuted)
                                .foregroundStyle(Theme.textMuted)
                            Text("$5.00")
                                .font(Typography.moneyMedium)
                                .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                            Text("/month")
                                .font(Typography.bodySmall)
                                .foregroundStyle(Theme.textMuted)
                        }
                        Text("Billed $59.99/year")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected
                              ? LinearGradient(colors: [Theme.elevated, Theme.surface], startPoint: .topLeading, endPoint: .bottomTrailing)
                              : LinearGradient(colors: [Theme.surface, Theme.surface], startPoint: .top, endPoint: .bottom)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ? Theme.accent.opacity(0.5) : Theme.border,
                            lineWidth: isSelected ? 1.5 : 0.5
                        )
                )
                .shadow(color: isSelected ? Theme.accent.opacity(0.12) : .clear, radius: 16, y: 6)

                Text("SAVE 50%")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Theme.buttonTextOnAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.goldGradient, in: .capsule)
                    .offset(x: -12, y: -10)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .animation(Theme.springSnappy, value: isSelected)
    }

    private var monthlyPlanCard: some View {
        let isSelected = selectedPlan == .monthly
        return Button {
            withAnimation(Theme.springSnappy) { selectedPlan = .monthly }
            planTapped.toggle()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Theme.accent : Theme.border, lineWidth: isSelected ? 2 : 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Monthly")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.textPrimary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$9.99")
                            .font(Typography.moneyMedium)
                            .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                        Text("/month")
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Theme.accent.opacity(0.5) : Theme.border,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .animation(Theme.springSnappy, value: isSelected)
    }

    private var lifetimeLink: some View {
        Button {
            withAnimation(Theme.springSnappy) { selectedPlan = .lifetime }
            planTapped.toggle()
        } label: {
            Text("Or get lifetime access for $149.99")
                .font(Typography.bodySmall)
                .foregroundStyle(selectedPlan == .lifetime ? Theme.accent : Theme.textMuted)
                .underline(selectedPlan == .lifetime, color: Theme.accent)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }



    // MARK: - Features

    private var featureList: some View {
        VStack(spacing: 16) {
            Text("Built for \(archetype.rawValue.replacingOccurrences(of: "The ", with: "")) types")
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            VStack(spacing: 2) {
                ForEach(Array(personalizedFeatures.enumerated()), id: \.offset) { index, feature in
                    HStack(spacing: 14) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(feature.tint)
                            .frame(width: 36, height: 36)
                            .background(feature.tint.opacity(0.12), in: .rect(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.name)
                                .font(Typography.headingSmall)
                                .foregroundStyle(Theme.textPrimary)
                            Text(feature.subtitle)
                                .font(Typography.bodySmall)
                                .foregroundStyle(Theme.textSecondary)
                        }

                        Spacer()

                        PhIcon.checkCircleFill
                            .frame(width: 18, height: 18)
                            .foregroundStyle(Theme.accent.opacity(0.5))
                    }
                    .padding(.vertical, 12)
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : -20)
                    .animation(.spring(response: 0.5).delay(0.3 + Double(index) * 0.08), value: appeared)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var personalizedFeatures: [(icon: String, name: String, subtitle: String, tint: Color)] {
        let base: [(icon: String, name: String, subtitle: String, tint: Color)] = [
            ("sparkles", "Full Splurj Wrapped", "Monthly & annual story recaps", Theme.accent),
            ("chart.bar.xaxis.ascending", "Premium Analytics", "Deep spending insights & trends", Theme.accent),
            ("bolt.shield.fill", "Ad-Free Experience", "Zero interruptions, full focus", Theme.accent),
        ]

        let archetypeSpecific: [(icon: String, name: String, subtitle: String, tint: Color)]
        switch archetype {
        case .guardian:
            archetypeSpecific = [
                ("shield.lefthalf.filled", "Guardian Shield Mode", "Advanced impulse defense tools", archetype.color),
                ("lock.fill", "Emergency Fund Tracker", "Watch your safety net grow", archetype.color),
            ]
        case .strategist:
            archetypeSpecific = [
                ("brain.head.profile.fill", "Deep Pattern Analysis", "AI-powered spending optimization", archetype.color),
                ("chart.line.uptrend.xyaxis", "Advanced Forecasting", "Predictive budget modeling", archetype.color),
            ]
        case .adventurer:
            archetypeSpecific = [
                ("dollarsign.arrow.circlepath", "Fun Fund Builder", "Adventure without guilt", archetype.color),
                ("gamecontroller.fill", "Unlimited Challenges", "Access every savings quest", archetype.color),
            ]
        case .empath:
            archetypeSpecific = [
                ("person.2.fill", "Couple Mode", "Shared budgets & goals with a partner", archetype.color),
                ("hand.raised.fill", "Boundary Builder", "Tools to protect your generosity", archetype.color),
            ]
        case .visionary:
            archetypeSpecific = [
                ("lightbulb.fill", "Income Growth Quests", "Side hustle & opportunity tracking", archetype.color),
                ("scope", "Vision Board", "Track your bold bets & investments", archetype.color),
            ]
        }

        return archetypeSpecific + base
    }

    // MARK: - Trust

    private var trustRow: some View {
        HStack(spacing: 24) {
            trustBadge(icon: "lock.fill", text: "Cancel\nanytime")
            trustBadge(icon: "shield.checkered", text: "Money-back\nguarantee")
            trustBadge(icon: "hand.raised.fill", text: "No hidden\nfees")
        }
        .padding(.horizontal, 20)
    }

    private func trustBadge(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Theme.textMuted)
            Text(text)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sticky Footer

    private var stickyFooter: some View {
        VStack(spacing: 8) {
            Button {
                ctaTapped.toggle()
                HapticManager.notification(.success)
                premiumManager.unlock()
                onComplete()
            } label: {
                Text("Start Free Trial")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.buttonTextOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.goldGradient, in: .rect(cornerRadius: 16))
                    .shadow(color: Theme.accent.opacity(0.3), radius: 12, y: 4)
                    .scaleEffect(ctaPulse ? 1.02 : 1.0)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .medium), trigger: ctaTapped)

            Text(footerPriceText)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)

            Button {
                premiumManager.restore()
            } label: {
                Text("Restore Purchases")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [Theme.background.opacity(0), Theme.background, Theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var footerPriceText: String {
        switch selectedPlan {
        case .annual:
            return "7-day free trial, then $59.99/year ($5.00/mo)"
        case .monthly:
            return "7-day free trial, then $9.99/month"
        case .lifetime:
            return "One-time payment of $149.99"
        }
    }

    private func startCTAPulse() {
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(1.0)) {
            ctaPulse = true
        }
    }
}
