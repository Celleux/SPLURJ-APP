import SwiftUI

struct SpeechBubble: View {
    let message: String
    let onDismiss: () -> Void
    @State private var displayedText: String = ""
    @State private var appeared: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Text(displayedText)
                .font(Typography.bodySmall)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.08), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                )

            Triangle()
                .fill(.ultraThinMaterial.opacity(0.4))
                .frame(width: 14, height: 8)
                .offset(y: -1)
        }
        .scaleEffect(appeared ? 1 : 0.5)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                appeared = true
            }
            startTypewriter()
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.2)) {
                appeared = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onDismiss()
            }
        }
        .accessibilityLabel("Splurji says: \(message)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to dismiss")
    }

    private func startTypewriter() {
        if reduceMotion {
            displayedText = message
            return
        }

        displayedText = ""
        let words = message.split(separator: " ").map(String.init)
        var delay: Double = 0.1

        for (index, word) in words.enumerated() {
            let currentDelay = delay
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(currentDelay))
                if index == 0 {
                    displayedText = word
                } else {
                    displayedText += " " + word
                }
            }
            delay += 0.05
        }
    }
}

private struct Triangle: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - rect.width / 2, y: 0))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.height))
        path.addLine(to: CGPoint(x: rect.midX + rect.width / 2, y: 0))
        path.closeSubpath()
        return path
    }
}
