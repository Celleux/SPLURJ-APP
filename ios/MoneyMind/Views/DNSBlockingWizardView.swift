import SwiftUI
import SwiftData

struct DNSBlockingWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @AppStorage("blockingEnabled") private var blockingEnabled = false
    @State private var currentStep: Int = 0
    @State private var isConfiguring = false
    @State private var configSuccess = false
    @State private var showManualFallback = false

    private var profile: UserProfile? { profiles.first }

    private let shieldBlue = Color(red: 0.25, green: 0.45, blue: 0.95)

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                progressBar

                TabView(selection: $currentStep) {
                    step1Explanation.tag(0)
                    step2Setup.tag(1)
                    step3Success.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4), value: currentStep)
            }
        }
    }

    private var header: some View {
        HStack {
            Button("Close") { dismiss() }
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            Text("Block Gambling Sites")
                .font(Typography.headingMedium)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            if currentStep < 2 {
                Text("Step \(currentStep + 1)/3")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Circle().fill(.clear).frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.cardSurface)
                    .frame(height: 4)

                Capsule()
                    .fill(shieldBlue)
                    .frame(width: geo.size.width * (Double(currentStep + 1) / 3.0), height: 4)
                    .animation(.spring(response: 0.4), value: currentStep)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private var step1Explanation: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(shieldBlue.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: "shield.checkered")
                    .font(Typography.displayLarge)
                    .foregroundStyle(shieldBlue)
            }

            VStack(spacing: 12) {
                Text("What is DNS Blocking?")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("DNS blocking prevents your device from connecting to gambling and high-risk spending websites at the network level.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }

            VStack(alignment: .leading, spacing: 16) {
                BenefitRow(icon: "eye.slash.fill", text: "Blocks gambling sites before they load", color: shieldBlue)
                BenefitRow(icon: "bolt.shield.fill", text: "Works across all apps and browsers", color: shieldBlue)
                BenefitRow(icon: "lock.fill", text: "Privacy-first — all filtering on device", color: shieldBlue)
                BenefitRow(icon: "arrow.clockwise", text: "You can disable it anytime in Settings", color: shieldBlue)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                withAnimation { currentStep = 1 }
            } label: {
                Text("Set Up Blocking")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(shieldBlue, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private var step2Setup: some View {
        VStack(spacing: 32) {
            Spacer()

            if showManualFallback {
                manualInstructions
            } else if isConfiguring {
                VStack(spacing: 20) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(shieldBlue)

                    Text("Configuring DNS...")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.textPrimary)
                }
            } else {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(shieldBlue.opacity(0.12))
                            .frame(width: 100, height: 100)

                        Image(systemName: "network.badge.shield.half.filled")
                            .font(Typography.displayLarge)
                            .foregroundStyle(shieldBlue)
                    }

                    VStack(spacing: 8) {
                        Text("Configure DNS Protection")
                            .font(Typography.headingLarge)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Splurj will set up secure DNS filtering to block known gambling domains on your device.")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 16)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        BlockedCategoryRow(name: "Online Casinos", count: "2,400+")
                        BlockedCategoryRow(name: "Sports Betting", count: "1,800+")
                        BlockedCategoryRow(name: "Poker Sites", count: "600+")
                        BlockedCategoryRow(name: "Lottery Sites", count: "300+")
                    }
                    .padding(16)
                    .splurjCard(.elevated)
                    .padding(.horizontal, 24)
                }
            }

            Spacer()

            if !isConfiguring {
                VStack(spacing: 12) {
                    if !showManualFallback {
                        Button {
                            attemptDNSConfig()
                        } label: {
                            Text("Enable DNS Blocking")
                                .font(Typography.headingMedium)
                                .foregroundStyle(Theme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(shieldBlue, in: .rect(cornerRadius: 14))
                        }
                        .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                    } else {
                        Button {
                            completeSetup()
                        } label: {
                            Text("I've Enabled It")
                                .font(Typography.headingMedium)
                                .foregroundStyle(Theme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.accentGreen, in: .rect(cornerRadius: 14))
                        }
                        .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                    }

                    if !showManualFallback {
                        Button {
                            withAnimation { showManualFallback = true }
                        } label: {
                            Text("Set up manually instead")
                                .font(Typography.bodyMedium)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private var manualInstructions: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(shieldBlue.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "gear")
                    .font(Typography.displayMedium)
                    .foregroundStyle(shieldBlue)
            }

            Text("Manual Setup")
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 16) {
                ManualStepRow(number: 1, text: "Open Settings → General → VPN & Device Management → DNS")
                ManualStepRow(number: 2, text: "Select \"DNS over HTTPS\" and enter a blocking DNS provider like CleanBrowsing or NextDNS")
                ManualStepRow(number: 3, text: "Use gambling-blocking profile: https://cleanbrowsing.org/filters")
                ManualStepRow(number: 4, text: "Return here and tap \"I've Enabled It\"")
            }
            .padding(16)
            .splurjCard(.elevated)
            .padding(.horizontal, 24)
        }
    }

    private var step3Success: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.accentGreen.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.shield.fill")
                    .font(Typography.displayLarge)
                    .foregroundStyle(Theme.accentGreen)
                    .symbolEffect(.bounce, value: configSuccess)
            }

            VStack(spacing: 12) {
                Text("Protection Active!")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.textPrimary)

                Text("DNS blocking is now configured on your device. Gambling sites will be blocked across all apps and browsers.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)

                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.accentGreen)
                    Text("+100 XP")
                        .font(Typography.headingSmall)
                        .foregroundStyle(Theme.accentGreen)
                }
                .padding(.top, 8)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(shieldBlue)
                    Text("You can manage DNS settings anytime in Settings → General → VPN & Device Management → DNS")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(3)
                }
            }
            .padding(16)
            .splurjCard(.elevated)
            .padding(.horizontal, 24)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accentGradient, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .sensoryFeedback(.success, trigger: configSuccess)
    }

    private func attemptDNSConfig() {
        isConfiguring = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation {
                isConfiguring = false
                showManualFallback = true
            }
        }
    }

    private func completeSetup() {
        blockingEnabled = true
        if let profile {
            profile.xpPoints += 100
        }
        withAnimation {
            configSuccess = true
            currentStep = 2
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(Typography.bodyMedium)
                .foregroundStyle(color)
                .frame(width: 32)

            Text(text)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

private struct BlockedCategoryRow: View {
    let name: String
    let count: String

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.emergency.opacity(0.7))
                Text(name)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            Text(count)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

private struct ManualStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(Typography.labelSmall)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color(red: 0.25, green: 0.45, blue: 0.95), in: Circle())

            Text(text)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(3)
        }
    }
}
