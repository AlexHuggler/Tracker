import SwiftUI
import SwiftData

struct QuickLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(filter: #Predicate<Medication> { $0.isActive },
           sort: \Medication.name)
    private var medications: [Medication]

    @Query(filter: #Predicate<ConditionProfile> { $0.isActive })
    private var activeConditions: [ConditionProfile]

    @State private var painLevel: Int = 5
    @State private var selectedSymptoms: Set<String> = []
    @State private var selectedTriggers: Set<String> = []
    @State private var takenMedications: Set<UUID> = []
    @State private var notes: String = ""
    @State private var showingSaveConfirmation = false
    @State private var isExpanded = false

    private var availableSymptoms: [String] {
        var symptoms: Set<String> = []
        for condition in activeConditions {
            for symptom in condition.conditionType.defaultSymptoms {
                symptoms.insert(symptom)
            }
        }
        if symptoms.isEmpty {
            symptoms = Set(Symptom.defaultMigraineSymptoms)
        }
        return symptoms.sorted()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 32) {
                        // MARK: - Pain Slider (above the fold)
                        VStack(spacing: 8) {
                            Text("How bad is it?")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundStyle(AuraTheme.primary)

                            PainSliderView(painLevel: $painLevel)
                        }
                        .padding(.top, 16)

                        // MARK: - Save Button (always visible, above the fold)
                        Button {
                            saveEpisode()
                        } label: {
                            Text("Save")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: AuraTheme.minTouchTarget)
                                .background {
                                    RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                                        .fill(AuraTheme.painColor(for: painLevel))
                                }
                        }
                        .padding(.horizontal)

                        // MARK: - Optional Details Toggle
                        Button {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Text(isExpanded ? "Less details" : "Add details (optional)")
                                    .font(AuraTheme.bodyFont)
                                    .foregroundStyle(.secondary)
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // MARK: - Optional Enrichment (below the fold)
                        if isExpanded {
                            VStack(spacing: 28) {
                                // Symptoms
                                SymptomPickerView(
                                    selectedSymptoms: $selectedSymptoms,
                                    availableSymptoms: availableSymptoms
                                )

                                Divider()

                                // Triggers
                                TriggerPickerView(
                                    selectedTriggers: $selectedTriggers,
                                    availableTriggers: Trigger.defaultTriggers
                                )

                                // Medications (if any configured)
                                if !medications.isEmpty {
                                    Divider()

                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Medications Taken")
                                            .font(AuraTheme.headingFont)
                                            .foregroundStyle(AuraTheme.primary)

                                        ForEach(medications) { med in
                                            MedicationQuickButton(
                                                medication: med,
                                                isTaken: takenMedications.contains(med.id)
                                            ) {
                                                if takenMedications.contains(med.id) {
                                                    takenMedications.remove(med.id)
                                                } else {
                                                    takenMedications.insert(med.id)
                                                }
                                                HapticsManager.shared.selectionChanged()
                                            }
                                        }
                                    }
                                }

                                Divider()

                                // Notes
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notes")
                                        .font(AuraTheme.headingFont)
                                        .foregroundStyle(AuraTheme.primary)

                                    TextField("Anything else to note...", text: $notes, axis: .vertical)
                                        .lineLimit(3...6)
                                        .textFieldStyle(.roundedBorder)
                                        .font(AuraTheme.bodyFont)
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal)
                }

                // MARK: - Save Confirmation Overlay
                if showingSaveConfirmation {
                    VStack {
                        Spacer()
                        Text("Logged. Feel better soon.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(AuraTheme.primary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                                    .fill(.regularMaterial)
                            }
                        Spacer()
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("Log Episode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.isDimMode.toggle()
                    } label: {
                        Image(systemName: appState.isDimMode ? "sun.max.fill" : "moon.fill")
                            .foregroundStyle(AuraTheme.accent)
                    }
                    .accessibilityLabel(appState.isDimMode ? "Turn off dim mode" : "Turn on dim mode")
                }
            }
        }
    }

    private func saveEpisode() {
        let episode = Episode(painLevel: painLevel)

        // Add symptoms
        for symptomName in selectedSymptoms {
            let symptom = Symptom(name: symptomName)
            symptom.episode = episode
            modelContext.insert(symptom)
        }

        // Add triggers
        for triggerName in selectedTriggers {
            let trigger = Trigger(name: triggerName)
            trigger.episode = episode
            modelContext.insert(trigger)
        }

        // Add medication doses
        for medID in takenMedications {
            if let med = medications.first(where: { $0.id == medID }) {
                let dose = MedicationDose(medication: med, episode: episode)
                modelContext.insert(dose)
            }
        }

        if !notes.isEmpty {
            episode.notes = notes
        }

        modelContext.insert(episode)

        HapticsManager.shared.saveSuccess()

        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            showingSaveConfirmation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}

// MARK: - Medication Quick Button

struct MedicationQuickButton: View {
    let medication: Medication
    let isTaken: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(medication.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AuraTheme.primary)
                    Text(medication.dosage)
                        .font(AuraTheme.captionFont)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(isTaken ? "Taken" : "Take")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isTaken ? .white : AuraTheme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        Capsule()
                            .fill(isTaken ? AuraTheme.accent : Color.clear)
                    }
                    .overlay {
                        Capsule()
                            .stroke(AuraTheme.accent, lineWidth: 2)
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                    .fill(Color(.systemBackground))
                    .shadow(color: AuraTheme.cardShadow, radius: 4, y: 2)
            }
        }
        .accessibilityLabel("\(medication.name), \(medication.dosage)")
        .accessibilityAddTraits(isTaken ? .isSelected : [])
    }
}

#Preview {
    QuickLogView()
        .environment(AppState())
        .modelContainer(for: [Episode.self, Symptom.self, Trigger.self, Medication.self, MedicationDose.self])
}
