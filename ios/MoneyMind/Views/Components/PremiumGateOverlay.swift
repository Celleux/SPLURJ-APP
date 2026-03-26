import SwiftUI

struct PremiumGateOverlay: View {
    let featureName: String
    let teaser: String
    @Environment(PremiumManager.self) private var premiumManager
    @State private var showPaywall: Bool = false
    @State private var appeared: Bool = false
    @State private var iconPulse: Bool = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.gold.opacity(0.2), Theme.gold.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)

                    Circle()
                        .strokeBorder(Theme.gold.opacity(0.3), lineWidth: 1)
                        .frame(width: 72, height: 72)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                        .scaleEffect(iconPulse ? 1.08 : 1.0)
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.7)

                VStack(spacing: 8) {
                    Text(featureName)
                        .font(Typography.headingLarge)
                        .foregroundStyle(Theme.textPrimary)

                    Text(teaser)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Unlock with Premium")
                            .font(Typography.headingMedium)
                    }
                    .foregroundStyle(Theme.buttonTextOnAccent)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Theme.goldGradient, in: .capsule)
                    .shadow(color: Theme.gold.opacity(0.3), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5)) {
                iconPulse = true
            }
        }
    }
}

struct PremiumGateModifier: ViewModifier {
    let featureName: String
    let teaser: String
    @Environment(PremiumManager.self) private var premiumManager

    func body(content: Content) -> some View {
        content
            .overlay {
                if !premiumManager.hasFullAccess {
                    PremiumGateOverlay(featureName: featureName, teaser: teaser)
                }
            }
    }
}

extension View {
    func premiumGate(feature: String, teaser: String) -> some View {
        modifier(PremiumGateModifier(featureName: feature, teaser: teaser))
    }
}
