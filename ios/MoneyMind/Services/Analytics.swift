import Foundation

// MARK: - Analytics
//
// Brief Chunk 10: "analytics events". This is the seam — a typed event
// enum + a pluggable Tracker protocol so call sites don't care whether
// the destination is Mixpanel, Amplitude, PostHog, or (default) console
// logs.

public enum AnalyticsEvent: Sendable {
    case onboardingStepShown(step: Int)
    case onboardingVariantChosen(variant: String)
    case onboardingDnaAnswered(answer: String)
    case onboardingPaywallShown
    case onboardingPaywallPlanSelected(plan: String)
    case onboardingCompleted(variant: String, dna: String, plan: String)

    case mascotTapped(stage: String, mood: String)
    case mascotLevelUp(fromStage: String, toStage: String)

    case homeCommandTapped(action: String)

    case coachSOSTriggered(reason: String)
    case coachSOSBreathe
    case coachSOSHoldAdded(amount: Double, merchant: String)
    case coachSOSBuyAnyway(amount: Double, merchant: String)

    case pactStarted(type: String, partnerCount: Int)
    case pactJoined(code: String)
    case pactInviteSent

    case plaidLinkAttempted
    case plaidLinkSucceeded(connectionID: String)
    case plaidLinkFailed(error: String)

    case healthAuthRequested
    case healthAuthGranted
    case healthAuthDenied

    var name: String {
        switch self {
        case .onboardingStepShown: "onboarding_step_shown"
        case .onboardingVariantChosen: "onboarding_variant_chosen"
        case .onboardingDnaAnswered: "onboarding_dna_answered"
        case .onboardingPaywallShown: "onboarding_paywall_shown"
        case .onboardingPaywallPlanSelected: "onboarding_paywall_plan_selected"
        case .onboardingCompleted: "onboarding_completed"
        case .mascotTapped: "mascot_tapped"
        case .mascotLevelUp: "mascot_level_up"
        case .homeCommandTapped: "home_command_tapped"
        case .coachSOSTriggered: "coach_sos_triggered"
        case .coachSOSBreathe: "coach_sos_breathe"
        case .coachSOSHoldAdded: "coach_sos_hold_added"
        case .coachSOSBuyAnyway: "coach_sos_buy_anyway"
        case .pactStarted: "pact_started"
        case .pactJoined: "pact_joined"
        case .pactInviteSent: "pact_invite_sent"
        case .plaidLinkAttempted: "plaid_link_attempted"
        case .plaidLinkSucceeded: "plaid_link_succeeded"
        case .plaidLinkFailed: "plaid_link_failed"
        case .healthAuthRequested: "health_auth_requested"
        case .healthAuthGranted: "health_auth_granted"
        case .healthAuthDenied: "health_auth_denied"
        }
    }

    var properties: [String: String] {
        switch self {
        case .onboardingStepShown(let s): ["step": "\(s)"]
        case .onboardingVariantChosen(let v): ["variant": v]
        case .onboardingDnaAnswered(let a): ["answer": a]
        case .onboardingPaywallShown: [:]
        case .onboardingPaywallPlanSelected(let p): ["plan": p]
        case .onboardingCompleted(let v, let d, let p): ["variant": v, "dna": d, "plan": p]
        case .mascotTapped(let s, let m): ["stage": s, "mood": m]
        case .mascotLevelUp(let f, let t): ["from": f, "to": t]
        case .homeCommandTapped(let a): ["action": a]
        case .coachSOSTriggered(let r): ["reason": r]
        case .coachSOSBreathe: [:]
        case .coachSOSHoldAdded(let amt, let m): ["amount": "\(amt)", "merchant": m]
        case .coachSOSBuyAnyway(let amt, let m): ["amount": "\(amt)", "merchant": m]
        case .pactStarted(let t, let c): ["type": t, "partners": "\(c)"]
        case .pactJoined(let c): ["code": c]
        case .pactInviteSent: [:]
        case .plaidLinkAttempted: [:]
        case .plaidLinkSucceeded(let id): ["connection_id": id]
        case .plaidLinkFailed(let e): ["error": e]
        case .healthAuthRequested, .healthAuthGranted, .healthAuthDenied: [:]
        }
    }
}

public protocol AnalyticsTracker: Sendable {
    func track(_ event: AnalyticsEvent)
}

public enum Analytics {
    public static var tracker: AnalyticsTracker = ConsoleTracker()

    public static func track(_ event: AnalyticsEvent) {
        tracker.track(event)
    }
}

/// Default tracker — logs to the console. Swap for a Mixpanel / PostHog
/// / Amplitude tracker in production by assigning to `Analytics.tracker`.
public struct ConsoleTracker: AnalyticsTracker {
    public init() {}
    public func track(_ event: AnalyticsEvent) {
        #if DEBUG
        print("[analytics] \(event.name) \(event.properties)")
        #endif
    }
}
