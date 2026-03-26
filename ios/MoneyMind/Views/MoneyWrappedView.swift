import SwiftUI

struct MoneyWrappedView: View {
    let data: WrappedData

    @Environment(\.dismiss) private var dismiss
    @Environment(PremiumManager.self) private var premiumManager
    @State private var currentSlide: Int = 0
    @State private var slideAppeared: [Bool] = Array(repeating: false, count: 7)
    @State private var isPaused: Bool = false
    @State private var shareImage: UIImage?
    @State private var showShareSheet: Bool = false
    @State private var hapticTick: Int = 0

    private let slideCount = 7

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                slideContent(for: currentSlide, size: geo.size)
                    .id(currentSlide)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))

                VStack {
                    storyProgressBar
                        .padding(.horizontal, 8)
                        .padding(.top, geo.safeAreaInsets.top + 8)

                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(Typography.headingMedium)
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(width: 32, height: 32)
                                .background(.ultraThinMaterial, in: .circle)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 4)
                    }

                    Spacer()
                }
                .zIndex(100)

                Color.clear
                    .contentShape(.rect)
                    .onTapGesture { goForward() }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.2)
                            .onChanged { _ in isPaused = true }
                            .onEnded { _ in isPaused = false }
                    )
                    .gesture(
                        DragGesture(minimumDistance: 50)
                            .onEnded { value in
                                if value.translation.width > 50 {
                                    goBack()
                                }
                            }
                    )
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
        .premiumGate(feature: "Full Splurj Wrapped", teaser: "Unlock detailed analytics, history, and shareable story recaps")
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                slideAppeared[0] = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    private var storyProgressBar: some View {
        HStack(spacing: 3) {
            ForEach(0..<slideCount, id: \.self) { i in
                Capsule()
                    .fill(
                        i < currentSlide ? AnyShapeStyle(data.personality.color) :
                        i == currentSlide ? AnyShapeStyle(
                            LinearGradient(
                                colors: [data.personality.color, data.personality.color.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        ) : AnyShapeStyle(Color.white.opacity(0.2))
                    )
                    .frame(height: 2.5)
                    .animation(.easeOut(duration: 0.3), value: currentSlide)
            }
        }
    }

    @ViewBuilder
    private func slideContent(for index: Int, size: CGSize) -> some View {
        let appeared = slideAppeared[index]
        switch index {
        case 0: WrappedSlideIntro(data: data, appeared: appeared, size: size)
        case 1: WrappedSlideSpent(data: data, appeared: appeared, size: size)
        case 2: WrappedSlideTopCategory(data: data, appeared: appeared, size: size)
        case 3: WrappedSlideMoodMap(data: data, appeared: appeared, size: size)
        case 4: WrappedSlideSavings(data: data, appeared: appeared, size: size)
        case 5: WrappedSlideFortune(data: data, appeared: appeared, size: size)
        case 6: WrappedSlideShareCard(data: data, appeared: appeared, size: size, onShare: shareWrapped)
        default: EmptyView()
        }
    }

    private func goForward() {
        guard !isPaused else { return }
        if currentSlide < slideCount - 1 {
            hapticTick += 1
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                currentSlide += 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                slideAppeared[currentSlide] = true
            }
        }
    }

    private func goBack() {
        guard !isPaused else { return }
        if currentSlide > 0 {
            hapticTick += 1
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                currentSlide -= 1
            }
        }
    }

    private func shareWrapped() {
        let card = WrappedShareImage(data: data)
        shareImage = ShareCardRenderer.render(card)
        if shareImage != nil { showShareSheet = true }
    }
}

// MARK: - Slide 1: Intro

private struct WrappedSlideIntro: View {
    let data: WrappedData
    let appeared: Bool
    let size: CGSize

    @State private var iconPulse: Bool = false
    @State private var meshPhase: CGFloat = 0

    var body: some View {
        ZStack {
            wrappedMeshBg(accent: data.personality.color, phase: meshPhase)

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: data.personality.icon)
                    .font(Typography.displayLarge)
                    .foregroundStyle(data.personality.color)
                    .scaleEffect(iconPulse ? 1.15 : 0.9)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: iconPulse)

