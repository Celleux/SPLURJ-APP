import SwiftUI

nonisolated enum CharacterStage: Int, CaseIterable, Sendable {
    case seedling = 1
    case sprout
    case guardian
    case warrior
    case champion
    case legend

    var name: String {
        switch self {
        case .seedling: "Seedling"
        case .sprout: "Sprout"
        case .guardian: "Guardian"
        case .warrior: "Warrior"
        case .champion: "Champion"
        case .legend: "Legend"
        }
    }

    var levelRange: ClosedRange<Int> {
        switch self {
        case .seedling: 1...5
        case .sprout: 6...10
        case .guardian: 11...20
        case .warrior: 21...35
        case .champion: 36...45
        case .legend: 46...50
        }
    }

    var xpRange: ClosedRange<Int> {
        switch self {
        case .seedling: 0...500
        case .sprout: 500...1_500
        case .guardian: 1_500...5_000
        case .warrior: 5_000...15_000
        case .champion: 15_000...35_000
        case .legend: 35_000...999_999
        }
    }

    var primaryColor: Color {
        switch self {
        case .seedling: Color(white: 0.45)
        case .sprout: Color(red: 0, green: 191/255, blue: 165/255)
        case .guardian: Color(red: 0.3, green: 0.5, blue: 0.9)
        case .warrior: Color(red: 0.55, green: 0.3, blue: 0.85)
        case .champion: Color(red: 1, green: 215/255, blue: 64/255)
        case .legend: Color(red: 1, green: 0.85, blue: 0.3)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .seedling: Color(white: 0.3)
        case .sprout: Color(red: 0, green: 230/255, blue: 118/255)
        case .guardian: Color(red: 0.2, green: 0.35, blue: 0.7)
        case .warrior: Color(red: 0.7, green: 0.4, blue: 1.0)
        case .champion: Color(red: 1, green: 179/255, blue: 0)
        case .legend: Color(red: 1, green: 0.95, blue: 0.6)
        }
    }

    var bodyIcon: String {
        switch self {
        case .seedling: "circle.fill"
        case .sprout: "leaf.fill"
        case .guardian: "shield.fill"
        case .warrior: "shield.checkered"
        case .champion: "crown.fill"
        case .legend: "sparkles"
        }
    }

    var size: CGFloat {
        switch self {
        case .seedling: 60
        case .sprout: 72
        case .guardian: 80
        case .warrior: 88
        case .champion: 96
        case .legend: 104
        }
    }

    static func from(xp: Int) -> CharacterStage {
        switch xp {
        case ..<500: .seedling
        case 500..<1_500: .sprout
        case 1_500..<5_000: .guardian
        case 5_000..<15_000: .warrior
        case 15_000..<35_000: .champion
        default: .legend
        }
    }

    static func level(from xp: Int) -> Int {
        switch xp {
        case ..<100: 1
        case 100..<200: 2
        case 200..<350: 3
        case 350..<500: 4
        case 500..<700: 5
        case 700..<950: 6
        case 950..<1_200: 7
        case 1_200..<1_500: 8
        case 1_500..<1_850: 9
        case 1_850..<2_250: 10
        case 2_250..<2_700: 11
        case 2_700..<3_200: 12
        case 3_200..<3_750: 13
        case 3_750..<4_350: 14
        case 4_350..<5_000: 15
        case 5_000..<5_750: 16
        case 5_750..<6_550: 17
        case 6_550..<7_400: 18
        case 7_400..<8_300: 19
        case 8_300..<9_250: 20
        case 9_250..<10_250: 21
        case 10_250..<11_300: 22
        case 11_300..<12_400: 23
        case 12_400..<13_550: 24
        case 13_550..<14_750: 25
        case 14_750..<16_000: 26
        case 16_000..<17_300: 27
        case 17_300..<18_650: 28
        case 18_650..<20_050: 29
        case 20_050..<21_500: 30
        case 21_500..<23_000: 31
        case 23_000..<24_550: 32
        case 24_550..<26_150: 33
        case 26_150..<27_800: 34
        case 27_800..<29_500: 35
        case 29_500..<30_500: 36
        case 30_500..<31_500: 37
        case 31_500..<32_500: 38
        case 32_500..<33_500: 39
        case 33_500..<34_500: 40
        case 34_500..<35_500: 41
        case 35_500..<36_500: 42
        case 36_500..<37_500: 43
        case 37_500..<38_500: 44
        case 38_500..<39_500: 45
        case 39_500..<41_000: 46
        case 41_000..<43_000: 47
        case 43_000..<46_000: 48
        case 46_000..<50_000: 49
        default: 50
        }
    }

    static func xpForLevel(_ level: Int) -> Int {
        let thresholds = [0, 0, 100, 200, 350, 500, 700, 950, 1_200, 1_500, 1_850,
                          2_250, 2_700, 3_200, 3_750, 4_350, 5_000, 5_750, 6_550, 7_400, 8_300,
                          9_250, 10_250, 11_300, 12_400, 13_550, 14_750, 16_000, 17_300, 18_650, 20_050,
                          21_500, 23_000, 24_550, 26_150, 27_800, 29_500, 30_500, 31_500, 32_500, 33_500,
                          34_500, 35_500, 36_500, 37_500, 38_500, 39_500, 41_000, 43_000, 46_000, 50_000]
        guard level >= 1, level <= 50 else { return 0 }
        return thresholds[level]
    }

    static func xpForNextLevel(_ level: Int) -> Int {
        guard level < 50 else { return 50_000 }
        return xpForLevel(level + 1)
    }
}

nonisolated enum CharacterReaction: String, Sendable {
    case idle
    case celebrate
    case breathe
    case sympathize
    case encourage
    case grace
}

nonisolated enum SDTPhase: Sendable {
    case extrinsic
    case transition
    case intrinsic

    static func from(daysSinceStart: Int) -> SDTPhase {
        switch daysSinceStart {
        case ..<30: .extrinsic
        case 30..<90: .transition
        default: .intrinsic
        }
    }
}

nonisolated enum XPAction: Sendable {
    case dailyCheckIn
    case avoidedPurchase(amount: Double)
    case gambleFreeDay
    case urgeSurfComplete
    case cbtExercise
    case haltCheckIn
    case sevenDayStreak
    case thirtyDayStreak
    case spendingAutopsy
    case implementationIntention
    case curriculumSession

    var xpValue: Int {
        switch self {
        case .dailyCheckIn: return 25
        case .avoidedPurchase(let amount):
            let scaled = Int(amount / 10) * 10
            return min(200, max(50, scaled))
        case .gambleFreeDay: return 100
        case .urgeSurfComplete: return 75
        case .cbtExercise: return 100
        case .haltCheckIn: return 15
        case .sevenDayStreak: return 500
        case .thirtyDayStreak: return 2_500
        case .spendingAutopsy: return 10
        case .implementationIntention: return 50
        case .curriculumSession: return 150
        }
    }
}
