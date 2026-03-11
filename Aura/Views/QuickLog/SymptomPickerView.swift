import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangementResult(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangementResult(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private struct ArrangementResult {
        var positions: [CGPoint]
        var sizes: [CGSize]
        var size: CGSize
    }

    private func arrangementResult(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, x - spacing)
            totalHeight = y + rowHeight
        }

        return ArrangementResult(
            positions: positions,
            sizes: sizes,
            size: CGSize(width: totalWidth, height: totalHeight)
        )
    }
}

struct SymptomPickerView: View {
    @Binding var selectedSymptoms: Set<String>
    var availableSymptoms: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptoms")
                .font(AuraTheme.headingFont)
                .foregroundStyle(AuraTheme.primary)

            FlowLayout(spacing: 10) {
                ForEach(availableSymptoms, id: \.self) { symptom in
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
}

struct PillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AuraTheme.pillFont)
                .padding(.horizontal, 20)
                .frame(minHeight: AuraTheme.pillHeight)
                .background {
                    Capsule()
                        .fill(isSelected ? AuraTheme.accent : Color.clear)
                }
                .overlay {
                    Capsule()
                        .stroke(isSelected ? AuraTheme.accent : Color.gray.opacity(0.3), lineWidth: 2)
                }
                .foregroundStyle(isSelected ? .white : AuraTheme.primary)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selected: Set<String> = ["Nausea"]
    SymptomPickerView(
        selectedSymptoms: $selected,
        availableSymptoms: Symptom.defaultMigraineSymptoms
    )
    .padding()
}
