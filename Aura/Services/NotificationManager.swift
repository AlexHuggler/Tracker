import UserNotifications
import Foundation
import os

private let logger = Logger(subsystem: "com.aura.app", category: "Notifications")

final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            logger.error("Failed to request notification authorization: \(error.localizedDescription)")
            return false
        }
    }

    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    func scheduleReminder(for medication: Medication, at time: Date) async throws {
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

        try await center.add(request)
        logger.info("Scheduled reminder for \(medication.name) at \(time.shortTimeString)")
    }

    func cancelReminder(for medication: Medication) {
        let identifier = "med-reminder-\(medication.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    // 4.1: Snooze a medication reminder by rescheduling it
    func snoozeReminder(for medication: Medication, minutes: Int) async throws {
        cancelReminder(for: medication)

        let content = UNMutableNotificationContent()
        content.title = "Snoozed: \(medication.name)"
        content.body = "\(medication.dosage) — reminder snoozed \(minutes) min"
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let identifier = "med-reminder-\(medication.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await center.add(request)
        logger.info("Snoozed \(medication.name) for \(minutes) minutes")
    }

    // 4.1: Skip today's reminder for a medication
    func skipToday(for medication: Medication) {
        cancelReminder(for: medication)
        logger.info("Skipped today's reminder for \(medication.name)")
        // The daily repeating reminder will fire again tomorrow since we only
        // removed the pending request. Re-schedule for tomorrow's normal time.
        if let reminderTime = medication.reminderTime {
            Task {
                try? await scheduleReminder(for: medication, at: reminderTime)
            }
        }
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
