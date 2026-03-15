import SwiftUI

struct PainSliderView: View {
    @Binding var painLevel: Int
    var isDimMode: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // 4.6: Dim mode glow animation
    @State private var glowPulse = false

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
                .font(.system(.headline, design: .rounded, weight: .medium))
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

                    // Thumb with optional dim mode glow (4.6)
                    ZStack {
                        if isDimMode {
                            Circle()
                                .fill(AuraTheme.painColor(for: painLevel).opacity(glowPulse ? 0.35 : 0.15))
                                .frame(width: thumbSize + 24, height: thumbSize + 24)
                                .blur(radius: 16)
                        }

                        Circle()
                            .fill(Color.white)
                            .frame(width: thumbSize, height: thumbSize)
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                            .overlay {
                                Circle()
                                    .stroke(AuraTheme.painColor(for: painLevel), lineWidth: 3)
                            }
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
                                        // 3.6: Graduated haptics based on pain level
                                        HapticsManager.shared.painLevelTick(level: newLevel)
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
        .onAppear {
            // 4.6: Start glow pulse animation when in dim mode
            if isDimMode && !reduceMotion {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue("Pain level \(painLevel)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                painLevel = min(10, painLevel + 1)
                HapticsManager.shared.painLevelTick(level: painLevel)
            case .decrement:
                painLevel = max(0, painLevel - 1)
                HapticsManager.shared.painLevelTick(level: painLevel)
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
