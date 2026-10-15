import Foundation
import UserNotifications
import InklingCore

/// A daily nudge that carries that day's writing prompt. iOS repeats a notification with the same text, so
/// the next two weeks are scheduled one by one, each with its own prompt, and topped up on every launch.
enum Reminders {
    private static let prefix = "inkling.reminder."
    private static let daysAhead = 14

    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func schedule(minutesAfterMidnight: Int, calendar: Calendar = .current) async {
        let center = UNUserNotificationCenter.current()
        cancelPending(center)
        let today = calendar.startOfDay(for: .now)
        for offset in 0..<daysAhead {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let fire = calendar.date(byAdding: .minute, value: minutesAfterMidnight, to: day),
                  fire > .now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Time to write"
            content.body = Prompts.forDay(day, calendar: calendar)
            content.sound = .default
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: prefix + "\(offset)", content: content, trigger: trigger))
        }
    }

    static func cancel() { cancelPending(UNUserNotificationCenter.current()) }

    private static func cancelPending(_ center: UNUserNotificationCenter) {
        center.removePendingNotificationRequests(withIdentifiers: (0..<daysAhead).map { prefix + "\($0)" })
    }
}
