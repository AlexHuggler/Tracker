import SwiftUI

struct StreakBadgeView: View {
    let streak: Int
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isMilestone: Bool {
        [7, 14, 21, 30, 60, 90, 365].contains(streak)
    }

    var body: some View {
        if streak > 1 {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.orange)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(streak)-day streak")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AuraTheme.primary)

                    if isMilestone {
                        Text("Milestone reached!")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AuraTheme.accent)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .auraCard()
            .onAppear {
                if isMilestone && !reduceMotion {
                    withAnimation(.easeInOut(duration: 0.4).repeatCount(3, autoreverses: true)) {
                        isAnimating = true
                    }
                    HapticsManager.shared.saveSuccess()
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StreakBadgeView(streak: 5)
        StreakBadgeView(streak: 7)
        StreakBadgeView(streak: 30)
    }
    .padding()
}
