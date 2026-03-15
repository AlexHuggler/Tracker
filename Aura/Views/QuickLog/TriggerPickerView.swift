import SwiftUI

struct TriggerPickerView: View {
    @Binding var selectedTriggers: Set<String>
    var availableTriggers: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Potential Triggers")
                .font(AuraTheme.headingFont)
                .foregroundStyle(AuraTheme.primary)

            FlowLayout(spacing: 10) {
                ForEach(availableTriggers, id: \.self) { trigger in
                    PillButton(
                        title: trigger,
                        isSelected: selectedTriggers.contains(trigger)
                    ) {
                        if trigger == "I don't know" {
                            // Selecting "I don't know" clears other selections
                            if selectedTriggers.contains(trigger) {
                                selectedTriggers.remove(trigger)
                            } else {
                                selectedTriggers = [trigger]
                            }
                        } else {
                            // Selecting a specific trigger clears "I don't know"
                            selectedTriggers.remove("I don't know")
                            if selectedTriggers.contains(trigger) {
                                selectedTriggers.remove(trigger)
                            } else {
                                selectedTriggers.insert(trigger)
                            }
                        }
                        HapticsManager.shared.selectionChanged()
                    }
                }
            }

            // 1.6: Explain "I don't know" mutual exclusion behavior
            Text("Tip: selecting \"I don't know\" clears other triggers, and vice versa.")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
    }
}

#Preview {
    @Previewable @State var selected: Set<String> = []
    TriggerPickerView(
        selectedTriggers: $selected,
        availableTriggers: Trigger.defaultTriggers
    )
    .padding()
}
