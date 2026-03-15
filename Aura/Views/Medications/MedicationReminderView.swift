import SwiftUI

struct MedicationReminderView: View {
    let medication: Medication
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var notificationPermissionGranted = false
    // 4.1: Confirmation feedback for snooze/skip actions
    @State private var actionMessage: String?

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
                        Task { try? await NotificationManager.shared.scheduleReminder(for: medication, at: newTime) }
                    }
                }
            } footer: {
                Text("You'll receive a daily notification to take \(medication.name).")
            }

            // 4.1: Functional snooze/skip buttons
            if reminderEnabled {
                Section("When notified") {
                    Button {
                        Task {
                            try? await NotificationManager.shared.snoozeReminder(for: medication, minutes: 15)
                            HapticsManager.shared.lightTap()
                            actionMessage = "Snoozed for 15 minutes"
                        }
                    } label: {
                        Label("Snooze 15 minutes", systemImage: "clock.arrow.circlepath")
                    }

                    Button {
                        Task {
                            try? await NotificationManager.shared.snoozeReminder(for: medication, minutes: 60)
                            HapticsManager.shared.lightTap()
                            actionMessage = "Snoozed for 1 hour"
                        }
                    } label: {
                        Label("Snooze 1 hour", systemImage: "clock.arrow.circlepath")
                    }

                    Button(role: .destructive) {
                        NotificationManager.shared.skipToday(for: medication)
                        HapticsManager.shared.lightTap()
                        actionMessage = "Skipped today's reminder"
                    } label: {
                        Label("Skip today", systemImage: "forward.fill")
                    }
                }

                // Confirmation feedback
                if let actionMessage {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AuraTheme.accent)
                            Text(actionMessage)
                                .font(AuraTheme.captionFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                self.actionMessage = nil
                            }
                        }
                    }
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
                try? await NotificationManager.shared.scheduleReminder(for: medication, at: reminderTime)
            } else {
                reminderEnabled = false
            }
        }
    }
}
