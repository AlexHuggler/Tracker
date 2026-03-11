import SwiftUI

struct PainSliderView: View {
    @Binding var painLevel: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let thumbSize: CGFloat = 44
    private let trackHeight: CGFloat = 16
    private var lastHapticLevel: Int = -1

    var body: some View {
        VStack(spacing: 20) {
            // Pain level number — large and prominent
            Text("\(painLevel)")
                .font(AuraTheme.painLevelFont)
                .foregroundStyle(AuraTheme.painColor(for: painLevel))
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: painLevel)
                .accessibilityLabel("Pain level \(painLevel) out of 10")

            // Category label
            Text(PainCategory.from(level: painLevel).rawValue)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(AuraTheme.painColor(for: painLevel))
                .accessibilityHidden(true)

            // Custom slider track
            GeometryReader { geometry in
                let trackWidth = geometry.size.width
                let usableWidth = trackWidth - thumbSize
                let normalizedValue = CGFloat(painLevel) / 10.0
                let thumbX = normalizedValue * usableWidth

                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: trackHeight)
                        .padding(.horizontal, thumbSize / 2)

                    // Filled track
                    Capsule()
                        .fill(AuraTheme.fullPainGradient)
                        .frame(width: thumbX + thumbSize / 2, height: trackHeight)
                        .padding(.leading, thumbSize / 2)

                    // Tick marks
                    HStack(spacing: 0) {
                        ForEach(0...10, id: \.self) { tick in
                            if tick > 0 {
                                Spacer()
                            }
                            Circle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .padding(.horizontal, thumbSize / 2)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        .overlay {
                            Circle()
                                .stroke(AuraTheme.painColor(for: painLevel), lineWidth: 3)
                        }
                        .offset(x: thumbX)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let newValue = (value.location.x - thumbSize / 2) / usableWidth
                                    let clamped = min(1, max(0, newValue))
                                    let newLevel = Int(round(clamped * 10))
                                    if newLevel != painLevel {
                                        painLevel = newLevel
                                        HapticsManager.shared.sliderTick()
                                    }
                                }
                        )
                }
                .frame(height: thumbSize)
            }
            .frame(height: thumbSize)
            .padding(.horizontal, 8)

            // Scale labels
            HStack {
                Text("0")
                    .font(AuraTheme.captionFont)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("5")
                    .font(AuraTheme.captionFont)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("10")
                    .font(AuraTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, thumbSize / 2 + 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue("Pain level \(painLevel)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                painLevel = min(10, painLevel + 1)
                HapticsManager.shared.sliderTick()
            case .decrement:
                painLevel = max(0, painLevel - 1)
                HapticsManager.shared.sliderTick()
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    @Previewable @State var level = 5
    PainSliderView(painLevel: $level)
        .padding()
}
