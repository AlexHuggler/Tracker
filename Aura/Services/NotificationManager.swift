import UserNotifications
import Foundation

final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    func scheduleReminder(for medication: Medication, at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time for your \(medication.name)"
        content.body = "\(medication.dosage) — \(medication.medicationType.rawValue)"
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let identifier = "med-reminder-\(medication.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    func cancelReminder(for medication: Medication) {
        let identifier = "med-reminder-\(medication.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    func registerCategories() {
        let snooze15 = UNNotificationAction(
            identifier: "SNOOZE_15",
            title: "Snooze 15 min",
            options: []
        )
        let snooze60 = UNNotificationAction(
            identifier: "SNOOZE_60",
            title: "Snooze 1 hour",
            options: []
        )
        let skip = UNNotificationAction(
            identifier: "SKIP_TODAY",
            title: "Skip today",
            options: .destructive
        )

        let category = UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [snooze15, snooze60, skip],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }
}
