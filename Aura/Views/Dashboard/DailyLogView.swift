import SwiftUI
import SwiftData

struct DailyLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var sleepHours: Double = 7
    @State private var stressLevel: Int = 3
    @State private var notes: String = ""

    private let stressEmojis = ["😌", "🙂", "😐", "😣", "😫"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Sleep hours
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Sleep", systemImage: "moon.zzz")
                            .font(AuraTheme.headingFont)
                            .foregroundStyle(AuraTheme.primary)

                        VStack(spacing: 4) {
                            Text(String(format: "%.1f hours", sleepHours))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(AuraTheme.accent)

                            Slider(value: $sleepHours, in: 0...12, step: 0.5)
                                .tint(AuraTheme.accent)

                            HStack {
                                Text("0h")
                                Spacer()
                                Text("12h")
                            }
                            .font(AuraTheme.captionFont)
                            .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // Stress level
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Stress Level", systemImage: "brain.head.profile")
                            .font(AuraTheme.headingFont)
                            .foregroundStyle(AuraTheme.primary)

                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { level in
                                Button {
                                    stressLevel = level
                                    HapticsManager.shared.selectionChanged()
                                } label: {
                                    Text(stressEmojis[level - 1])
                                        .font(.title2)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background {
                                            RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                                                .fill(stressLevel == level ? AuraTheme.accent.opacity(0.15) : Color(.systemGray6))
                                        }
                                        .overlay {
                                            if stressLevel == level {
                                                RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                                                    .stroke(AuraTheme.accent, lineWidth: 2)
                                            }
                                        }
                                }
                                .accessibilityLabel("Stress level \(level) of 5")
                                .accessibilityAddTraits(stressLevel == level ? .isSelected : [])
                            }
                        }
                    }

                    Divider()

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes", systemImage: "note.text")
                            .font(AuraTheme.headingFont)
                            .foregroundStyle(AuraTheme.primary)

                        TextField("Anything to note about today...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                            .font(AuraTheme.bodyFont)
                    }

                    // Save button
                    Button {
                        saveDailyLog()
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AuraTheme.minTouchTarget)
                            .background {
                                RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                                    .fill(AuraTheme.accent)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Daily Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveDailyLog() {
        let log = DailyLog(
            sleepHours: sleepHours,
            stressLevel: stressLevel,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(log)
        HapticsManager.shared.saveSuccess()
        dismiss()
    }
}
