import SwiftUI
import SwiftData
import UserNotifications

struct LaunchScreenView: View {
    let dna: FinancialDNA
    let modelContext: ModelContext
    let onComplete: () -> Void

    @State private var name: String = ""
    @State private var notificationsEnabled = false
    @State private var notificationRequested = false
    @State private var appeared = false
    @State private var cursorVisible: Bool = true
    @FocusState private var nameFocused: Bool

    private var archetype: FinancialArchetype { dna.primaryArchetype }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                VStack(spacing: 8) {
                    Text("Welcome,")
                        .font(Typography.displayMedium)
                        .foregroundStyle(Theme.textSecondary)

                    ZStack {
                        if name.isEmpty && !nameFocused {
                            HStack(spacing: 0) {
                                Text("Tap to enter name")
                                    .font(Typography.displaySmall)
                                    .foregroundStyle(Theme.textMuted.opacity(0.5))

                                Rectangle()
                                    .fill(Theme.accent)
                                    .frame(width: 2, height: 28)
                                    .opacity(cursorVisible ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: cursorVisible)
                                    .padding(.leading, 2)
                            }
                            .onTapGesture { nameFocused = true }
                        }

                        TextField("", text: $name)
                            .font(Typography.displayMedium)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .tint(Theme.accent)
                            .focused($nameFocused)
                            .padding(.horizontal, 40)
                            .opacity(name.isEmpty && !nameFocused ? 0 : 1)
                    }

                    Rectangle()
                        .fill(Theme.accent.opacity(name.isEmpty ? 0.3 : 0.6))
                        .frame(width: 160, height: 2)
                        .animation(.easeOut(duration: 0.2), value: name)

                    if name.isEmpty {
                        Text("Enter your name to continue")
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.accent.opacity(0.7))
                            .padding(.top, 4)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)

                HStack(spacing: 12) {
                    Image(systemName: archetype.icon)
                        .font(Typography.headingLarge)
                        .foregroundStyle(archetype.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(archetype.rawValue)
                            .font(Typography.headingSmall)
                            .foregroundStyle(.white)

                        Text(archetype.tagline)
                            .font(Typography.labelSmall)
                            .foregroundStyle(archetype.color)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        axisDot(value: dna.spendingAxis, color: Theme.accent)
                        axisDot(value: dna.emotionalAxis, color: Theme.axisEmotional)
                        axisDot(value: dna.riskAxis, color: Theme.axisRisk)
                        axisDot(value: dna.socialAxis, color: Theme.axisSocial)
                    }
                }
                .padding(16)
                .splurjCard(.subtle)
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
                .animation(.spring(response: 0.5).delay(0.15), value: appeared)

                HStack(spacing: 12) {
                    Image(systemName: "map.fill")
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 40, height: 40)
                        .background(Theme.accent.opacity(0.12), in: .rect(cornerRadius: 10))

                    Text("Your first quest is waiting.")
                        .font(Typography.headingSmall)
                        .foregroundStyle(.white)

                    Spacer()
                }
                .padding(16)
                .splurjCard(.interactive)
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
                .animation(.spring(response: 0.5).delay(0.25), value: appeared)

                notificationCard
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.spring(response: 0.5).delay(0.35), value: appeared)

                Spacer().frame(height: 8)

                Button {
                    saveAndComplete()
                } label: {
                    HStack(spacing: 8) {
                        Text("Enter Splurj")
                            .font(Typography.headingLarge)
                        Image(systemName: "arrow.right")
                            .font(Typography.headingMedium)
                    }
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        !name.isEmpty
                            ? AnyShapeStyle(Theme.accentGradient)
                            : AnyShapeStyle(Color.gray.opacity(0.3)),
                        in: .rect(cornerRadius: 14)
                    )
                    .shadow(color: !name.isEmpty ? Theme.accent.opacity(0.4) : .clear, radius: 16, y: 6)
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                .disabled(name.isEmpty)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)

                Button {
                    onComplete()
                } label: {
                    Text("Skip for now")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(.top, 4)
                .padding(.bottom, 48)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
            cursorVisible = false
        }
    }

    private func axisDot(value: Double, color: Color) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.elevated)
                .frame(width: 4, height: 20)

            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: 20 * max(0.1, value))
        }
    }

    private var notificationCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "bell.badge.fill")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 40, height: 40)
                    .background(Theme.accent.opacity(0.12), in: .rect(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Remind me to complete quests")
                        .font(Typography.headingSmall)
                        .foregroundStyle(.white)

                    Text("Daily quest reminders & streak alerts")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()
            }

            if !notificationRequested {
                Button {
                    requestNotifications()
                } label: {
                    Text("Enable Reminders")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent, in: .rect(cornerRadius: 10))
                }
                .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: notificationsEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(notificationsEnabled ? Theme.accent : Theme.textSecondary)
                    Text(notificationsEnabled ? "Reminders enabled" : "Not now — you can enable later")
                        .font(Typography.bodySmall)
                        .foregroundStyle(notificationsEnabled ? Theme.accent : Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .padding(16)
        .splurjCard(.elevated)
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            Task { @MainActor in
                notificationsEnabled = granted
                notificationRequested = true
            }
        }
    }

    private func saveAndComplete() {
        let profile = UserProfile(name: name)
        profile.notificationsEnabled = notificationsEnabled
        modelContext.insert(profile)

        let result = FinancialDNAResult(
            dna: dna,
            cardSortAnswers: [],
            triggerRatings: [:],
            memoryAnswers: [],
            riskScore: dna.riskAxis
        )
        modelContext.insert(result)
        try? modelContext.save()

        onComplete()
    }
}
