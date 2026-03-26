import SwiftUI
import PhosphorSwift

struct SplurjEmptyState: View {
    let icon: Image
    let title: String
    let subtitle: String
    var ctaTitle: String? = nil
    var ctaAction: (() -> Void)? = nil

    @State private var floatOffset: CGFloat = 0
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.accent.opacity(0.08), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Circle()
                    .strokeBorder(Theme.accent.opacity(0.1), lineWidth: 1)
                    .frame(width: 120, height: 120)

                Circle()
                    .strokeBorder(Theme.accent.opacity(0.15), lineWidth: 1)
                    .frame(width: 80, height: 80)

                icon
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            .offset(y: floatOffset)

            Text(title)
                .font(Typography.headingLarge)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let ctaTitle, let ctaAction {
                Button(ctaTitle) { ctaAction() }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .medium))
            }
        }
        .padding(.vertical, 40)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                floatOffset = -4
            }
        }
    }
}
