import SwiftUI

enum CeremonyType: Equatable {
    case questReward(QuestReward)
    case cardReveal(CardRarity, String, String)
    case levelUp(oldLevel: Int, newLevel: Int)
    case streakMilestone(days: Int)
    case bossDefeat(zone: QuestZone)

    static func == (lhs: CeremonyType, rhs: CeremonyType) -> Bool {
        switch (lhs, rhs) {
        case (.questReward, .questReward): return true
        case (.cardReveal, .cardReveal): return true
        case (.levelUp, .levelUp): return true
        case (.streakMilestone, .streakMilestone): return true
        case (.bossDefeat, .bossDefeat): return true
        default: return false
        }
    }
}

@Observable
class CeremonyOverlayManager {
    static let shared = CeremonyOverlayManager()

    var currentCeremony: CeremonyType?
    var isPresenting: Bool = false
    private var queue: [CeremonyType] = []

    private init() {}

    func enqueue(_ ceremony: CeremonyType) {
        if isPresenting {
            queue.append(ceremony)
        } else {
            present(ceremony)
        }
    }

    func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            isPresenting = false
            currentCeremony = nil
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.dequeueNext()
        }
    }

    private func present(_ ceremony: CeremonyType) {
        currentCeremony = ceremony
        withAnimation(.easeOut(duration: 0.2)) {
            isPresenting = true
        }
    }

    private func dequeueNext() {
        guard !queue.isEmpty else { return }
        let next = queue.removeFirst()
        present(next)
    }
}
