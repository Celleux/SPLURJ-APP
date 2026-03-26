import SwiftUI
import SwiftData

struct VibeCheckOverlay: View {
    let transaction: Transaction
    let onSelect: (VibeType) -> Void
    let onSkip: () -> Void

    @State private var selectedVibe: VibeType?
    @State private var appeared: Bool = false
    @State private var bounceVibe: VibeType?
    @State private var dismissing: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Vibe Check")
                        .font(Typography.headingLarge)
                        .foregroundStyle(Theme.textPrimary)

                    Text("How did this purchase make you feel?")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(spacing: 0) {
                    ForEach(VibeType.allCases, id: \.self) { vibe in
                        vibeButton(vibe)
                    }
                }

                Button {
                    withAnimation(.easeOut(duration: 0.25)) {
                        dismissing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSkip()
                    }
                } label: {
                    Text("Not now")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Theme.border, lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 30, y: -10)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .offset(y: appeared && !dismissing ? 0 : 300)
            .opacity(appeared && !dismissing ? 1 : 0)
        }
        .background(
            Color.black.opacity(appeared && !dismissing ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture { }
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }

    private func vibeButton(_ vibe: VibeType) -> some View {
        let isSelected = selectedVibe == vibe
        let isBouncing = bounceVibe == vibe

        return Button {
            guard selectedVibe == nil else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bounceVibe = vibe
                selectedVibe = vibe
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.25)) {
                    dismissing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSelect(vibe)
                }
            }
        } label: {
            VStack(spacing: 6) {
                Text(vibe.emoji)
                    .font(Typography.displayMedium)
                    .scaleEffect(isBouncing ? 1.35 : 1.0)
                    .shadow(color: isSelected ? Theme.accent.opacity(0.6) : .clear, radius: 8)

                Text(vibe.label)
                    .font(Typography.labelSmall)
                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ? Theme.accent.opacity(0.15) : Color.clear,
                in: .rect(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: isBouncing)
    }
}
