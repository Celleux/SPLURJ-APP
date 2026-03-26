import SwiftUI

struct RiskToleranceView: View {
    @Binding var dna: FinancialDNA
    @Binding var riskScore: Double
    let onComplete: () -> Void

    @State private var currentLevel: Int = 0
    @State private var isRunning = false
    @State private var exploded = false
    @State private var lockedIn = false
    @State private var coinScale: CGFloat = 1.0
    @State private var shakeAmount: CGFloat = 0
    @State private var appeared = false
    @State private var showResult = false
    @State private var explosionParticles: [CoinParticle] = []

    private let levels: [(amount: String, risk: Int, riskAxis: Double)] = [
        ("$100", 5, 0.1),
        ("$200", 15, 0.2),
        ("$500", 30, 0.35),
        ("$1,000", 45, 0.5),
        ("$2,500", 60, 0.65),
        ("$5,000", 78, 0.8),
        ("$10,000", 92, 0.95),
    ]

    private var currentAmount: String {
        guard currentLevel < levels.count else { return "$0" }
        return levels[currentLevel].amount
    }

    private var currentRisk: Int {
        guard currentLevel < levels.count else { return 100 }
        return levels[currentLevel].risk
    }

    private var amountFontSize: CGFloat {
        let base: CGFloat = 40
        let growth = CGFloat(currentLevel) * 4
        return min(base + growth, 64)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("RISK TOLERANCE")
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.textMuted)
                .tracking(3)
                .padding(.top, 24)
                .opacity(appeared ? 1 : 0)

            Text("How far will you go?")
                .font(Typography.displaySmall)
                .foregroundStyle(.white)
                .padding(.top, 12)
                .opacity(appeared ? 1 : 0)

            Text("The coins keep growing. Cash out whenever.")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 6)
                .opacity(appeared ? 1 : 0)

            Spacer()

            if showResult {
                resultView
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            } else {
                gameView
            }

            Spacer()

            if !showResult {
                if !isRunning && !exploded && !lockedIn {
                    Button {
                        startGame()
                    } label: {
                        Text("Start the Challenge")
                            .font(Typography.headingMedium)
                            .foregroundStyle(Theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(Theme.accentGradient, in: .rect(cornerRadius: 14))
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                } else if isRunning {
                    Button {
                        lockIn()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(Typography.headingMedium)
                            Text("Lock In My Gains")
                                .font(Typography.headingMedium)
                        }
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Theme.accentGradient, in: .rect(cornerRadius: 14))
                        .scaleEffect(lockInPulse ? 1.03 : 1.0)
                    }
                    .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
                    .padding(.horizontal, 32)
                }
            }

            Spacer().frame(height: 48)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showResult)
        .onAppear {
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }

    @State private var lockInPulse = false

    private var gameView: some View {
        HStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    if exploded {
                        ForEach(explosionParticles) { particle in
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: particle.size))
                                .foregroundStyle(Theme.gold.opacity(particle.opacity))
                                .offset(x: particle.x, y: particle.y)
                        }
                    } else {
                        VStack(spacing: 4) {
                            ForEach(0...min(currentLevel, 6), id: \.self) { i in
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 28 + CGFloat(i) * 2))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Theme.gold, Theme.amber],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Theme.gold.opacity(0.4), radius: 6)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .scaleEffect(coinScale)
                        .offset(x: shakeAmount)
                    }
                }
                .frame(height: 200)
                .animation(.spring(response: 0.3), value: currentLevel)

                Text(exploded ? "$0" : currentAmount)
                    .font(.system(size: amountFontSize, weight: .black, design: .rounded))
                    .foregroundStyle(
                        exploded
                            ? AnyShapeStyle(Theme.danger)
                            : AnyShapeStyle(LinearGradient(colors: [Theme.gold, Theme.amber], startPoint: .leading, endPoint: .trailing))
                    )
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: currentLevel)
            }

            VStack(spacing: 8) {
                Text("RISK")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.textMuted)
                    .tracking(2)

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.elevated)
                        .frame(width: 24, height: 160)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Theme.danger.opacity(0.6), Theme.danger],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 24, height: 160 * CGFloat(currentRisk) / 100.0)
                        .animation(.spring(response: 0.5), value: currentLevel)
                }

                Text("\(currentRisk)%")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.danger)
                    .contentTransition(.numericText())
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            if exploded {
                Image(systemName: "face.smiling.inverse")
                    .font(Typography.displayLarge)
                    .foregroundStyle(Theme.axisRisk)

                Text("Interesting.")
                    .font(Typography.displayMedium)
                    .foregroundStyle(.white)

                Text("You like to push the limits. 😏")
                    .font(Typography.labelLarge)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Image(systemName: "lock.shield.fill")
                    .font(Typography.displayLarge)
                    .foregroundStyle(Theme.accent)

                Text("Locked in at \(levels[max(0, currentLevel)].amount)")
                    .font(Typography.displaySmall)
                    .foregroundStyle(.white)

                Text("Smart move. You know your limits.")
                    .font(Typography.labelLarge)
                    .foregroundStyle(Theme.textSecondary)
            }

            Button {
                onComplete()
            } label: {
                Text("Continue")
                    .font(Typography.headingMedium)
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Theme.accentGradient, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(SplurjButtonStyle(variant: .primary, size: .large))
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
    }

    private func startGame() {
        isRunning = true
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            lockInPulse = true
        }
        advanceLevel()
    }

    private func advanceLevel() {
        guard isRunning, !lockedIn, !exploded else { return }

        Task {
            try? await Task.sleep(for: .seconds(2))
            guard isRunning, !lockedIn, !exploded else { return }

            if currentLevel + 1 >= levels.count {
                triggerExplosion()
                return
            }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                currentLevel += 1
                coinScale = 1.1
            }

            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            withAnimation(.spring(response: 0.2)) {
                coinScale = 1.0
            }

            if currentLevel >= 3 {
                let intensity = CGFloat(currentLevel) * 1.5
                withAnimation(.spring(response: 0.1).repeatCount(3, autoreverses: true)) {
                    shakeAmount = intensity
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    withAnimation { shakeAmount = 0 }
                }
            }

            advanceLevel()
        }
    }

    private func lockIn() {
        lockedIn = true
        isRunning = false
        let riskValue = levels[currentLevel].riskAxis
        riskScore = riskValue
        dna.riskAxis = max(0, min(1, dna.riskAxis * 0.4 + riskValue * 0.6))

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showResult = true
        }
    }

    private func triggerExplosion() {
        exploded = true
        isRunning = false
        riskScore = 1.0
        dna.riskAxis = max(0, min(1, dna.riskAxis * 0.3 + 0.7))

        var particles: [CoinParticle] = []
        for i in 0..<16 {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 60...150)
            particles.append(CoinParticle(
                id: i,
                x: cos(angle) * distance,
                y: sin(angle) * distance,
                size: CGFloat.random(in: 12...24),
                opacity: Double.random(in: 0.3...0.8)
            ))
        }

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            generator.impactOccurred()
            try? await Task.sleep(for: .milliseconds(100))
            generator.impactOccurred()
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            explosionParticles = particles
        }

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showResult = true
            }
        }
    }
}

struct CoinParticle: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
}
