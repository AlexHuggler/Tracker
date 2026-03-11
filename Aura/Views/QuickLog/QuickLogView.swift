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
    @State private var isExpanded = UserDefaults.standard.bool(forKey: "quickLogWasExpanded")

    // Smart defaults from UserDefaults
    private static let recentSymptomsKey = "recentSymptoms"
    private static let recentTriggersKey = "recentTriggers"
    private static let wasExpandedKey = "quickLogWasExpanded"

    private var recentSymptoms: [String] {
        UserDefaults.standard.stringArray(forKey: Self.recentSymptomsKey) ?? []
    }

    private var recentTriggers: [String] {
        UserDefaults.standard.stringArray(forKey: Self.recentTriggersKey) ?? []
    }

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
                                // Recent Symptoms (smart defaults)
                                if !recentSymptoms.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Recent")
                                            .font(AuraTheme.captionFont)
                                            .foregroundStyle(.secondary)

                                        FlowLayout(spacing: 8) {
                                            ForEach(recentSymptoms.prefix(5), id: \.self) { symptom in
                                                PillButton(
                                                    title: symptom,
                                                    isSelected: selectedSymptoms.contains(symptom)
                                                ) {
                                                    if selectedSymptoms.contains(symptom) {
                                                        selectedSymptoms.remove(symptom)
                                                    } else {
                                                        selectedSymptoms.insert(symptom)
                                                    }
                                                    HapticsManager.shared.selectionChanged()
                                                }
                                            }
                                        }
                                    }
                                }

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
                    SaveConfirmationOverlay(reduceMotion: reduceMotion)
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

        // Save smart defaults for next time
        if !selectedSymptoms.isEmpty {
            UserDefaults.standard.set(Array(selectedSymptoms), forKey: Self.recentSymptomsKey)
        }
        if !selectedTriggers.isEmpty {
            UserDefaults.standard.set(Array(selectedTriggers), forKey: Self.recentTriggersKey)
        }
        UserDefaults.standard.set(isExpanded, forKey: Self.wasExpandedKey)

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
                    .padding(.vertical, 14)
                    .frame(minHeight: 44)
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
            .auraCard()
        }
        .accessibilityLabel("\(medication.name), \(medication.dosage)")
        .accessibilityAddTraits(isTaken ? .isSelected : [])
    }
}

// MARK: - Save Confirmation Overlay

struct SaveConfirmationOverlay: View {
    let reduceMotion: Bool
    @State private var showCheck = false
    @State private var showText = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(AuraTheme.accent.opacity(0.2), lineWidth: 4)
                        .frame(width: 64, height: 64)

                    Circle()
                        .trim(from: 0, to: showCheck ? 1 : 0)
                        .stroke(AuraTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AuraTheme.accent)
                        .scaleEffect(showCheck ? 1 : 0.3)
                        .opacity(showCheck ? 1 : 0)
                }

                Text("Logged. Feel better soon.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(AuraTheme.primary)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 8)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background {
                RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                    .fill(.regularMaterial)
            }
            .scaleEffect(showCheck ? 1 : 0.9)
            Spacer()
        }
        .transition(.opacity)
        .onAppear {
            if reduceMotion {
                showCheck = true
                showText = true
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showCheck = true
                }
                withAnimation(.easeOut(duration: 0.3).delay(0.25)) {
                    showText = true
                }
            }
        }
    }
}

#Preview {
    QuickLogView()
        .environment(AppState())
        .modelContainer(for: [Episode.self, Symptom.self, Trigger.self, Medication.self, MedicationDose.self])
}