                Spacer().frame(height: 40)

                VStack(spacing: 14) {
                    Text(data.isAnnual ? "Your Year in" : "Your Month in")
                        .font(Typography.displaySmall)
                        .foregroundStyle(.white.opacity(0.6))
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    Text("Splurj")
                        .font(Typography.displayLarge)
                        .foregroundStyle(.white)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    Text(data.periodLabel)
                        .font(Typography.headingLarge)
                        .foregroundStyle(data.personality.color)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                }

                Spacer()

                Text("Tap to continue")
                    .font(Typography.labelSmall)
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 60)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            iconPulse = true
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                meshPhase = 1
            }
        }
    }
}

// MARK: - Slide 2: Total Spent

private struct WrappedSlideSpent: View {
    let data: WrappedData
    let appeared: Bool
    let size: CGSize

    @State private var animatedAmount: Double = 0

    var body: some View {
        ZStack {
            wrappedMeshBg(accent: data.personality.color, secondary: Theme.accent.opacity(0.6))

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    Text(data.isAnnual ? "YOU SAVED" : "TOTAL SPENT")
                        .font(Typography.labelSmall)
                        .foregroundStyle(data.personality.color)
                        .tracking(4)
                        .opacity(appeared ? 1 : 0)

                    Text(animatedAmount, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(Typography.displayLarge)
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(value: animatedAmount))

                    if data.spendingChangePercent != 0 {
                        let isUp = data.spendingChangePercent > 0
                        HStack(spacing: 6) {
                            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                                .font(Typography.headingSmall)
                            Text("\(abs(Int(data.spendingChangePercent)))% \(isUp ? "more" : "less") than last month")
                                .font(Typography.bodyMedium)
                        }
                        .foregroundStyle(isUp ? Theme.danger : Theme.success)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.8), value: appeared)
                    }

                    Image(systemName: "dollarsign.circle.fill")
                        .font(Typography.displayLarge)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [data.personality.color, Theme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.5), value: appeared)
                }

                Spacer()
            }
        }
        .frame(width: size.width, height: size.height)
        .onChange(of: appeared) { _, newValue in
            if newValue {
                let target = data.isAnnual ? data.totalSaved : data.totalSpent
                withAnimation(.easeOut(duration: 1.2)) {
                    animatedAmount = target
                }
            }
        }
    }
}

// MARK: - Slide 3: Top Category

private struct WrappedSlideTopCategory: View {
    let data: WrappedData
    let appeared: Bool
    let size: CGSize

    @State private var ringProgress: Double = 0

    var body: some View {
        ZStack {
            wrappedMeshBg(accent: Theme.secondary, secondary: data.personality.color.opacity(0.5))

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    Text("TOP CATEGORY")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.secondary)
                        .tracking(4)
                        .opacity(appeared ? 1 : 0)

                    ZStack {
                        ForEach(Array(data.categoryBreakdown.prefix(5).enumerated()), id: \.offset) { index, cat in
                            let total = data.categoryBreakdown.prefix(5).reduce(0.0) { $0 + $1.amount }
                            let fraction = total > 0 ? cat.amount / total : 0.2
                            let startAngle = startAngleFor(index: index, in: data.categoryBreakdown.prefix(5).map(\.amount))

                            PieSlice(startAngle: .degrees(startAngle), endAngle: .degrees(startAngle + fraction * 360))
                                .fill(Color(hex: UInt(cat.color, radix: 16) ?? 0x6C5CE7))
                                .opacity(index == 0 ? 1.0 : 0.6)
                                .scaleEffect(appeared ? 1 : 0.3)
                                .opacity(appeared ? 1 : 0)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.12),
                                    value: appeared
                                )
                        }

