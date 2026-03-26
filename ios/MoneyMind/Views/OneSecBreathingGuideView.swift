import SwiftUI

struct OneSecBreathingGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var completedSteps: Set<Int> = []
    @State private var expandedStep: Int? = 0

    private let breathGreen = Color(red: 0.2, green: 0.78, blue: 0.4)

    private let triggerApps = [
        ("DraftKings", "crown.fill"),
        ("FanDuel", "flag.fill"),
        ("BetMGM", "suit.spade.fill"),
        ("Amazon", "cart.fill"),
        ("eBay", "tag.fill"),
        ("Robinhood", "chart.line.uptrend.xyaxis"),
        ("Coinbase", "bitcoinsign.circle.fill"),
        ("Any App", "square.grid.2x2.fill")
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 24) {
                        heroSection
                        researchBadge
                        stepsSection
                        tipsSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button("Close") { dismiss() }
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            Text("Breathing Pause")
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Circle().fill(.clear).frame(width: 44, height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(breathGreen.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "lungs.fill")
                    .font(Typography.displayLarge)
                    .foregroundStyle(breathGreen)
            }

            VStack(spacing: 8) {
                Text("Add a Breathing Pause")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textPrimary)

                Text("Add a moment of reflection before opening tempting apps. Based on the One Sec method.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.top, 8)
    }

    private var researchBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal.fill")
                .font(Typography.headingLarge)
                .foregroundStyle(breathGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text("57% impulse reduction")
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)
                Text("Max-Planck Institute for Human Development")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(breathGreen.opacity(0.08), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(breathGreen.opacity(0.15), lineWidth: 1)
        )
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Setup Guide")
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textPrimary)

            SetupStepCard(
                number: 1,
                icon: "apps.iphone",
                title: "Open the Shortcuts App",
                description: "Find the Shortcuts app on your iPhone. It's pre-installed by Apple with a blue and red icon.",
                isCompleted: completedSteps.contains(1),
                isExpanded: expandedStep == 0,
                accentColor: breathGreen,
                onToggle: { toggleStep(0) },
                onComplete: { markComplete(1) }
            )

            SetupStepCard(
                number: 2,
                icon: "bolt.circle.fill",
                title: "Create a New Automation",
                description: "Tap the \"Automation\" tab at the bottom → tap \"+\" → select \"App\" as the trigger.",
                isCompleted: completedSteps.contains(2),
                isExpanded: expandedStep == 1,
                accentColor: breathGreen,
                onToggle: { toggleStep(1) },
                onComplete: { markComplete(2) }
            )

            SetupStepCard(
                number: 3,
                icon: "square.grid.2x2.fill",
                title: "Choose Your Trigger Apps",
                description: "Select the apps that tempt you. Tap \"Choose\" and search for any of these:",
                isCompleted: completedSteps.contains(3),
                isExpanded: expandedStep == 2,
                accentColor: breathGreen,
                onToggle: { toggleStep(2) },
                onComplete: { markComplete(3) },
                extraContent: AnyView(appChips)
            )

            SetupStepCard(
                number: 4,
                icon: "wind",
                title: "Add the Breathing Action",
                description: "For the action, choose \"Open App\" and select Splurj. When you open a trigger app, you'll be guided to take a breath first.",
                isCompleted: completedSteps.contains(4),
                isExpanded: expandedStep == 3,
                accentColor: breathGreen,
                onToggle: { toggleStep(3) },
                onComplete: { markComplete(4) }
            )

            SetupStepCard(
                number: 5,
                icon: "checkmark.seal.fill",
                title: "Set to Run Immediately",
                description: "Make sure \"Ask Before Running\" is turned OFF so the breathing pause happens automatically.",
                isCompleted: completedSteps.contains(5),
                isExpanded: expandedStep == 4,
                accentColor: breathGreen,
                onToggle: { toggleStep(4) },
                onComplete: { markComplete(5) }
            )
        }
    }

    private var appChips: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
            ForEach(triggerApps, id: \.0) { app in
                HStack(spacing: 6) {
                    Image(systemName: app.1)
                        .font(Typography.labelSmall)
                        .foregroundStyle(breathGreen)
                    Text(app.0)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Theme.cardSurface.opacity(0.8), in: .capsule)
                .overlay(
                    Capsule()
                        .strokeBorder(breathGreen.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Theme.gold)
                Text("Tips")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 10) {
                TipRow(text: "You can add any app — not just the ones listed above")
                TipRow(text: "The pause works even when you're on autopilot")
                TipRow(text: "You can always remove the automation later in Shortcuts")
            }
        }
        .padding(16)
        .splurjCard(.elevated)
    }

    private func toggleStep(_ index: Int) {
        withAnimation(.spring(response: 0.35)) {
            expandedStep = expandedStep == index ? nil : index
        }
    }

    private func markComplete(_ step: Int) {
        withAnimation(.spring(response: 0.3)) {
            completedSteps.insert(step)
            if step < 5 {
                expandedStep = step
            }
        }
    }
}

private struct SetupStepCard: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    let isCompleted: Bool
    let isExpanded: Bool
    let accentColor: Color
    let onToggle: () -> Void
    let onComplete: () -> Void
    var extraContent: AnyView? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 14) {
                    ZStack {
                        if isCompleted {
                            Circle()
                                .fill(Theme.accentGreen)
                                .frame(width: 32, height: 32)
                            Image(systemName: "checkmark")
                                .font(Typography.labelSmall)
                                .foregroundStyle(.white)
                        } else {
                            Circle()
                                .fill(accentColor.opacity(0.12))
                                .frame(width: 32, height: 32)
                            Text("\(number)")
                                .font(Typography.labelSmall)
                                .foregroundStyle(accentColor)
                        }
                    }

                    Text(title)
                        .font(Typography.headingSmall)
                        .foregroundStyle(isCompleted ? Theme.textSecondary : Theme.textPrimary)
                        .strikethrough(isCompleted)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary.opacity(0.5))
                }
            }
            .buttonStyle(.plain)
            .padding(16)

            if isExpanded && !isCompleted {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .font(Typography.displaySmall)
                            .foregroundStyle(accentColor)
                            .frame(width: 44, height: 44)
                            .background(accentColor.opacity(0.1), in: .rect(cornerRadius: 10))

                        Text(description)
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                            .lineSpacing(4)
                    }

                    if let extra = extraContent {
                        extra
                    }

                    Button(action: onComplete) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(Typography.labelSmall)
                            Text("Done")
                                .font(Typography.headingSmall)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(accentColor, in: .capsule)
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .medium))
                    .sensoryFeedback(.success, trigger: isCompleted)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .splurjCard(.elevated)
    }
}

private struct TipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.right.circle.fill")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.gold.opacity(0.7))
                .padding(.top, 2)
            Text(text)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
        }
    }
}
