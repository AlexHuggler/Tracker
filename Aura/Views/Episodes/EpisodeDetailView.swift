import SwiftUI
import SwiftData

struct EpisodeDetailView: View {
    let episode: Episode
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Pain Level Header
                VStack(spacing: 8) {
                    Text("\(episode.painLevel)")
                        .font(AuraTheme.painLevelFont)
                        .foregroundStyle(AuraTheme.painColor(for: episode.painLevel))

                    Text(episode.painCategory.rawValue)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
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

                // MARK: - Symptoms
                if let symptoms = episode.symptoms, !symptoms.isEmpty {
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
                if let triggers = episode.triggers, !triggers.isEmpty {
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
                                        .font(.system(size: 15, weight: .medium))
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
                if let notes = episode.notes, !notes.isEmpty {
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
        .navigationTitle("Episode Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EpisodeEditView(episode: episode)
        }
    }

    private func detailSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AuraTheme.primary)

            content()
        }
        .padding(AuraTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .auraCard()
        .padding(.horizontal)
    }
}
