import SwiftUI
import SwiftData

struct MedicationListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Medication.name)
    private var medications: [Medication]

    @State private var showingAddMedication = false

    private var acuteMeds: [Medication] {
        medications.filter { $0.medicationType == .acute }
    }

    private var preventiveMeds: [Medication] {
        medications.filter { $0.medicationType == .preventive }
    }

    private var supplementMeds: [Medication] {
        medications.filter { $0.medicationType == .supplement }
    }

    private var canAddMore: Bool {
        appState.isPremium || medications.count < AppState.freeMedicationLimit
    }

    var body: some View {
        Group {
            if medications.isEmpty {
                ContentUnavailableView {
                    Label("No Medications", systemImage: "pill")
                } description: {
                    Text("Add your medications to track usage and effectiveness.")
                } actions: {
                    Button("Add Medication") {
                        showingAddMedication = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AuraTheme.accent)
                }
            } else {
                List {
                    if !acuteMeds.isEmpty {
                        medicationSection(title: "Acute", meds: acuteMeds)
                    }
                    if !preventiveMeds.isEmpty {
                        medicationSection(title: "Preventive", meds: preventiveMeds)
                    }
                    if !supplementMeds.isEmpty {
                        medicationSection(title: "Supplements", meds: supplementMeds)
                    }

                    if !canAddMore {
                        Section {
                            Button {
                                appState.showingPaywall = true
                            } label: {
                                HStack {
                                    Image(systemName: "lock.fill")
                                    Text("Unlock unlimited medications")
                                }
                                .foregroundStyle(AuraTheme.accent)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        // 2.6: Show medication limit indicator for free tier
        .safeAreaInset(edge: .top) {
            if !appState.isPremium && !medications.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "pill")
                        .font(.system(size: 12))
                    Text("\(medications.count)/\(AppState.freeMedicationLimit) medications")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    if !canAddMore {
                        Button {
                            appState.showingPaywall = true
                        } label: {
                            Text("Unlock more")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AuraTheme.accent)
                        }
                    }
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
        .navigationTitle("Medications")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if canAddMore {
                        showingAddMedication = true
                    } else {
                        appState.showingPaywall = true
                    }
                } label: {
                    Image(systemName: canAddMore ? "plus" : "lock.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView()
        }
    }

    private func medicationSection(title: String, meds: [Medication]) -> some View {
        Section(title) {
            ForEach(meds) { med in
                NavigationLink {
                    MedicationDetailView(medication: med)
                } label: {
                    MedicationRowView(medication: med)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    modelContext.delete(meds[index])
                }
            }
        }
    }
}

struct MedicationRowView: View {
    let medication: Medication

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.system(size: 16, weight: .medium))
                Text(medication.dosage)
                    .font(AuraTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(medication.medicationType.rawValue)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(medicationTypeColor.opacity(0.15))
                }
                .foregroundStyle(medicationTypeColor)
        }
    }

    private var medicationTypeColor: Color {
        medication.medicationType.color
    }
}

// MARK: - Add Medication View

struct AddMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dosage = ""
    @State private var medicationType: MedicationType = .acute
    @State private var frequency = ""
    @State private var maxDosesPerDay: Int?
    @State private var showingPresets = true

    var body: some View {
        NavigationStack {
            List {
                if showingPresets {
                    Section("Common Medications") {
                        ForEach(Medication.commonMedications, id: \.name) { preset in
                            Button {
                                name = preset.name
                                dosage = preset.dosage
                                medicationType = preset.type
                                showingPresets = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(.primary)
                                        Text("\(preset.dosage) · \(preset.type.rawValue)")
                                            .font(AuraTheme.captionFont)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(AuraTheme.accent)
                                }
                            }
                        }
                    }

                    Section {
                        Button("Enter custom medication") {
                            showingPresets = false
                        }
                    }
                } else {
                    Section("Medication Details") {
                        TextField("Name", text: $name)
                        TextField("Dosage (e.g. 50mg)", text: $dosage)
                        Picker("Type", selection: $medicationType) {
                            ForEach(MedicationType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }

                    if medicationType == .preventive {
                        Section("Schedule") {
                            TextField("Frequency (e.g. Once daily)", text: $frequency)
                        }
                    }

                    if medicationType == .acute {
                        Section("Limits") {
                            Stepper(
                                "Max per day: \(maxDosesPerDay.map(String.init) ?? "No limit")",
                                value: Binding(
                                    get: { maxDosesPerDay ?? 0 },
                                    set: { maxDosesPerDay = $0 > 0 ? $0 : nil }
                                ),
                                in: 0...10
                            )
                        }
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if !showingPresets {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            saveMedication()
                        }
                        .disabled(name.isEmpty || dosage.isEmpty)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private func saveMedication() {
        let med = Medication(
            name: name,
            medicationType: medicationType,
            dosage: dosage,
            frequency: frequency.isEmpty ? nil : frequency,
            maxDosesPerDay: maxDosesPerDay
        )
        modelContext.insert(med)
        HapticsManager.shared.saveSuccess()
        dismiss()
    }
}
