import Foundation
import SwiftData

@Model
class UserProfile {
    var name: String
    var startDate: Date
    var dailyImpulseAmount: Double
    var currentStreak: Int
    var longestStreak: Int
    var totalSaved: Double
    var selectedGoals: [String]
    var lastCheckInDate: Date?
    var selectedReason: String
    var hourlyRate: Double
    var simpleMode: Bool
    var highContrastMode: Bool
    var gentleViewMode: Bool
    var notificationStyle: String
    var adhdMode: Bool
    var xpPoints: Int
    var phantomProgressApplied: Bool
    var graceUsedThisMonth: Bool
    var lastGraceReset: Date
    var lastReactionType: String
    var lastReactionDate: Date?
    var totalConsciousChoices: Int
    var dailyPledgeTime: Int
    var eveningReflectionTime: Int
    var lastPGSIPromptDate: Date?
    var referralCode: String
    var notificationsEnabled: Bool
    var morningPledgeNotif: Bool
    var eveningReflectionNotif: Bool
    var weeklyPaycheckNotif: Bool
    var streakMaintenanceNotif: Bool
    var milestoneApproachingNotif: Bool
    var emaMorningNotif: Bool
    var emaAfternoonNotif: Bool
    var emaEveningNotif: Bool
    var midDayIntentionNotif: Bool
    var jitaiAdaptiveNotif: Bool
    var curriculumReminderNotif: Bool
    var reEngagementNotif: Bool
    var emaMorningTime: Int
    var emaAfternoonTime: Int
    var emaEveningTime: Int
    var midDayIntentionTime: Int
    var midDayIntentionMinute: Int
    var quietHoursEnabled: Bool
    var quietHoursStart: Int
    var quietHoursEnd: Int
    var lastOpenDate: Date
    var hasShownNotificationPrompt: Bool
    var lastCurriculumReminderDate: Date?
    var defaultCurrency: String
    var defaultBudgetMethod: String
    var firstDayOfMonth: Int
    var billRemindersEnabled: Bool
    var budgetAlert50: Bool
    var budgetAlert80: Bool
    var budgetAlert100: Bool
    var dailyCheckInNotif: Bool
    var weeklyDigestNotif: Bool
    var userPathRaw: String
    var currencySymbol: String
    var installDate: Date

    // Splurj v2 personalization (set during SplurjOnboardingFlow)
    var splurjVariantRaw: String?
    var splurjArchetypeRaw: String?
    var splurjLevel: Int
    var equippedCosmeticIDs: [String]
    var earnedBadgeIDs: [String]

    var userPath: UserPath {
        get { UserPath(rawValue: userPathRaw) ?? .generalSaver }
        set { userPathRaw = newValue.rawValue }
    }

    init(
        name: String,
        dailyImpulseAmount: Double = 25.0,
        selectedGoals: [String] = [],
        selectedReason: String = "spend",
        userPath: UserPath = .generalSaver,
        currencyCode: String = "USD",
        currencySymbol: String = "$"
    ) {
        self.name = name
        self.startDate = Date()
        self.dailyImpulseAmount = dailyImpulseAmount
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalSaved = 0
        self.selectedGoals = selectedGoals
        self.lastCheckInDate = nil
        self.selectedReason = selectedReason
        self.hourlyRate = 20.0
        self.simpleMode = false
        self.highContrastMode = false
        self.gentleViewMode = false
        self.notificationStyle = "standard"
        self.adhdMode = false
        self.xpPoints = 0
        self.phantomProgressApplied = false
        self.graceUsedThisMonth = false
        self.lastGraceReset = Date()
        self.lastReactionType = ""
        self.lastReactionDate = nil
        self.totalConsciousChoices = 0
        self.dailyPledgeTime = 8
        self.eveningReflectionTime = 21
        self.lastPGSIPromptDate = nil
        self.referralCode = Self.generateReferralCode()
        self.notificationsEnabled = false
        self.morningPledgeNotif = true
        self.eveningReflectionNotif = true
        self.weeklyPaycheckNotif = true
        self.streakMaintenanceNotif = true
        self.milestoneApproachingNotif = true
        self.emaMorningNotif = true
        self.emaAfternoonNotif = true
        self.emaEveningNotif = true
        self.midDayIntentionNotif = true
        self.jitaiAdaptiveNotif = true
        self.curriculumReminderNotif = true
        self.reEngagementNotif = true
        self.emaMorningTime = 9
        self.emaAfternoonTime = 13
        self.emaEveningTime = 19
        self.midDayIntentionTime = 12
        self.midDayIntentionMinute = 30
        self.quietHoursEnabled = false
        self.quietHoursStart = 22
        self.quietHoursEnd = 7
        self.lastOpenDate = Date()
        self.hasShownNotificationPrompt = false
        self.lastCurriculumReminderDate = nil
        self.defaultCurrency = "USD"
        self.defaultBudgetMethod = "50/30/20"
        self.firstDayOfMonth = 1
        self.billRemindersEnabled = true
        self.budgetAlert50 = true
        self.budgetAlert80 = true
        self.budgetAlert100 = true
        self.dailyCheckInNotif = true
        self.weeklyDigestNotif = true
        self.userPathRaw = userPath.rawValue
        self.currencySymbol = currencySymbol
        self.installDate = Date()
        self.splurjVariantRaw = nil
        self.splurjArchetypeRaw = nil
        self.splurjLevel = 1
        self.equippedCosmeticIDs = []
        self.earnedBadgeIDs = []
    }

    private static func generateReferralCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return "SP-" + String((0..<6).map { _ in chars.randomElement()! })
    }
}