                        if data.categoryBreakdown.isEmpty {
                            Circle()
                                .fill(Theme.elevated)
                        }
                    }
                    .frame(width: 160, height: 160)

                    if let top = data.topCategory {
                        VStack(spacing: 10) {
                            Text(top.category)
                                .font(Typography.displaySmall)
                                .foregroundStyle(.white)

                            Text("was your biggest spend at \(top.amount, format: .currency(code: "USD").precision(.fractionLength(0)))")
                                .font(Typography.bodyMedium)
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)

                            HStack(spacing: 6) {
                                Image(systemName: "cup.and.saucer.fill")
                                    .foregroundStyle(Theme.secondary)
                                Text("That's \(data.coffeEquivalent) cups of coffee")
                                    .font(Typography.bodySmall)
                                    .foregroundStyle(Theme.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.secondary.opacity(0.1), in: .capsule)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.6), value: appeared)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func startAngleFor(index: Int, in amounts: [Double]) -> Double {
        let total = amounts.reduce(0, +)
        guard total > 0 else { return 0 }
        var angle: Double = -90
        for i in 0..<index {
            angle += (amounts[i] / total) * 360
        }
        return angle
    }
}

private struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle

    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

// MARK: - Slide 4: Mood Map

private struct WrappedSlideMoodMap: View {
    let data: WrappedData
    let appeared: Bool
    let size: CGSize

    private let defaultMoods: [(emoji: String, count: Int)] = [
        ("😌", 5), ("😬", 3), ("😤", 2), ("✅", 8), ("💪", 4)
    ]

    private var moods: [(emoji: String, count: Int)] {
        data.moodBreakdown.isEmpty ? defaultMoods : data.moodBreakdown
    }

    private var topMood: (emoji: String, count: Int) {
        moods.max(by: { $0.count < $1.count }) ?? ("😌", 0)
    }

    private var totalCount: Int {
        moods.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        ZStack {
            wrappedMeshBg(accent: .purple, secondary: data.personality.color.opacity(0.4))

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    Text("SPENDING MOODS")
                        .font(Typography.labelSmall)
                        .foregroundStyle(.purple)
                        .tracking(4)
                        .opacity(appeared ? 1 : 0)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(Array(moodGrid.enumerated()), id: \.offset) { index, emoji in
                            Text(emoji)
                                .font(Typography.displayMedium)
                                .scaleEffect(appeared ? 1 : 0)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.6)
                                    .delay(Double(index) * 0.04),
                                    value: appeared
                                )
                        }
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 10) {
                        Text(topMood.emoji)
                            .font(Typography.displayLarge)
                            .scaleEffect(appeared ? 1 : 0.3)
                            .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.6), value: appeared)

                        let pct = totalCount > 0 ? Int((Double(topMood.count) / Double(totalCount)) * 100) : 0
                        Text("Your top vibe \(pct)% of purchases")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.8), value: appeared)
                    }
                }

                Spacer()
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private var moodGrid: [String] {
        var grid: [String] = []
        for mood in moods {
            for _ in 0..<min(mood.count, 6) {
                grid.append(mood.emoji)
            }
        }
        return Array(grid.shuffled().prefix(16))
    }
}

// MARK: - Slide 5: Savings

private struct WrappedSlideSavings: View {
    let data: WrappedData
    let appeared: Bool
    let size: CGSize

    @State private var ringFill: Double = 0
    @State private var showConfetti: Bool = false
    @State private var confettiParticles: [ConfettiPiece] = []

