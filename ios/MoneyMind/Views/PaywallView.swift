import SwiftUI
import SwiftData
import PhosphorSwift

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PremiumManager.self) private var premiumManager
    @Query private var quizResults: [QuizResult]
    @Query private var profiles: [UserProfile]
    @Query private var impulseLogs: [ImpulseLog]
    @State private var selectedPlan: PlanType = .annual
    @State private var ctaTapped: Bool = false
    @State private var planTapped: Bool = false
    @State private var appeared: Bool = false
    @State private var featuresRevealed: [Bool] = Array(repeating: false, count: 6)
    @State private var ctaPulse: Bool = false

    private var profile: UserProfile? { profiles.first }
    private var latestQuiz: QuizResult? { quizResults.first }
    private var currencySymbol: String { profile?.currencySymbol ?? "$" }

    private var totalSaved: Double {
        impulseLogs.reduce(0) { $0 + $1.amount }
    }

    private var hasMeaningfulSavings: Bool {
        totalSaved >= 1.0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroArea
                    statsRibbon
                        .padding(.top, -20)
                    roiFraming
                        .padding(.top, 24)
                    planSelector
                        .padding(.top, 32)
                    featureShowcase
                        .padding(.top, 32)
                    trustIndicators
                        .padding(.top, 28)
                    Spacer().frame(height: 160)
                }
            }
            .scrollIndicators(.hidden)

            stickyFooter

            closeButton
        }
        .interactiveDismissDisabled()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            revealFeatures()
            startCTAPulse()
        }
    }

    // MARK: - Close

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    PhIcon.x
                        .frame(width: 14, height: 14)
                        .foregroundStyle(Theme.textMuted)
                        .frame(width: 30, height: 30)
                        .background(Theme.elevated.opacity(0.8), in: .circle)
                }
                .padding(.top, 12)
                .padding(.trailing, 20)
            }
            Spacer()
        }
    }

    // MARK: - Hero

    private var heroArea: some View {
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
                    Theme.accent.opacity(0.06), Theme.background, Theme.accent.opacity(0.03),
                    Theme.background, Theme.gold.opacity(0.04), Theme.background
                ]
            )
            .frame(height: 380)
            .ignoresSafeArea()

            SplurjSwoosh()
                .fill(Theme.accent.opacity(0.04))
                .frame(height: 380)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 20) {
                Spacer().frame(height: 60)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.accent.opacity(0.15), Theme.accent.opacity(0.03), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.3), Theme.accent.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 100, height: 100)

                    PhIcon.crownFill
                        .frame(width: 40, height: 40)
                        .foregroundStyle(Theme.accent)
                        .shadow(color: Theme.accent.opacity(0.5), radius: 12)
                }
                .holographicSheen(isActive: appeared)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)

                VStack(spacing: 10) {
                    Text("Unlock Your\nFull Potential")
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("Everything you need to master your money")
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Theme.textSecondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
            .padding(.bottom, 40)
        }
        .frame(height: 380)
    }

    // MARK: - Stats Ribbon

    private var statsRibbon: some View {
        HStack(spacing: 0) {
            statPill(
                icon: PhIcon.piggyBankFill,
                value: "\(currencySymbol)\(Int(totalSaved))",
                label: "Saved"
            )
            Rectangle()
                .fill(Theme.border)
                .frame(width: 1, height: 32)
            statPill(
                icon: PhIcon.fireFill,
                value: "\(impulseLogs.count)",
                label: "Wins"
            )
            Rectangle()
                .fill(Theme.border)
                .frame(width: 1, height: 32)
            statPill(
                icon: PhIcon.starFill,
                value: "4.8",
                label: "Rating"
            )
        }
        .padding(.vertical, 14)
        .background(Theme.surface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.border.opacity(0.5), lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.15), value: appeared)
    }

    private func statPill(icon: Image, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                icon
                    .frame(width: 14, height: 14)
                    .foregroundStyle(Theme.accent)
                Text(value)
                    .font(Typography.moneySmall)
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
            }
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
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
                                .foregroundStyle(Theme.accent)
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

    private var roiFraming: some View {
        Group {
            if hasMeaningfulSavings {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.accent)

                    Text("You already saved \(currencySymbol)\(Int(totalSaved)) — MoneyMind costs less than one impulse purchase.")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(Theme.accent.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.accent.opacity(0.15), lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Feature Showcase

    private var featureShowcase: some View {
        VStack(spacing: 20) {
            Text("Everything in Premium")
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            VStack(spacing: 2) {
                ForEach(Array(premiumFeatures.enumerated()), id: \.offset) { index, feature in
                    featureRow(feature, index: index)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func featureRow(_ feature: PremiumFeature, index: Int) -> some View {
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
        .opacity(featuresRevealed[safe: index] == true ? 1 : 0)
        .offset(x: featuresRevealed[safe: index] == true ? 0 : -30)
    }

    // MARK: - Trust

    private var trustIndicators: some View {
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

    // MARK: - Helpers

    private func revealFeatures() {
        for i in 0..<premiumFeatures.count {
            withAnimation(Theme.spring.delay(Double(i) * 0.1 + 0.4)) {
                if i < featuresRevealed.count {
                    featuresRevealed[i] = true
                }
            }
        }
    }

    private func startCTAPulse() {
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(1.0)) {
            ctaPulse = true
        }
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

    // MARK: - Data

    private let premiumFeatures: [PremiumFeature] = [
        PremiumFeature(icon: "sparkles", name: "Full Splurj Wrapped", subtitle: "Monthly & annual story recaps", tint: Theme.accent),
        PremiumFeature(icon: "eye.slash.fill", name: "Ghost Budget", subtitle: "Hidden budgets only you can see", tint: Theme.accentTertiary),
        PremiumFeature(icon: "trophy.fill", name: "Unlimited Pacts", subtitle: "Access every savings pact", tint: Theme.accent),
        PremiumFeature(icon: "chart.bar.xaxis.ascending", name: "Premium Analytics", subtitle: "Deep spending insights & trends", tint: Theme.accent),
        PremiumFeature(icon: "person.2.fill", name: "Couple Mode", subtitle: "Shared budgets & goals with a partner", tint: Theme.accentTertiary),
        PremiumFeature(icon: "bolt.shield.fill", name: "Ad-Free Experience", subtitle: "Zero interruptions, full focus", tint: Theme.accent)
    ]
}

nonisolated enum PlanType: Sendable {
    case monthly, annual, lifetime
}

private struct PremiumFeature {
    let icon: String
    let name: String
    let subtitle: String
    var tint: Color = Theme.accent
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
