import SwiftUI
import SwiftData

nonisolated struct DisplayMessage: Identifiable, Sendable {
    let id: UUID
    let role: CoachMessageRole
    let content: String
    let timestamp: Date
    let isDistortionFlag: Bool

    init(id: UUID = UUID(), role: CoachMessageRole, content: String, timestamp: Date = Date(), isDistortionFlag: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isDistortionFlag = isDistortionFlag
    }
}

@Observable
final class CoachViewModel {
    var messages: [DisplayMessage] = []
    var isTyping: Bool = false
    var sessionActive: Bool = false
    var sessionTimeElapsed: TimeInterval = 0
    var showCrisisOverlay: Bool = false
    var sessionEnded: Bool = false
    var currentSessionID: UUID = UUID()
    var sessionsUsedToday: Int = 0
    var useAI: Bool = false
    var dailyMessageCount: Int = 0
    var showPremiumPrompt: Bool = false
    var hitFreeMessageLimit: Bool = false

    private var sessionTimer: Timer?
    private var nineMinuteWarned = false
    private var pendingFollowUp: String?
    private var lastMessageCountResetDate: Date?

    let maxSessionDuration: TimeInterval = 600
    let maxSessionsPerDay = 5
    let freeMessageLimit = 5
    let softPromptThreshold = 3

    var sessionProgress: Double {
        min(sessionTimeElapsed / maxSessionDuration, 1.0)
    }

    var canStartSession: Bool {
        sessionsUsedToday < maxSessionsPerDay
    }

    var sessionsRemaining: Int {
        max(0, maxSessionsPerDay - sessionsUsedToday)
    }

