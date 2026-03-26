import Foundation

struct ChallengeLivesEngine {

    static func processCheckIn(participant: inout ChallengeParticipant, didHold: Bool, challengeDay: Int) {
        participant.totalCheckIns += 1

        if didHold {
            participant.successfulCheckIns += 1
            participant.currentStreak += 1
            participant.longestStreak = max(participant.longestStreak, participant.currentStreak)
            participant.status = "active"

            if participant.currentStreak == 7 {
                awardBonusLife(&participant)
            }
            if participant.currentStreak == 14 {
                awardBonusLife(&participant)
            }

            if challengeDay == 7 {
                awardStreakShield(&participant)
            }
            if challengeDay == 21 {
                awardStreakShield(&participant)
            }
        } else {
            if participant.shieldActiveToday {
                participant.shieldActiveToday = false
                participant.streakShieldsAvailable -= 1
            } else {
                participant.currentStreak = 0
                participant.livesRemaining -= 1

                if participant.livesRemaining <= 0 && participant.status == "onThinIce" {
                    participant.status = "eliminated"
                    participant.eliminationDate = Date()
                    generateExitSummary(&participant)
                } else if participant.livesRemaining <= 0 {
                    participant.status = "onThinIce"
                } else {
                    participant.status = "slipped"
                }
            }
        }
    }

    static func processMidnightMiss(participant: inout ChallengeParticipant) {
        processCheckIn(participant: &participant, didHold: false, challengeDay: 0)
    }

    static func coverFriend(giver: inout ChallengeParticipant, receiver: inout ChallengeParticipant) -> Bool {
        guard giver.livesRemaining >= 2 else { return false }
        guard !giver.hasCoveredFriendIDs.contains(receiver.id) else { return false }

        giver.livesRemaining -= 1
        giver.hasCoveredFriendIDs.append(receiver.id)

        receiver.livesRemaining += 1
        receiver.wasCoveredToday = true

        if receiver.status == "onThinIce" {
            receiver.status = "active"
        }

        return true
    }

    static func activateShield(participant: inout ChallengeParticipant) -> Bool {
        guard participant.streakShieldsAvailable > 0 else { return false }
        participant.shieldActiveToday = true
        participant.status = "shielded"
        return true
    }

    private static func awardBonusLife(_ p: inout ChallengeParticipant) {
        if p.livesRemaining < 5 {
            p.livesRemaining += 1
        }
    }

    private static func awardStreakShield(_ p: inout ChallengeParticipant) {
        if p.streakShieldsAvailable < 2 {
            p.streakShieldsAvailable += 1
        }
    }

    static func generateExitSummary(_ p: inout ChallengeParticipant) {
        let summary: [String: Any] = [
            "daysCompleted": p.totalCheckIns,
            "successfulDays": p.successfulCheckIns,
            "bestStreak": p.longestStreak,
            "completionRate": p.completionRate
        ]
        if let data = try? JSONSerialization.data(withJSONObject: summary),
           let json = String(data: data, encoding: .utf8) {
            p.exitSummary = json
        }
    }

    static func voluntaryQuit(participant: inout ChallengeParticipant) {
        participant.status = "spectator"
        participant.eliminationDate = Date()
        generateExitSummary(&participant)
    }

    static func completeChallenge(participants: [ChallengeParticipant]) {
        for p in participants where p.isActive {
            p.status = "completed"
        }
    }

    static func transferCaptain(from creator: ChallengeParticipant, allParticipants: [ChallengeParticipant]) -> ChallengeParticipant? {
        creator.isCreator = false
        let candidate = allParticipants
            .filter { $0.isActive && $0.id != creator.id }
            .sorted { $0.longestStreak > $1.longestStreak }
            .first
        candidate?.isCreator = true
        return candidate
    }
}
