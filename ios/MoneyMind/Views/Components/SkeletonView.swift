import SwiftUI

struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 8

    @State private var shimmerOffset: CGFloat = -200
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Theme.surface)
            .frame(maxWidth: width == nil ? .infinity : width, maxHeight: height)
            .frame(height: height)
            .overlay(
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.05), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 200)
                .offset(x: shimmerOffset)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
    }
}

struct SkeletonCircle: View {
    let size: CGFloat

    @State private var shimmerOffset: CGFloat = -200
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(Theme.surface)
            .frame(width: size, height: size)
            .overlay(
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.05), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 100)
                .offset(x: shimmerOffset)
            )
            .clipShape(Circle())
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
    }
}

struct SkeletonCardRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonCircle(size: 40)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonView(width: 120, height: 14)
                SkeletonView(width: 80, height: 10)
            }
            Spacer()
            SkeletonView(width: 60, height: 16)
        }
        .padding(.vertical, 8)
    }
}

struct SkeletonListView: View {
    let rowCount: Int

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<rowCount, id: \.self) { _ in
                SkeletonCardRow()
            }
        }
    }
}

struct SkeletonGridView: View {
    let columns: Int
    let rows: Int
    let itemHeight: CGFloat

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns),
            spacing: 12
        ) {
            ForEach(0..<(columns * rows), id: \.self) { _ in
                VStack(spacing: 8) {
                    SkeletonView(height: itemHeight, cornerRadius: 12)
                    SkeletonView(width: 80, height: 12)
                }
            }
        }
    }
}
