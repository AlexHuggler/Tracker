import SwiftUI

struct StatsCardView: View {
    let title: String
    let value: String
    let subtitle: String?
    var accentColor: Color = AuraTheme.accent

    @State private var displayedValue: String = ""
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(title: String, value: String, subtitle: String? = nil, accentColor: Color = AuraTheme.accent) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(AuraTheme.captionFont)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(hasAppeared ? value : " ")
                .font(.title3.weight(.bold))
                .foregroundStyle(accentColor)
                .contentTransition(.numericText(value: Double(value.filter(\.isNumber).prefix(4)) ?? 0))

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .auraCard()
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 8)
        .onAppear {
            if reduceMotion {
                hasAppeared = true
            } else {
                withAnimation(.easeOut(duration: 0.4)) {
                    hasAppeared = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(subtitle ?? "")")
    }
}

#Preview {
    HStack {
        StatsCardView(title: "Episodes", value: "12", subtitle: "this month")
        StatsCardView(title: "Avg Pain", value: "6.2", subtitle: "out of 10", accentColor: AuraTheme.painSevere)
    }
    .padding()
}
