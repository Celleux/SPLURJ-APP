import Foundation

nonisolated enum CrisisKeywords: Sendable {
    static let phrases: [String] = [
        "suicide", "kill myself", "end it all", "no reason to live",
        "self-harm", "want to die", "can't go on", "what's the point",
        "nobody cares", "better off without me", "hurt myself",
        "don't want to be here", "ending it", "no way out"
    ]

    static func containsCrisisLanguage(_ text: String) -> Bool {
        let lower = text.lowercased()
        return phrases.contains { lower.contains($0) }
    }
}

nonisolated struct GamblingDistortion: Sendable {
    let pattern: String
    let name: String
    let correction: String
}

nonisolated enum DistortionPatterns: Sendable {
    static let all: [GamblingDistortion] = [
        GamblingDistortion(
            pattern: "due for a win",
            name: "Gambler's Fallacy",
            correction: "Each event is independent. Past losses don't increase future chances of winning. The odds reset every time."
        ),
        GamblingDistortion(
            pattern: "i have a system",
            name: "Illusion of Control",
            correction: "Games of chance can't be controlled by any system. The house edge is mathematical and consistent regardless of strategy."
        ),
        GamblingDistortion(
            pattern: "almost won",
            name: "Near-Miss Bias",
            correction: "A near-miss is still a loss. Our brains treat 'almost winning' as encouraging, but the outcome is the same as any other loss."
        ),
        GamblingDistortion(
            pattern: "just one more",
            name: "Chasing Losses",
            correction: "Chasing losses is how small losses become devastating ones. The urge to 'win it back' is one of the strongest and most dangerous impulses."
        ),
        GamblingDistortion(
            pattern: "feeling lucky",
            name: "Superstitious Thinking",
            correction: "Luck isn't a real force that influences outcomes. Random events don't respond to feelings, rituals, or patterns."
        ),
        GamblingDistortion(
            pattern: "win it back",
            name: "Chasing Losses",
            correction: "The money lost is gone. Trying to recover it through more gambling statistically leads to greater losses."
        ),
        GamblingDistortion(
            pattern: "hot streak",
            name: "Hot Hand Fallacy",
            correction: "Past wins don't predict future wins. Each event is independent. A 'streak' is just a pattern our brains impose on randomness."
        ),
        GamblingDistortion(
            pattern: "know when to stop",
            name: "Overconfidence Bias",
            correction: "Most people overestimate their ability to stop. The neurochemistry of gambling makes it harder to quit while ahead than we expect."
        )
    ]

    static func detectDistortion(in text: String) -> GamblingDistortion? {
        let lower = text.lowercased()
        return all.first { lower.contains($0.pattern) }
    }
}

nonisolated struct ScriptedResponse: Sendable {
    let triggers: [String]
    let response: String
    let followUp: String?
}

nonisolated enum ScriptedCoachTree: Sendable {
    static let greeting = "Welcome to your coaching session. I'm here to help you explore your relationship with money in a supportive, non-judgmental space. What's on your mind today?"

    static let disclaimer = "I'm an AI wellness coach, not a therapist. If you're in crisis, tap SOS anytime."

    static let sessionEndingSummary = "Our time is wrapping up. You showed real courage today by reflecting on your experiences. Remember: every moment of awareness is a step forward. Take one insight from today and carry it with you."

    static let nineMinuteWarning = "We have about a minute left in this session. Is there anything important you'd like to share before we wrap up?"

    static let responses: [ScriptedResponse] = [
        ScriptedResponse(
            triggers: ["urge", "craving", "want to gamble", "want to spend", "tempted"],
            response: "It sounds like you're experiencing an urge right now. That takes real awareness to notice. Urges are like waves — they rise, peak, and fall. On a scale of 0-10, how intense is this urge?",
            followUp: "Whatever number it is, that's okay. The urge will naturally decrease if you don't act on it. Would you like to try the Urge Surf tool, or talk through what triggered this feeling?"
        ),
        ScriptedResponse(
            triggers: ["stressed", "anxious", "worried", "overwhelmed", "panic"],
            response: "I hear that you're feeling stressed. Your feelings are completely valid. Let's take a moment — can you take three slow, deep breaths with me? In for 4 seconds, hold for 4, out for 4.",
            followUp: "How are you feeling now? Sometimes just pausing helps. Would it help to explore what's driving the stress, or would you prefer a grounding exercise?"
        ),
        ScriptedResponse(
            triggers: ["relapse", "gave in", "failed", "slipped", "messed up"],
            response: "Thank you for being honest about this. It takes genuine courage to share that. A slip doesn't erase your progress — it's information about what you need. Recovery isn't a straight line.",
            followUp: "Can you walk me through what happened? Understanding the sequence — trigger, thought, feeling, action — helps us build better strategies for next time."
        ),
        ScriptedResponse(
            triggers: ["bored", "nothing to do", "lonely"],
            response: "Boredom and loneliness are two of the most common triggers. Your brain is looking for stimulation, and old habits offer a quick fix. What's one thing you enjoy that you haven't done in a while?",
            followUp: "Building a list of alternative activities is one of the most effective strategies. Even small things — a walk, a podcast, calling someone — can redirect that energy."
        ),
        ScriptedResponse(
            triggers: ["money", "debt", "bills", "broke", "financial"],
            response: "Financial stress is incredibly difficult. It can feel like a weight that never lifts. But you're here, working on it, and that matters. Would you like to talk about what's causing the most pressure right now?",
            followUp: "Sometimes breaking big financial worries into smaller, actionable steps makes them feel more manageable. What's one small thing you could do this week?"
        ),
        ScriptedResponse(
            triggers: ["proud", "good", "happy", "win", "saved", "resisted"],
            response: "That's wonderful! You should feel proud — that took real strength. Every time you make a conscious choice, you're literally rewiring your brain. How does it feel to recognize that win?",
            followUp: "Savoring positive moments like this is important. Your brain needs to register that choosing differently feels good too. Would you like to log this win in your wallet?"
        ),
        ScriptedResponse(
            triggers: ["angry", "frustrated", "mad"],
            response: "Anger is a powerful emotion, and it's often masking something underneath — hurt, fear, or feeling out of control. It's okay to feel angry. What happened that brought this on?",
            followUp: "When we understand what's beneath the anger, we can address the real need. Would a HALT check help right now to see what might be driving this?"
        ),
        ScriptedResponse(
            triggers: ["can't sleep", "insomnia", "nighttime", "late night"],
            response: "Late nights can be a vulnerable time. The quiet and lack of distraction can amplify urges. You're smart to reach out instead of acting on impulse. What's keeping you up?",
            followUp: "A brief breathing exercise might help settle your mind. Or we could talk through what's weighing on you. What feels right?"
        ),
        ScriptedResponse(
            triggers: ["relationship", "partner", "family", "friend"],
            response: "Relationships are deeply connected to how we handle money and stress. It takes courage to reflect on how our patterns affect the people we care about. What's going on?",
            followUp: "Sometimes our loved ones are affected by our struggles in ways we don't fully see. Would it help to think about how to have an honest conversation with them?"
        ),
        ScriptedResponse(
            triggers: ["help", "what should i do", "advice", "lost"],
            response: "You've already taken an important step by being here and asking. Let me understand what you're dealing with — can you tell me more about what's going on right now?",
            followUp: "Based on what you've shared, we have some great tools available. Would you like to explore them, or would it help to keep talking through this?"
        )
    ]

    static let defaultResponse = "Thank you for sharing that. Can you tell me more about what you're experiencing? Understanding the full picture helps us find the best path forward."

    static let defaultFollowUp = "Remember, there's no wrong answer here. This is your space to explore and reflect."

    static func findResponse(for text: String) -> (String, String?) {
        let lower = text.lowercased()
        for scripted in responses {
            if scripted.triggers.contains(where: { lower.contains($0) }) {
                return (scripted.response, scripted.followUp)
            }
        }
        return (defaultResponse, defaultFollowUp)
    }
}


