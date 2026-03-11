import SwiftUI
import SwiftData

struct ConditionSetupView: View {
    let onContinue: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var selectedConditions: Set<ConditionType> = []

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(AuraTheme.accent)

            Text("What do you track?")
                .font(AuraTheme.headingFont)
                .foregroundStyle(AuraTheme.primary)

            Text("Select all that apply. You can change this later.")
                .font(AuraTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Condition selection grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ConditionType.allCases) { condition in
                    ConditionCard(
                        condition: condition,
                        isSelected: selectedConditions.contains(condition)
                    ) {
                        if selectedConditions.contains(condition) {
                            selectedConditions.remove(condition)
                        } else {
                            selectedConditions.insert(condition)
                        }
                        HapticsManager.shared.selectionChanged()
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                saveConditions()
                onContinue()
            } label: {
                Text(selectedConditions.isEmpty ? "Skip" : "Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AuraTheme.minTouchTarget)
                    .background {
                        RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                            .fill(AuraTheme.accent)
                    }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func saveConditions() {
        for conditionType in selectedConditions {
            let profile = ConditionProfile(conditionType: conditionType)
            modelContext.insert(profile)
        }
    }
}

struct ConditionCard: View {
    let condition: ConditionType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: condition.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? .white : AuraTheme.accent)

                Text(condition.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : AuraTheme.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background {
                RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                    .fill(isSelected ? AuraTheme.accent : Color(.systemBackground))
                    .shadow(color: AuraTheme.cardShadow, radius: 4, y: 2)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                        .stroke(AuraTheme.accent, lineWidth: 2)
                }
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
