import SwiftUI
import PhosphorSwift

struct IntroOnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage: Int = 0
    @State private var appeared: Bool = false
    @State private var contentAppeared: [Bool] = Array(repeating: false, count: 5)
    @State private var iconFloat: CGFloat = 0
    @State private var ctaPulse: CGFloat = 1.0

    private let pages = IntroPage.allPages

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    Theme.background, Theme.background, Theme.background,
                    Theme.accent.opacity(0.02), Theme.background, Theme.accent.opacity(0.015),
                    Theme.background, Theme.gold.opacity(0.015), Theme.background
                ]
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        introPageView(page: page, index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentPage)

                bottomControls
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            revealPage(0)
            startIconFloat()
        }
        .onChange(of: currentPage) { _, newValue in
            revealPage(newValue)
            HapticManager.impact(.light)
        }
    }

    // MARK: - Page Content

    private func introPageView(page: IntroPage, index: Int) -> some View {
        VStack(spacing: 0) {
            Spacer()

            illustrationArea(page: page, index: index)
                .padding(.bottom, 40)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(Typography.displayMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(contentAppeared[safe: index] == true ? 1 : 0)
                    .offset(y: contentAppeared[safe: index] == true ? 0 : 16)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: contentAppeared[safe: index])

                Text(page.subtitle)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 32)
                    .opacity(contentAppeared[safe: index] == true ? 1 : 0)
                    .offset(y: contentAppeared[safe: index] == true ? 0 : 12)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: contentAppeared[safe: index])
            }
            .padding(.horizontal, 20)

            Spacer()
            Spacer()
        }
    }

    private func illustrationArea(page: IntroPage, index: Int) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [page.accentColor.opacity(0.1), page.accentColor.opacity(0.02), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 90
                    )
                )
                .frame(width: 200, height: 200)

            Circle()
                .strokeBorder(page.accentColor.opacity(0.08), lineWidth: 1)
                .frame(width: 160, height: 160)

            Circle()
                .strokeBorder(page.accentColor.opacity(0.12), lineWidth: 1)
                .frame(width: 110, height: 110)

            Circle()
                .fill(page.accentColor.opacity(0.08))
                .frame(width: 80, height: 80)

            page.icon
                .frame(width: 36, height: 36)
                .foregroundStyle(page.accentColor)
                .shadow(color: page.accentColor.opacity(0.4), radius: 10)
        }
        .offset(y: iconFloat)
        .opacity(contentAppeared[safe: index] == true ? 1 : 0)
        .scaleEffect(contentAppeared[safe: index] == true ? 1 : 0.85)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: contentAppeared[safe: index])
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 20) {
            pageIndicator

            if currentPage == pages.count - 1 {
                Button {
                    HapticManager.notification(.success)
                    onComplete()
                } label: {
                    HStack(spacing: 8) {
                        Text("Let's Go!")
                            .font(Typography.headingMedium)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(Theme.buttonTextOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.goldGradient, in: .rect(cornerRadius: 16))
                    .shadow(color: Theme.accent.opacity(0.3), radius: 12, y: 4)
                    .scaleEffect(ctaPulse)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .onAppear { startCTAPulse() }
            } else {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        currentPage += 1
                    }
                } label: {
                    Text("Continue")
                        .font(Typography.headingMedium)
                        .foregroundStyle(Theme.buttonTextOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.goldGradient, in: .rect(cornerRadius: 16))
                        .shadow(color: Theme.accent.opacity(0.2), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
            }

            if currentPage < pages.count - 1 {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        currentPage = pages.count - 1
                    }
                } label: {
                    Text("Skip")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.textMuted)
                }
            } else {
                Spacer().frame(height: 17)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Theme.accent : Theme.textMuted.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    // MARK: - Animations

    private func revealPage(_ index: Int) {
        guard index < contentAppeared.count else { return }
        if !contentAppeared[index] {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                contentAppeared[index] = true
            }
        }
    }

    private func startIconFloat() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            iconFloat = -6
        }
    }

    private func startCTAPulse() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            ctaPulse = 1.03
        }
    }
}

// MARK: - Page Model

private struct IntroPage: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: Image
    let accentColor: Color

    static let allPages: [IntroPage] = [
        IntroPage(
            id: 0,
            title: "Track Every Win",
            subtitle: "Log purchases you avoided and watch your savings grow in real time.",
            icon: PhIcon.piggyBankFill,
            accentColor: Theme.accent
        ),
        IntroPage(
            id: 1,
            title: "Complete Quests",
            subtitle: "Turn financial goals into fun daily challenges with real rewards.",
            icon: PhIcon.compass,
            accentColor: Theme.accent
        ),
        IntroPage(
            id: 2,
            title: "Build Your Streak",
            subtitle: "Stay consistent and unlock powerful rewards as your streak grows.",
            icon: PhIcon.fireFill,
            accentColor: Theme.accent
        ),
        IntroPage(
            id: 3,
            title: "Ready to Start?",
            subtitle: "Your personal finance companion evolves with you. Let's build something great.",
            icon: PhIcon.rocketFill,
            accentColor: Theme.accent
        )
    ]
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
