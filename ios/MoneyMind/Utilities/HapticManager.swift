import UIKit

enum HapticManager {

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func coinSave() {
        impact(.medium)
        SoundManager.shared.play(.coinSave)
    }

    static func questComplete() {
        notification(.success)
        SoundManager.shared.play(.success)
    }

    static func levelUp() {
        notification(.success)
        SoundManager.shared.play(.levelUp)
    }

    static func buttonTap() {
        impact(.light)
    }

    static func tabSwitch() {
        impact(.light)
    }

    static func cardScratch() {
        impact(.light)
        SoundManager.shared.play(.cardScratch)
    }

    static func epicReveal() {
        impact(.heavy)
        SoundManager.shared.play(.epicReveal)
    }

    static func streakMilestone() {
        notification(.success)
        SoundManager.shared.play(.success)
    }
}
