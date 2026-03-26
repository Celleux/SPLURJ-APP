import Foundation

nonisolated enum UserPath: String, CaseIterable, Codable, Sendable {
    case impulseShopper
    case gambling
    case adhd
    case generalSaver

    var title: String {
        switch self {
        case .impulseShopper: "I spend too much"
        case .gambling: "Gambling is affecting my finances"
        case .adhd: "ADHD makes money hard"
        case .generalSaver: "I just want to save more"
        }
    }

    var subtitle: String {
        switch self {
        case .impulseShopper: "Impulse buying, emotional spending, living paycheck to paycheck"
        case .gambling: "Sports betting, online gambling, or casino spending"
        case .adhd: "Forgetting bills, impulsive purchases, can't stick to a budget"
        case .generalSaver: "No crisis — I want smarter habits and better tools"
        }
    }

    var emoji: String {
        switch self {
        case .impulseShopper: "💸"
        case .gambling: "🎰"
        case .adhd: "🧠"
        case .generalSaver: "🌱"
        }
    }

    var displayName: String {
        switch self {
        case .impulseShopper: "Impulse Shopper"
        case .gambling: "Gambling"
        case .adhd: "ADHD"
        case .generalSaver: "General Saver"
        }
    }

    var notificationBenefit: String {
        switch self {
        case .impulseShopper: "We'll remind you to pause before big purchases"
        case .adhd: "Bill reminders so nothing slips through the cracks"
        case .gambling: "Check-in reminders to stay on track"
        case .generalSaver: "Weekly savings updates and streak reminders"
        }
    }
}
