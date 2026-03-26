import SwiftUI

struct SOSEmergencySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showUrgeSurf = false
    @State private var showEmergency = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(Typography.displayMedium)
                            .foregroundStyle(Theme.accent)
                            .symbolEffect(.pulse, options: .repeating)

                        Text("You're Not Alone")
                            .font(Typography.displaySmall)
                            .foregroundStyle(Theme.textPrimary)

                        Text("This moment will pass. Let's get through it together.")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 12) {
                        SOSActionCard(
                            icon: "water.waves",
                            title: "Urge Surfing",
                            subtitle: "Ride the wave — guided breathing",
                            color: Theme.teal
                        ) {
                            showUrgeSurf = true
                        }

                        SOSActionCard(
                            icon: "cross.fill",
                            title: "Full Crisis Support",
                            subtitle: "Hotlines, grounding & screening",
                            color: Theme.textSecondary
                        ) {
                            showEmergency = true
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Access")
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.textPrimary)

                        VStack(spacing: 8) {
                            CrisisRow(
                                name: "Suicide & Crisis Lifeline",
                                number: "988",
                                available: "24/7, Free"
                            )
                            CrisisRow(
                                name: "Gambling Helpline",
                                number: "1-800-522-4700",
                                available: "24/7, Free & Confidential"
                            )
                            CrisisRow(
                                name: "Crisis Text Line",
                                number: "Text HOME to 741741",
                                available: "24/7"
                            )
                        }
                    }
                    .padding(16)
                    .splurjCard(.elevated)

                    Text("Remember: You've resisted before and you can do it again.")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)
                }
                .padding(.horizontal)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accentGreen)
                }
            }
            .fullScreenCover(isPresented: $showUrgeSurf) {
                UrgeSurfView()
            }
            .fullScreenCover(isPresented: $showEmergency) {
                EmergencyCrisisView()
            }
        }
    }
}

private struct SOSActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(Typography.displaySmall)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12), in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary.opacity(0.5))
            }
            .padding(16)
            .splurjCard(.interactive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

private struct CrisisRow: View {
    let name: String
    let number: String
    let available: String

    var body: some View {
        Button {
            let digits = number.filter { $0.isNumber || $0 == "+" }
            guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else { return }
            UIApplication.shared.open(url)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)
                    Text(available)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(number)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.accentGreen)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
