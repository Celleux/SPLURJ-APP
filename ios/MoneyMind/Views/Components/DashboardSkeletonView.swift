import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.08),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: phase * geo.size.width * 2)
                }
                .clipShape(.rect(cornerRadius: 8))
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct DashboardSkeletonView: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    skeletonBlock(width: 180, height: 20)
                    skeletonBlock(width: 140, height: 14)
                }
                Spacer()
                skeletonCircle(size: 36)
            }
            .padding(.top, 16)

            VStack(spacing: 10) {
                skeletonBlock(width: 140, height: 14)
                skeletonBlock(width: 180, height: 48)
                skeletonBlock(width: 120, height: 14)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .splurjCard(.elevated)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: 10) {
                        skeletonCircle(size: 40)
                        skeletonBlock(width: 70, height: 14)
                        Spacer()
                    }
                    .padding(14)
                    .splurjCard(.subtle)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    skeletonBlock(width: 80, height: 16)
                    Spacer()
                    skeletonBlock(width: 50, height: 14)
                }
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            skeletonBlock(width: 80, height: 14)
                            Spacer()
                            skeletonBlock(width: 60, height: 12)
                        }
                        skeletonBlock(width: .infinity, height: 6)
                    }
                }
            }
            .padding(20)
            .splurjCard(.elevated)

            skeletonBlock(width: .infinity, height: 180)
                .splurjCard(.elevated)

            VStack(alignment: .leading, spacing: 14) {
                skeletonBlock(width: 60, height: 16)
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 12) {
                        skeletonCircle(size: 10)
                        VStack(alignment: .leading, spacing: 4) {
                            skeletonBlock(width: 120, height: 14)
                            skeletonBlock(width: 60, height: 10)
                        }
                        Spacer()
                        skeletonBlock(width: 60, height: 16)
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding(20)
            .splurjCard(.elevated)
        }
    }

    private func skeletonBlock(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Theme.elevated)
            .frame(maxWidth: width == .infinity ? .infinity : width, maxHeight: height)
            .frame(height: height)
            .shimmer()
    }

    private func skeletonCircle(size: CGFloat) -> some View {
        Circle()
            .fill(Theme.elevated)
            .frame(width: size, height: size)
            .shimmer()
    }
}
