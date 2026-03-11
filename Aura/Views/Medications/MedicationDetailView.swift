import SwiftUI
import SwiftData

struct MedicationDetailView: View {
    let medication: Medication
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MedicationDose.timestamp, order: .reverse)
    private var allDoses: [MedicationDose]

    private var doses: [MedicationDose] {
        allDoses.filter { $0.medication?.id == medication.id }
    }

    private var thisMonthDoses: [MedicationDose] {
        let cutoff = Date().adding(days: -30)
        return doses.filter { $0.timestamp >= cutoff }
    }

    var body: some View {
        List {
            // MARK: - Overview
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medication.name)
                            .font(.system(size: 22, weight: .bold))
                        Text(medication.dosage)
                            .font(AuraTheme.bodyFont)
                            .foregroundStyle(.secondary)
                        Text(medication.medicationType.rawValue)
                            .font(AuraTheme.captionFont)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background {
                                Capsule()
                                    .fill(AuraTheme.accent.opacity(0.15))
                            }
                            .foregroundStyle(AuraTheme.accent)
                    }
                    Spacer()
                }
            }

            // MARK: - Usage Stats
            Section("Usage — Last 30 Days") {
                HStack {
                    Text("Times used")
                    Spacer()
                    Text("\(thisMonthDoses.count)")
                        .foregroundStyle(.secondary)
                }

                if medication.medicationType == .acute,
                   let maxDoses = medication.maxDosesPerDay {
                    HStack {
                        Text("Max per day")
                        Spacer()
                        Text("\(maxDoses)")
                            .foregroundStyle(.secondary)
                    }

                    if thisMonthDoses.count >= maxDoses * 8 {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(AuraTheme.painModerate)
                            Text("You've used \(medication.name) \(thisMonthDoses.count) times this month. Your doctor may want to know if you're needing it this often.")
                                .font(AuraTheme.captionFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if medication.medicationType == .preventive {
                    if let frequency = medication.frequency {
                        HStack {
                            Text("Frequency")
                            Spacer()
                            Text(frequency)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // MARK: - Dose History
            if !doses.isEmpty {
                Section("Recent Doses") {
                    ForEach(doses.prefix(20)) { dose in
                        HStack {
                            Text(dose.timestamp.shortDateTimeString)
                                .font(AuraTheme.bodyFont)
                            Spacer()
                            if let episode = dose.episode {
                                PainBadge(level: episode.painLevel)
                            }
                        }
                    }
                }
            }

            // MARK: - Actions
            Section {
                Toggle("Active", isOn: Binding(
                    get: { medication.isActive },
                    set: { medication.isActive = $0 }
                ))

                if medication.medicationType == .preventive {
                    NavigationLink("Reminders") {
                        MedicationReminderView(medication: medication)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(medication.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
