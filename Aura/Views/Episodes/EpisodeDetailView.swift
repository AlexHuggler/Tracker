import SwiftUI
import SwiftData

struct EpisodeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let episode: Episode
    @State private var isEditing = false

    @Query(filter: #Predicate<ConditionProfile> { $0.isActive })
    private var activeConditions: [ConditionProfile]

    // Editing state
    @State private var editPainLevel: Int = 5
    @State private var editSelectedSymptoms: Set<String> = []
    @State private var editSelectedTriggers: Set<String> = []
    @State private var editNotes: String = ""

    private var availableSymptoms: [String] {
        var symptoms: Set<String> = []
        for condition in activeConditions {
            for symptom in condition.conditionType.defaultSymptoms {
                symptoms.insert(symptom)
            }
        }
        for symptom in editSelectedSymptoms {
            symptoms.insert(symptom)
        }
        if symptoms.isEmpty {
            symptoms = Set(Symptom.defaultMigraineSymptoms)
        }
        return symptoms.sorted()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Pain Level Header
                if isEditing {
                    PainSliderView(painLevel: $editPainLevel)
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 8) {
                        Text("\(episode.painLevel)")
                            .font(AuraTheme.painLevelFont)
                            .foregroundStyle(AuraTheme.painColor(for: episode.painLevel))

                        Text(episode.painCategory.rawValue)
                            .font(.system(.headline, design: .rounded, weight: .medium))
                            .foregroundStyle(AuraTheme.painColor(for: episode.painLevel))

                        Text(episode.timestamp.shortDateTimeString)
                            .font(AuraTheme.bodyFont)
                            .foregroundStyle(.secondary)

                        if let duration = episode.formattedDuration {
                            Text("Duration: \(duration)")
                                .font(AuraTheme.captionFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background {
                        RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                            .fill(AuraTheme.painColor(for: episode.painLevel).opacity(0.1))
                    }
                    .padding(.horizontal)
                }

                // MARK: - Symptoms
                if isEditing {
                    detailSection(title: "Symptoms", icon: "stethoscope") {
                        SymptomPickerView(
                            selectedSymptoms: $editSelectedSymptoms,
                            availableSymptoms: availableSymptoms
                        )
                    }
                } else if let symptoms = episode.symptoms, !symptoms.isEmpty {
                    detailSection(title: "Symptoms", icon: "stethoscope") {
                        FlowLayout(spacing: 8) {
                            ForEach(symptoms) { symptom in
                                Text(symptom.name)
                                    .font(AuraTheme.captionFont)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background {
                                        Capsule()
                                            .fill(AuraTheme.accent.opacity(0.15))
                                    }
                                    .foregroundStyle(AuraTheme.accent)
                            }
                        }
                    }
                }

                // MARK: - Triggers
                if isEditing {
                    detailSection(title: "Triggers", icon: "exclamationmark.triangle") {
                        TriggerPickerView(
                            selectedTriggers: $editSelectedTriggers,
                            availableTriggers: Trigger.defaultTriggers
                        )
                    }
                } else if let triggers = episode.triggers, !triggers.isEmpty {
                    detailSection(title: "Triggers", icon: "exclamationmark.triangle") {
                        FlowLayout(spacing: 8) {
                            ForEach(triggers) { trigger in
                                Text(trigger.name)
                                    .font(AuraTheme.captionFont)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background {
                                        Capsule()
                                            .fill(AuraTheme.painModerate.opacity(0.15))
                                    }
                                    .foregroundStyle(AuraTheme.painSevere)
                            }
                        }
                    }
                }

                // MARK: - Medications
                if let doses = episode.medicationDoses, !doses.isEmpty {
                    detailSection(title: "Medications Taken", icon: "pill") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(doses) { dose in
                                HStack {
                                    Text(dose.medication?.name ?? "Unknown")
                                        .font(.subheadline.weight(.medium))
                                    if let dosage = dose.dosage {
                                        Text(dosage)
                                            .font(AuraTheme.captionFont)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(dose.timestamp.shortTimeString)
                                        .font(AuraTheme.captionFont)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // MARK: - Conditions
                if let conditions = episode.conditions, !conditions.isEmpty {
                    detailSection(title: "Conditions", icon: "heart.text.clipboard") {
                        FlowLayout(spacing: 8) {
                            ForEach(conditions) { condition in
                                Label(condition.displayName, systemImage: condition.conditionType.icon)
                                    .font(AuraTheme.captionFont)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background {
                                        Capsule()
                                            .fill(AuraTheme.primary.opacity(0.1))
                                    }
                                    .foregroundStyle(AuraTheme.primary)
                            }
                        }
                    }
                }

                // MARK: - Notes
                if isEditing {
                    detailSection(title: "Notes", icon: "note.text") {
                        TextField("Anything else to note...", text: $editNotes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                            .font(AuraTheme.bodyFont)
                    }
                } else if let notes = episode.notes, !notes.isEmpty {
                    detailSection(title: "Notes", icon: "note.text") {
                        Text(notes)
                            .font(AuraTheme.bodyFont)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isEditing ? "Edit Episode" : "Episode Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Done") {
                        saveInlineChanges()
                    }
                    .fontWeight(.semibold)
                } else {
                    Button("Edit") {
                        startEditing()
                    }
                }
            }
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
            }
        }
    }

    private func startEditing() {
        editPainLevel = episode.painLevel
        editSelectedSymptoms = Set((episode.symptoms ?? []).map(\.name))
        editSelectedTriggers = Set((episode.triggers ?? []).map(\.name))
        editNotes = episode.notes ?? ""
        isEditing = true
    }

    private func saveInlineChanges() {
        episode.painLevel = editPainLevel
        episode.notes = editNotes.isEmpty ? nil : editNotes

        // Update symptoms
        if let existingSymptoms = episode.symptoms {
            for symptom in existingSymptoms {
                modelContext.delete(symptom)
            }
        }
        for symptomName in editSelectedSymptoms {
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
        for triggerName in editSelectedTriggers {
            let trigger = Trigger(name: triggerName)
            trigger.episode = episode
            modelContext.insert(trigger)
        }

        HapticsManager.shared.saveSuccess()
        isEditing = false
    }

    private func detailSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(AuraTheme.primary)

            content()
        }
        .padding(AuraTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .auraCard()
        .padding(.horizontal)
    }
}
