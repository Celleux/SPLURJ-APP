import Foundation
import SwiftData

@Model
class GachaState {
    var pullsSinceLastEpic: Int = 0
    var pullsSinceLastLegendary: Int = 0
    var totalPulls: Int = 0
    var totalEssence: Int = 0
    var totalShards: Int = 0

    init() {}
}
