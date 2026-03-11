import SwiftUI
import SwiftData

struct EpisodeEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<ConditionProfile> { $0.isActive })
    private var activeConditions: [ConditionProfile]

    let episode: Episode

    @State private var painLevel: Int
    @State private var selectedSymptoms: Set<String>
    @State private var selectedTriggers: Set<String>
    @State private var notes: String
    @State private var episodeDate: Date
    @State private var hasEndTime: Bool
    @State private var endDate: Date

    init(episode: Episode) {
        self.episode = episode
        self._painLevel = State(initialValue: episode.painLevel)
        self._selectedSymptoms = State(initialValue: Set((episode.symptoms ?? []).map(\.name)))
        self._selectedTriggers = State(initialValue: Set((episode.triggers ?? []).map(\.name)))
        self._notes = State(initialValue: episode.notes ?? "")
        self._episodeDate = State(initialValue: episode.timestamp)
        self._hasEndTime = State(initialValue: episode.endTimestamp != nil)
        self._endDate = State(initialValue: episode.endTimestamp ?? Date())
    }

    private var availableSymptoms: [String] {
        var symptoms: Set<String> = []
        for condition in activeConditions {
            for symptom in condition.conditionType.defaultSymptoms {
                symptoms.insert(symptom)
            }
        }
        // Include any custom symptoms already on the episode
        for symptom in selectedSymptoms {
            symptoms.insert(symptom)
        }
        if symptoms.isEmpty {
            symptoms = Set(Symptom.defaultMigraineSymptoms)
        }
        return symptoms.sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Pain slider
                    PainSliderView(painLevel: $painLevel)

                    // Date/time
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date & Time")
                            .font(AuraTheme.headingFont)
                            .foregroundStyle(AuraTheme.primary)

                        DatePicker("Start", selection: $episodeDate)
                            .font(AuraTheme.bodyFont)

                        Toggle("Episode ended", isOn: $hasEndTime)
                            .font(AuraTheme.bodyFont)

                        if hasEndTime {
                            DatePicker("End", selection: $endDate)
                                .font(AuraTheme.bodyFont)
                        }
                    }
                    .padding(.horizontal)

                    // Symptoms
                    SymptomPickerView(
                        selectedSymptoms: $selectedSymptoms,
                        availableSymptoms: availableSymptoms
                    )
                    .padding(.horizontal)

                    Divider().padding(.horizontal)

                    // Triggers
                    TriggerPickerView(
                        selectedTriggers: $selectedTriggers,
                        availableTriggers: Trigger.defaultTriggers
                    )
                    .padding(.horizontal)

                    Divider().padding(.horizontal)

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
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Edit Episode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        episode.painLevel = painLevel
        episode.timestamp = episodeDate
        episode.endTimestamp = hasEndTime ? endDate : nil
        episode.notes = notes.isEmpty ? nil : notes

        // Update symptoms
        if let existingSymptoms = episode.symptoms {
            for symptom in existingSymptoms {
                modelContext.delete(symptom)
            }
        }
        for symptomName in selectedSymptoms {
            let symptom = Symptom(name: symptomName)
            symptom.episode = episode
            modelContext.insert(symptom)
        }

        // Update triggers
        if let existingTriggers = episode.triggers {
            for trigger in existingTriggers {
                modelContext.delete(trigger)
            }
        }
        for triggerName in selectedTriggers {
            let trigger = Trigger(name: triggerName)
            trigger.episode = episode
            modelContext.insert(trigger)
        }

        HapticsManager.shared.saveSuccess()
        dismiss()
    }
}
