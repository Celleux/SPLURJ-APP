import UIKit

enum SplurjHaptics {

    static func questComplete() {
        let light = UIImpactFeedbackGenerator(style: .light)
        light.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            light.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        }
    }

    static func scratchReveal() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func scratchContinuous() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
    }

    static func epicReveal() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.impactOccurred(intensity: 0.7)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            heavy.impactOccurred(intensity: 0.85)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            heavy.impactOccurred(intensity: 1.0)
        }
    }

    static func legendaryReveal() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.prepare()
        for i in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                heavy.impactOccurred(intensity: 1.0)
            }
        }
    }

    static func levelUp() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.prepare()
        heavy.impactOccurred(intensity: 0.8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            heavy.impactOccurred(intensity: 0.9)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            heavy.impactOccurred(intensity: 1.0)
        }
    }

    static func bossDefeated() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.prepare()
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                heavy.impactOccurred(intensity: 1.0)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            heavy.impactOccurred(intensity: 1.0)
        }
    }

    static func streakIncrement() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func coinCollect() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.3)
    }

    static func cardTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func cardExpand() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func stepComplete() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func bossDamage() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
    }

    static func swipeComplete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func rewardItemReveal() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 0.7)
    }

    static func microQuestDone() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.6)
    }
}
