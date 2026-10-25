import Foundation
import UserNotifications

/// Where the daily reminders are planned. Today they are local notifications on the phone;
/// tests use a fake that only records what was planned.
protocol ReminderScheduling {
    /// Replaces every planned study reminder with these. An empty list turns them off.
    func replace(with reminders: [PlannedReminder])
}

/// Local notifications: the iPhone itself shows them, nothing leaves the phone.
struct NotificationReminders: ReminderScheduling {
    static let idPrefix = "hablo.reminder."

    func replace(with reminders: [PlannedReminder]) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        // One id per day, so removing the days that could be planned clears the old reminders
        // in order, before the new ones are added.
        let now = Date.now
        let candidates = (-1...StudyReminder.plannedDays + 1).map {
            Self.id(for: calendar.date(byAdding: .day, value: $0, to: now) ?? now, calendar: calendar)
        }
        center.removePendingNotificationRequests(withIdentifiers: candidates)
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.message.title
            content.body = reminder.message.body
            content.sound = .default
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            center.add(UNNotificationRequest(identifier: Self.id(for: reminder.date, calendar: calendar),
                                             content: content, trigger: trigger))
        }
    }

    private static func id(for date: Date, calendar: Calendar) -> String {
        idPrefix + Streak.dayKey(date, calendar: calendar)
    }

    /// Whether the learner has allowed notifications, has refused them, or has not been asked.
    static func permission() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Shows the system question the first time; afterwards it answers with the learner's choice.
    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }
}

/// Keeps the planned reminders in memory; used by tests and previews.
final class InMemoryReminders: ReminderScheduling {
    private(set) var planned: [PlannedReminder] = []

    func replace(with reminders: [PlannedReminder]) {
        planned = reminders
    }
}
