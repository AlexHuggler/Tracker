import SwiftUI

struct StatsCardView: View {
    let title: String
    let value: String
    let subtitle: String?
    var accentColor: Color = AuraTheme.accent

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

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: AuraTheme.cardShadow, radius: 4, y: 2)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        StatsCardView(title: "Episodes", value: "12", subtitle: "this month")
        StatsCardView(title: "Avg Pain", value: "6.2", subtitle: "out of 10", accentColor: AuraTheme.painSevere)
    }
    .padding()
}
