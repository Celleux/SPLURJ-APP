import SwiftUI

struct DNAAxisPreviewCard: View {
    let title: String
    let icon: String
    let color: Color
    var value: Double? = nil
    var showShimmer: Bool = false

    @State private var shimmerOffset: CGFloat = -1.0

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(Typography.headingLarge)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12), in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(Typography.headingSmall)
                    .foregroundStyle(Theme.textPrimary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.elevated)
                            .frame(height: 6)

                        if let value {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [color, color.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * max(0.05, value), height: 6)
                                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: value)
                        }

                        if showShimmer {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            color.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * 0.4, height: 6)
                                .offset(x: shimmerOffset * geo.size.width)
                        }
                    }
                }
                .frame(height: 6)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .splurjCard(.outlined)
        .onAppear {
            guard showShimmer else { return }
            withAnimation(.easeInOut(duration: 1.5).delay(0.5)) {
                shimmerOffset = 1.0
            }
        }
    }
}
