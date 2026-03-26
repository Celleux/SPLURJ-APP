import UserNotifications

struct ChallengeNotificationService {

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleNudge(senderEmoji: String, senderName: String, challengeName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Challenge Nudge"
        content.body = "\(senderEmoji) \(senderName) is checking on you! How's \(challengeName) going?"
        content.sound = .default
        schedule(content, id: "nudge-\(UUID().uuidString)")
    }

    static func scheduleCheerOn(senderEmoji: String, senderName: String) {
        let content = UNMutableNotificationContent()
        content.title = "You've got a fan!"
        content.body = "\(senderEmoji) \(senderName) is cheering you on!"
        content.sound = .default
        schedule(content, id: "cheer-\(UUID().uuidString)")
    }

    static func scheduleReaction(senderName: String, emoji: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Reaction"
        content.body = "\(senderName) reacted \(emoji) to your check-in!"
        content.sound = .default
        schedule(content, id: "reaction-\(UUID().uuidString)")
    }

    static func scheduleCoverReceived(senderName: String) {
        let content = UNMutableNotificationContent()
        content.title = "You received a life!"
        content.body = "\(senderName) sent you a life! 🛡️"
        content.sound = .default
        schedule(content, id: "cover-\(UUID().uuidString)")
    }

    private static func schedule(_ content: UNMutableNotificationContent, id: String) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
