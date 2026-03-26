import SwiftUI
import StoreKit

@Observable
final class AppReviewManager {
    static let shared = AppReviewManager()

    private let maxReviewRequests = 3
    private let minimumDaysBetweenRequests = 60
    private let minimumActiveDays = 7
    private let minimumCompletedQuests = 5

    @ObservationIgnored
    @AppStorage("lastReviewRequestDate") private var lastReviewRequestDateTimestamp: Double = 0

    @ObservationIgnored
    @AppStorage("reviewRequestCount") private var reviewRequestCount: Int = 0

    @ObservationIgnored
    @AppStorage("totalCompletedQuestsEver") private var totalCompletedQuests: Int = 0

    @ObservationIgnored
    @AppStorage("firstAppOpenDate") private var firstAppOpenDateTimestamp: Double = 0

    private init() {
        if firstAppOpenDateTimestamp == 0 {
            firstAppOpenDateTimestamp = Date().timeIntervalSince1970
        }
    }

    func recordQuestCompletion() {
        totalCompletedQuests += 1
    }

    var canRequestReview: Bool {
        guard reviewRequestCount < maxReviewRequests else { return false }
        guard totalCompletedQuests >= minimumCompletedQuests else { return false }

        let activeDays = Int(Date().timeIntervalSince1970 - firstAppOpenDateTimestamp) / 86400
        guard activeDays >= minimumActiveDays else { return false }

        if lastReviewRequestDateTimestamp > 0 {
            let daysSinceLastRequest = Int(Date().timeIntervalSince1970 - lastReviewRequestDateTimestamp) / 86400
            guard daysSinceLastRequest >= minimumDaysBetweenRequests else { return false }
        }

        return true
    }

    func requestReviewIfAppropriate() {
        guard canRequestReview else { return }

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }

        SKStoreReviewController.requestReview(in: windowScene)
        lastReviewRequestDateTimestamp = Date().timeIntervalSince1970
        reviewRequestCount += 1
    }

    func requestReviewAfterDelay(seconds: Double = 1.5) {
        guard canRequestReview else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.requestReviewIfAppropriate()
        }
    }
}
