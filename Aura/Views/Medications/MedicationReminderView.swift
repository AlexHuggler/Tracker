import SwiftUI

struct MedicationReminderView: View {
    let medication: Medication
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var notificationPermissionGranted = false

    init(medication: Medication) {
        self.medication = medication
        self._reminderEnabled = State(initialValue: medication.reminderTime != nil)
        self._reminderTime = State(initialValue: medication.reminderTime ?? Calendar.current.date(
            bySettingHour: 9, minute: 0, second: 0, of: Date()
        ) ?? Date())
    }

    var body: some View {
        List {
            Section {
                Toggle("Daily Reminder", isOn: $reminderEnabled)
                    .onChange(of: reminderEnabled) { _, newValue in
                        if newValue {
                            requestNotificationPermission()
                        } else {
                            medication.reminderTime = nil
                            NotificationManager.shared.cancelReminder(for: medication)
                        }
                    }

                if reminderEnabled {
                    DatePicker(
                        "Time",
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: reminderTime) { _, newTime in
                        medication.reminderTime = newTime
                        NotificationManager.shared.scheduleReminder(for: medication, at: newTime)
                    }
                }
            } footer: {
                Text("You'll receive a daily notification to take \(medication.name).")
            }

            if reminderEnabled {
                Section("When notified") {
                    Label("Snooze 15 minutes", systemImage: "clock.arrow.circlepath")
                    Label("Snooze 1 hour", systemImage: "clock.arrow.circlepath")
                    Label("Skip today", systemImage: "forward.fill")
                }
            }
        }
        .navigationTitle("Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            notificationPermissionGranted = await NotificationManager.shared.isAuthorized()
        }
    }

    private func requestNotificationPermission() {
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                medication.reminderTime = reminderTime
                NotificationManager.shared.scheduleReminder(for: medication, at: reminderTime)
            } else {
                reminderEnabled = false
            }
        }
    }
}
