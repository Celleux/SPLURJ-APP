import SwiftUI

struct ScratchCardToastData: Equatable {
    let isGlowing: Bool
}

struct ScratchCardToast: View {
    let data: ScratchCardToastData
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(Typography.headingMedium)
                .foregroundStyle(data.isGlowing ? Theme.gold : Theme.accent)

            Text(data.isGlowing ? "You earned a GLOWING scratch card" : "You earned a scratch card")
                .font(Typography.labelMedium)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Image(systemName: "xmark")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            (data.isGlowing ? Theme.gold : Theme.accent).opacity(0.3),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: (data.isGlowing ? Theme.gold : Theme.accent).opacity(0.2), radius: 12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .onTapGesture { onDismiss() }
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(3))
                onDismiss()
            }
        }
    }
}