    var body: some View {
        ZStack {
            wrappedMeshBg(accent: Theme.success, secondary: Theme.secondary.opacity(0.5))

            ForEach(confettiParticles) { piece in
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .position(piece.position)
                    .opacity(showConfetti ? 0 : 1)
                    .animation(.easeOut(duration: piece.duration), value: showConfetti)
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    Text("SAVINGS PROGRESS")
                        .font(Typography.labelSmall)
                        .foregroundStyle(Theme.success)
                        .tracking(4)
                        .opacity(appeared ? 1 : 0)

                    ZStack {
                        Circle()
                            .stroke(Theme.elevated, lineWidth: 12)
                            .frame(width: 180, height: 180)

                        Circle()
                            .trim(from: 0, to: ringFill)
                            .stroke(
                                AngularGradient(
                                    colors: [Theme.success, Theme.secondary, Theme.success],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Text("\(Int(data.savingsProgress * 100))%")
                                .font(Typography.displayLarge)
                                .foregroundStyle(.white)

                            Text("of goal")
                                .font(Typography.labelSmall)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }

                    if data.savingsGoal > 0 {
                        Text("\(data.totalSaved, format: .currency(code: "USD").precision(.fractionLength(0))) of \(data.savingsGoal, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            .font(Typography.bodyLarge)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    if data.goalMet {
                        HStack(spacing: 8) {
                            Image(systemName: "party.popper.fill")
                            Text("Goal Reached!")
                        }
                        .font(Typography.headingLarge)
                        .foregroundStyle(Theme.gold)
                        .scaleEffect(appeared ? 1 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(1.2), value: appeared)
                    }
                }

                Spacer()
            }
        }
        .frame(width: size.width, height: size.height)
        .onChange(of: appeared) { _, newValue in
            if newValue {
                withAnimation(.easeOut(duration: 1.4)) {
                    ringFill = data.savingsProgress
                }
                if data.goalMet {
                    spawnConfetti(in: size)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showConfetti = true
                    }
                }
            }
        }
    }

    private func spawnConfetti(in size: CGSize) {
        let colors: [Color] = [Theme.success, Theme.secondary, Theme.gold, .white, data.personality.color]
        confettiParticles = (0..<40).map { _ in
            ConfettiPiece(
                position: CGPoint(
                    x: CGFloat.random(in: 40...(size.width - 40)),
                    y: CGFloat.random(in: (size.height * 0.2)...(size.height * 0.7))
                ),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 4...10),
                duration: Double.random(in: 1.5...3.0)
            )
        }
    }
}

nonisolated struct ConfettiPiece: Identifiable, Sendable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let size: CGFloat
    let duration: Double
}

// MARK: - Slide 6: Fortune

private struct WrappedSlideFortune: View {
    let data: WrappedData
    let appeared: Bool
    let size: CGSize

    @State private var glowPhase: Bool = false

    var body: some View {
        ZStack {
            wrappedMeshBg(accent: data.personality.color, secondary: .indigo.opacity(0.4))

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Text("FINANCIAL FORTUNE")
                        .font(Typography.labelSmall)
                        .foregroundStyle(data.personality.color)
                        .tracking(4)
                        .opacity(appeared ? 1 : 0)

                    Image(systemName: "sparkle")
                        .font(Typography.displayMedium)
                        .foregroundStyle(data.personality.color)
                        .scaleEffect(glowPhase ? 1.2 : 0.9)
                        .opacity(appeared ? 1 : 0)

                    VStack(spacing: 20) {
                        Text(data.fortune)
                            .font(.system(.body, design: .serif, weight: .regular))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 8)
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Theme.elevated.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        data.personality.color.opacity(glowPhase ? 0.6 : 0.2),
                                        data.personality.color.opacity(0.1),
                                        data.personality.color.opacity(glowPhase ? 0.6 : 0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: data.personality.color.opacity(glowPhase ? 0.3 : 0.1), radius: 20)
                    .rotationEffect(.degrees(-1.5))
                    .scaleEffect(appeared ? 1 : 0.85)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appeared)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
        }
    }
}

// MARK: - Slide 7: Share Card

private struct WrappedSlideShareCard: View {
    let data: WrappedData
    let appeared: Bool
    let size: CGSize
    let onShare: () -> Void