    func startSession(modelContext: ModelContext) {
        currentSessionID = UUID()
        messages = []
        sessionTimeElapsed = 0
        sessionEnded = false
        sessionActive = true
        nineMinuteWarned = false
        pendingFollowUp = nil

        let disclaimerMsg = DisplayMessage(
            role: .system,
            content: ScriptedCoachTree.disclaimer
        )
        messages.append(disclaimerMsg)

        let session = CoachInteraction.session(sessionNumber: sessionsUsedToday + 1)
        session.id = currentSessionID
        modelContext.insert(session)

        persistMessage(.system, content: ScriptedCoachTree.disclaimer, modelContext: modelContext)

        startSessionTimer(modelContext: modelContext)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.isTyping = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.isTyping = false
                let greeting = DisplayMessage(
                    role: .assistant,
                    content: ScriptedCoachTree.greeting
                )
                self.messages.append(greeting)
                self.persistMessage(.assistant, content: ScriptedCoachTree.greeting, modelContext: modelContext)
            }
        }
    }

    func sendMessage(_ text: String, modelContext: ModelContext, profile: UserProfile?, completedSessions: [CoachInteraction], hasPremium: Bool) {
        guard !sessionEnded, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        resetDailyCountIfNeeded()

        if !hasPremium && dailyMessageCount >= freeMessageLimit {
            hitFreeMessageLimit = true
            return
        }

        let userMessage = DisplayMessage(role: .user, content: text)
        messages.append(userMessage)
        persistMessage(.user, content: text, modelContext: modelContext)

        dailyMessageCount += 1
        saveDailyMessageCount()

        if !hasPremium && dailyMessageCount == softPromptThreshold {
            showPremiumPrompt = true
        }

        if CrisisKeywords.containsCrisisLanguage(text) {
            showCrisisOverlay = true
            return
        }

        if let distortion = DistortionPatterns.detectDistortion(in: text) {
            let flag = DisplayMessage(
                role: .assistant,
                content: "I noticed something — \(distortion.name): \(distortion.correction)",
                isDistortionFlag: true
            )

            isTyping = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.isTyping = false
                self?.messages.append(flag)
                self?.persistMessage(.assistant, content: flag.content, modelContext: modelContext)
            }
            return
        }

        if useAI {
            generateAIResponse(text, modelContext: modelContext, profile: profile, completedSessions: completedSessions)
        } else {
            generateScriptedResponse(text, modelContext: modelContext, profile: profile, completedSessions: completedSessions)
        }
    }

    func endSession(modelContext: ModelContext, profile: UserProfile?) {
        sessionEnded = true
        sessionActive = false
        sessionTimer?.invalidate()
        sessionTimer = nil

        let summary = DisplayMessage(
            role: .assistant,
            content: ScriptedCoachTree.sessionEndingSummary
        )
        messages.append(summary)
        persistMessage(.assistant, content: summary.content, modelContext: modelContext)

        let sessionID = currentSessionID
        let descriptor = FetchDescriptor<CoachInteraction>(
            predicate: #Predicate { $0.typeRaw == "session" && $0.id == sessionID }
        )
        if let session = try? modelContext.fetch(descriptor).first {
            session.endTime = Date()
            if !session.xpAwarded {
                session.xpAwarded = true
                profile?.xpPoints = (profile?.xpPoints ?? 0) + 25
            }
        }

        sessionsUsedToday += 1
    }

    func countTodaySessions(modelContext: ModelContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<CoachInteraction>(
            predicate: #Predicate { $0.typeRaw == "session" && $0.startTime >= startOfDay }
        )
        sessionsUsedToday = (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func loadDailyMessageCount() {
        resetDailyCountIfNeeded()
        dailyMessageCount = UserDefaults.standard.integer(forKey: "coach_daily_message_count")
    }

    private func saveDailyMessageCount() {
        UserDefaults.standard.set(dailyMessageCount, forKey: "coach_daily_message_count")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "coach_message_count_date")
    }

    private func resetDailyCountIfNeeded() {
        let savedTimestamp = UserDefaults.standard.double(forKey: "coach_message_count_date")
        guard savedTimestamp > 0 else { return }
        let savedDate = Date(timeIntervalSince1970: savedTimestamp)
        if !Calendar.current.isDateInToday(savedDate) {
            dailyMessageCount = 0
            UserDefaults.standard.set(0, forKey: "coach_daily_message_count")
        }
    }

    var freeMessagesRemaining: Int {
        max(0, freeMessageLimit - dailyMessageCount)
    }

    func checkAIAvailability() {
        if #available(iOS 26.0, *) {
            useAI = checkFoundationModelAvailability()
        } else {
            useAI = false
        }
    }

    @available(iOS 26.0, *)
    private func checkFoundationModelAvailability() -> Bool {
        return false
    }

    private func generateScriptedResponse(_ text: String, modelContext: ModelContext, profile: UserProfile?, completedSessions: [CoachInteraction]) {
        isTyping = true

        let (response, followUp) = ScriptedCoachTree.findResponse(for: text)

        var contextualAddition = ""
        let completedCount = completedSessions.filter { $0.isCompleted }.count
        if completedCount > 0 && Bool.random() {
            contextualAddition = "\n\nBy the way, I see you've completed \(completedCount) curriculum session\(completedCount == 1 ? "" : "s"). That's great progress!"
        }

        let finalResponse = response + contextualAddition
        pendingFollowUp = followUp

        let delay = Double.random(in: 1.2...2.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.isTyping = false

            let msg = DisplayMessage(role: .assistant, content: finalResponse)
            self.messages.append(msg)
            self.persistMessage(.assistant, content: finalResponse, modelContext: modelContext)

            if let followUp = self.pendingFollowUp {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isTyping = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.isTyping = false
                        let followUpMsg = DisplayMessage(role: .assistant, content: followUp)
                        self.messages.append(followUpMsg)
                        self.persistMessage(.assistant, content: followUp, modelContext: modelContext)
                        self.pendingFollowUp = nil
                    }
                }
            }
        }
    }

    private func generateAIResponse(_ text: String, modelContext: ModelContext, profile: UserProfile?, completedSessions: [CoachInteraction]) {
        if #available(iOS 26.0, *) {
            Task {
                await generateWithFoundationModels(text, modelContext: modelContext, profile: profile, completedSessions: completedSessions)
            }
        } else {
            generateScriptedResponse(text, modelContext: modelContext, profile: profile, completedSessions: completedSessions)
        }
    }

    @available(iOS 26.0, *)
    private func generateWithFoundationModels(_ text: String, modelContext: ModelContext, profile: UserProfile?, completedSessions: [CoachInteraction]) async {
        generateScriptedResponse(text, modelContext: modelContext, profile: profile, completedSessions: completedSessions)
    }

    private func startSessionTimer(modelContext: ModelContext) {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.sessionTimeElapsed += 1

                if self.sessionTimeElapsed >= 540 && !self.nineMinuteWarned {
                    self.nineMinuteWarned = true
                    let warning = DisplayMessage(
                        role: .system,
                        content: ScriptedCoachTree.nineMinuteWarning
                    )
                    self.messages.append(warning)
                    self.persistMessage(.system, content: warning.content, modelContext: modelContext)
                }

                if self.sessionTimeElapsed >= self.maxSessionDuration {
                    self.endSession(modelContext: modelContext, profile: nil)
                }
            }
        }
    }

    private func persistMessage(_ role: CoachMessageRole, content: String, modelContext: ModelContext) {
        let msg = CoachInteraction.message(role: role, content: content, sessionID: currentSessionID)
        modelContext.insert(msg)
    }
}
