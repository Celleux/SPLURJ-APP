import Foundation
import CloudKit

class ChallengeCloudKitService {
    static let shared = ChallengeCloudKitService()

    private let container = CKContainer.default()
    private var database: CKDatabase { container.publicCloudDatabase }

    private let ParticipantRecordType = "ChallengeParticipant"
    private let CheckInRecordType = "ChallengeCheckIn"
    private let NudgeRecordType = "ChallengeNudge"

    // MARK: - Participant

    func saveParticipant(_ participant: ChallengeParticipant) async throws {
        let record = CKRecord(recordType: ParticipantRecordType, recordID: CKRecord.ID(recordName: participant.id))
        record["challengeID"] = participant.challengeID
        record["userID"] = participant.userID
        record["displayName"] = participant.displayName
        record["emoji"] = participant.emoji
        record["joinedDate"] = participant.joinedDate
        record["livesRemaining"] = participant.livesRemaining
        record["streakShieldsAvailable"] = participant.streakShieldsAvailable
        record["shieldActiveToday"] = participant.shieldActiveToday ? 1 : 0
        record["status"] = participant.status
        record["currentStreak"] = participant.currentStreak
        record["longestStreak"] = participant.longestStreak
        record["totalCheckIns"] = participant.totalCheckIns
        record["successfulCheckIns"] = participant.successfulCheckIns
        record["hasCoveredFriendIDs"] = participant.hasCoveredFriendIDs
        record["wasCoveredToday"] = participant.wasCoveredToday ? 1 : 0
        record["eliminationDate"] = participant.eliminationDate
        record["exitSummary"] = participant.exitSummary
        record["lastCheckInDate"] = participant.lastCheckInDate
        record["isCreator"] = participant.isCreator ? 1 : 0
        try await database.save(record)
    }

    func fetchParticipants(for challengeID: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "challengeID == %@", challengeID)
        let query = CKQuery(recordType: ParticipantRecordType, predicate: predicate)
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { try? $0.1.get() }
    }

    func applyParticipantRecord(_ record: CKRecord, to participant: ChallengeParticipant) {
        participant.livesRemaining = record["livesRemaining"] as? Int ?? 3
        participant.streakShieldsAvailable = record["streakShieldsAvailable"] as? Int ?? 0
        participant.shieldActiveToday = (record["shieldActiveToday"] as? Int ?? 0) == 1
        participant.status = record["status"] as? String ?? "active"
        participant.currentStreak = record["currentStreak"] as? Int ?? 0
        participant.longestStreak = record["longestStreak"] as? Int ?? 0
        participant.totalCheckIns = record["totalCheckIns"] as? Int ?? 0
        participant.successfulCheckIns = record["successfulCheckIns"] as? Int ?? 0
        participant.hasCoveredFriendIDs = record["hasCoveredFriendIDs"] as? [String] ?? []
        participant.wasCoveredToday = (record["wasCoveredToday"] as? Int ?? 0) == 1
        participant.eliminationDate = record["eliminationDate"] as? Date
        participant.exitSummary = record["exitSummary"] as? String
        participant.lastCheckInDate = record["lastCheckInDate"] as? Date
        participant.isCreator = (record["isCreator"] as? Int ?? 0) == 1
    }

    // MARK: - Check-In

    func saveCheckIn(_ checkIn: ChallengeCheckIn) async throws {
        let record = CKRecord(recordType: CheckInRecordType, recordID: CKRecord.ID(recordName: checkIn.id))
        record["challengeID"] = checkIn.challengeID
        record["participantID"] = checkIn.participantID
        record["date"] = checkIn.date
        record["didHold"] = checkIn.didHold ? 1 : 0
        record["note"] = checkIn.note
        record["amountSaved"] = checkIn.amountSaved
        record["reactions"] = checkIn.reactions
        record["livesLost"] = checkIn.livesLost
        record["shieldUsed"] = checkIn.shieldUsed ? 1 : 0
        try await database.save(record)
    }

    func fetchCheckIns(for challengeID: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "challengeID == %@", challengeID)
        let query = CKQuery(recordType: CheckInRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { try? $0.1.get() }
    }

    // MARK: - Nudge

    func saveNudge(_ nudge: ChallengeNudge) async throws {
        let record = CKRecord(recordType: NudgeRecordType, recordID: CKRecord.ID(recordName: nudge.id))
        record["challengeID"] = nudge.challengeID
        record["senderName"] = nudge.senderName
        record["senderEmoji"] = nudge.senderEmoji
        record["receiverName"] = nudge.receiverName
        record["date"] = nudge.date
        record["type"] = nudge.type
        try await database.save(record)
    }

    func fetchNudges(for challengeID: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "challengeID == %@", challengeID)
        let query = CKQuery(recordType: NudgeRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { try? $0.1.get() }
    }

    func fetchNudges(for challengeID: String, receiver: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "challengeID == %@ AND receiverName == %@", challengeID, receiver)
        let query = CKQuery(recordType: NudgeRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { try? $0.1.get() }
    }

    // MARK: - Update Check-In Reactions

    func updateCheckInReactions(checkInID: String, reactions: [String]) async throws {
        let recordID = CKRecord.ID(recordName: checkInID)
        let record = try await database.record(for: recordID)
        record["reactions"] = reactions
        try await database.save(record)
    }
}
