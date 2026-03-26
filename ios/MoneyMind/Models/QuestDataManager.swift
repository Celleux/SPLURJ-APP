import Foundation

class QuestDataManager {
    static let shared = QuestDataManager()
    private init() {}

    private lazy var _allQuests: [QuestDefinition] = QuestDatabase.allQuests
    private lazy var _questIndex: [String: QuestDefinition] = {
        Dictionary(uniqueKeysWithValues: _allQuests.map { ($0.id, $0) })
    }()
    private lazy var _categoryIndex: [QuestCategory: [QuestDefinition]] = {
        Dictionary(grouping: _allQuests, by: \.category)
    }()
    private lazy var _zoneIndex: [QuestZone: [QuestDefinition]] = {
        Dictionary(grouping: _allQuests, by: \.zone)
    }()
    private lazy var _cadenceIndex: [QuestCadence: [QuestDefinition]] = {
        Dictionary(grouping: _allQuests, by: \.cadence)
    }()
    private lazy var _chainIndex: [String: [QuestDefinition]] = {
        var dict: [String: [QuestDefinition]] = [:]
        for quest in _allQuests {
            guard let chainID = quest.chainID else { continue }
            dict[chainID, default: []].append(quest)
        }
        for key in dict.keys {
            dict[key]?.sort { ($0.chainIndex ?? 0) < ($1.chainIndex ?? 0) }
        }
        return dict
    }()

    var allQuests: [QuestDefinition] { _allQuests }
    var totalQuests: Int { _allQuests.count }

    func quest(byID id: String) -> QuestDefinition? {
        _questIndex[id]
    }

    func quests(forCategory category: QuestCategory) -> [QuestDefinition] {
        _categoryIndex[category] ?? []
    }

    func quests(forZone zone: QuestZone) -> [QuestDefinition] {
        _zoneIndex[zone] ?? []
    }

    func quests(forChain chainID: String) -> [QuestDefinition] {
        _chainIndex[chainID] ?? []
    }

    func quests(forCadence cadence: QuestCadence) -> [QuestDefinition] {
        _cadenceIndex[cadence] ?? []
    }

    var allChainIDs: [String] { QuestDatabase.allChainIDs }
    var streakMilestones: [Int] { QuestDatabase.streakMilestones }

    func streakQuest(forMilestone milestone: Int) -> QuestDefinition? {
        QuestDatabase.streakQuests.first { $0.id == "streak_\(milestone)" }
    }

    func randomComebackQuest() -> QuestDefinition {
        QuestDatabase.coreQuests.randomElement() ?? QuestDatabase.coreQuests[0]
    }

    func availableDynamicQuests() -> [QuestDefinition] { [] }

    var microQuests: [QuestDefinition] { QuestDatabase.microQuests }
}