    var body: some View {
        ZStack {
            wrappedMeshBg(accent: data.personality.color, secondary: Theme.secondary.opacity(0.3))

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        Image(systemName: data.personality.icon)
                            .font(Typography.headingLarge)
                            .foregroundStyle(data.personality.color)
                        Text(data.periodLabel)
                            .font(Typography.headingMedium)
                            .foregroundStyle(.white)
                    }
                    .opacity(appeared ? 1 : 0)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        StatMini(
                            label: data.isAnnual ? "Saved" : "Spent",
                            value: (data.isAnnual ? data.totalSaved : data.totalSpent).formatted(.currency(code: "USD").precision(.fractionLength(0))),
                            icon: "dollarsign.circle.fill",
                            color: Theme.success,
                            appeared: appeared,
                            delay: 0.1
                        )
                        StatMini(
                            label: "Resisted",
                            value: "\(data.purchasesResisted)",
                            icon: "hand.raised.fill",
                            color: Theme.secondary,
                            appeared: appeared,
                            delay: 0.2
                        )
                        StatMini(
                            label: "Streak",
                            value: "\(data.longestStreak) days",
                            icon: "flame.fill",
                            color: .orange,
                            appeared: appeared,
                            delay: 0.3
                        )
                        StatMini(
                            label: "Level",
                            value: "\(data.level) \(data.characterStage.name)",
                            icon: data.characterStage.bodyIcon,
                            color: data.characterStage.primaryColor,
                            appeared: appeared,
                            delay: 0.4
                        )
                    }
                    .padding(.horizontal, 8)
                }
                .padding(24)
                .background(Theme.card.opacity(0.8), in: .rect(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(data.personality.color.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .scaleEffect(appeared ? 1 : 0.9)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)

                Spacer().frame(height: 32)

                VStack(spacing: 14) {
                    Button(action: onShare) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(Typography.headingMedium)
                            Text("Share Your Wrapped")
                                .font(Typography.headingMedium)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [data.personality.color, data.personality.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: .rect(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                }
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)

                Spacer()
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct StatMini: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    let appeared: Bool
    let delay: Double

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(Typography.headingLarge)
                .foregroundStyle(color)

            Text(value)
                .font(Typography.headingMedium)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.elevated.opacity(0.5), in: .rect(cornerRadius: 12))
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay), value: appeared)
    }
}

// MARK: - Share Image (1080x1920)

struct WrappedShareImage: View {
    let data: WrappedData

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Theme.accentGreen)
                    Text("Splurj")
                        .font(Typography.labelSmall)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Text(data.periodLabel)
                    .font(Typography.labelSmall)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 28)
            .padding(.top, 48)

            Spacer()

            VStack(spacing: 32) {
                Image(systemName: data.personality.icon)
                    .font(Typography.displayLarge)
                    .foregroundStyle(data.personality.color)

                Text(data.isAnnual ? "Year in Review" : "Monthly Wrapped")
                    .font(Typography.displayMedium)
                    .foregroundStyle(.white)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ShareStatCell(label: data.isAnnual ? "Saved" : "Spent", value: (data.isAnnual ? data.totalSaved : data.totalSpent).formatted(.currency(code: "USD").precision(.fractionLength(0))), color: Theme.success)
                    ShareStatCell(label: "Resisted", value: "\(data.purchasesResisted)", color: Theme.secondary)
                    ShareStatCell(label: "Streak", value: "\(data.longestStreak) days", color: .orange)
                    ShareStatCell(label: "Level", value: "\(data.level)", color: data.personality.color)
                }
                .padding(.horizontal, 20)

                if let top = data.topCategory {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: UInt(top.color, radix: 16) ?? 0x6C5CE7))
                            .frame(width: 10, height: 10)
                        Text("Top: \(top.category)")
                            .font(Typography.bodySmall)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }

            Spacer()

            VStack(spacing: 8) {
                Text("Get Splurj")
                    .font(Typography.labelSmall)
                    .foregroundStyle(data.personality.color)
                CardWatermark()
            }
            .padding(.bottom, 48)
        }
        .frame(width: ShareCardRenderer.viewSize.width, height: ShareCardRenderer.viewSize.height)
        .background(CardBackground(accentColor: data.personality.color, secondaryColor: Theme.secondary))
        .clipShape(.rect(cornerRadius: 24))
    }
}

private struct ShareStatCell: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(Typography.displaySmall)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Shared Mesh Background

private func wrappedMeshBg(accent: Color, secondary: Color? = nil, phase: CGFloat = 0) -> some View {
    let sec = secondary ?? accent.opacity(0.5)
    return ZStack {
        Theme.background.ignoresSafeArea()

        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [Float(0.5 + phase * 0.1), 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, Float(0.5 + phase * 0.05)], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .clear, accent.opacity(0.12), .clear,
                sec.opacity(0.08), .clear, accent.opacity(0.06),
                .clear, sec.opacity(0.1), .clear
            ]
        )
        .ignoresSafeArea()

        RadialGradient(
            colors: [accent.opacity(0.08), .clear],
            center: .center,
            startRadius: 20,
            endRadius: 400
        )
        .ignoresSafeArea()
    }
}