nonisolated struct ACTExerciseStep: Sendable {
    let instruction: String
    let prompt: String?
    let isReflection: Bool
}

nonisolated enum ACTContent: Sendable {
    static let valuesSteps: [ACTExerciseStep] = [
        ACTExerciseStep(
            instruction: "Values are directions, not destinations. They're about who you want to be, not what you want to have.",
            prompt: "What matters most to you about money? Not how much — but what role do you want it to play in your life?",
            isReflection: true
        ),
        ACTExerciseStep(
            instruction: "Consider these areas of life. Rate how important each is to you (1-10):",
            prompt: nil,
            isReflection: false
        ),
        ACTExerciseStep(
            instruction: "Now think about your recent actions. Are they moving you toward or away from what matters?",
            prompt: "What's one thing you did this week that aligned with your values?",
            isReflection: true
        ),
        ACTExerciseStep(
            instruction: "A committed action is a concrete step you take based on your values, even when it's uncomfortable.",
            prompt: "Complete this: 'This week, I commit to ___ because ___ matters to me.'",
            isReflection: true
        )
    ]

    static let valuesAreas = [
        "Family & Relationships",
        "Financial Security",
        "Personal Growth",
        "Health & Wellbeing",
        "Freedom & Independence",
        "Generosity & Giving"
    ]

    static let defusionSteps: [ACTExerciseStep] = [
        ACTExerciseStep(
            instruction: "Our minds constantly produce thoughts. Some are helpful, some aren't. The goal isn't to stop thoughts — it's to change your relationship with them.",
            prompt: "What unhelpful thought about money or spending keeps showing up for you?",
            isReflection: true
        ),
        ACTExerciseStep(
            instruction: "Now, take that thought and add this prefix: 'I notice I'm having the thought that...'",
            prompt: nil,
            isReflection: false
        ),
        ACTExerciseStep(
            instruction: "Say it again, but this time: 'My mind is telling me that...'",
            prompt: "How does the thought feel different with this distance? Does it feel less 'true' or less urgent?",
            isReflection: true
        ),
        ACTExerciseStep(
            instruction: "Finally, imagine placing that thought on a leaf floating down a stream. Watch it drift away. It's still there — you're just not holding it.",
            prompt: "What did you notice during this exercise?",
            isReflection: true
        )
    ]

    static let willingnessSteps: [ACTExerciseStep] = [
        ACTExerciseStep(
            instruction: "Willingness means making room for discomfort without trying to control or eliminate it. It's the opposite of avoidance.",
            prompt: nil,
            isReflection: false
        ),
        ACTExerciseStep(
            instruction: "Think about the discomfort you feel when resisting an urge. Where do you feel it in your body?",
            prompt: "Rate your current discomfort from 0 (none) to 10 (extreme):",
            isReflection: false
        ),
        ACTExerciseStep(
            instruction: "Now, instead of fighting it, can you sit with this feeling for 2 minutes? Breathe slowly. Don't try to change anything. Just notice.",
            prompt: nil,
            isReflection: false
        ),
        ACTExerciseStep(
            instruction: "Two minutes have passed. Take a moment to check in.",
            prompt: "Rate your discomfort again. Did it change? What did you notice?",
            isReflection: true
        )
    ]
}
