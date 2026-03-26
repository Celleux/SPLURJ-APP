import SwiftUI

struct FriendActivity: Identifiable {
    let id = UUID()
    let username: String
    let activityText: String
    let timeAgo: String
    let avatarIcon: String
    let avatarColor: Color

    static let mockData: [FriendActivity] = [
        FriendActivity(username: "Alex", activityText: "completed a 7-day streak", timeAgo: "2h", avatarIcon: "person.fill", avatarColor: Theme.accent),
        FriendActivity(username: "Jordan", activityText: "saved $42 on impulse buys", timeAgo: "4h", avatarIcon: "person.fill", avatarColor: Theme.accentTertiary),
        FriendActivity(username: "Taylor", activityText: "leveled up to Guardian III", timeAgo: "6h", avatarIcon: "person.fill", avatarColor: Theme.axisEmotional),
        FriendActivity(username: "Casey", activityText: "finished Budget Warriors quest", timeAgo: "8h", avatarIcon: "person.fill", avatarColor: Theme.axisRisk),
    ]
}
