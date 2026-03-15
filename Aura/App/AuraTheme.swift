import SwiftUI

enum AuraTheme {
    // MARK: - Colors

    static let primary = Color(hex: "2C3E50")
    static let accent = Color(hex: "1ABC9C")
    static let background = Color(hex: "FAFAF8")
    static let cardBackground = Color.white
    static let cardShadow = Color.black.opacity(0.06)

    // Pain gradient
    static let painMild = Color(hex: "82C785")
    static let painModerate = Color(hex: "F1C40F")
    static let painSevere = Color(hex: "E8853A")
    static let painExtreme = Color(hex: "E74C3C")

    // Status colors
    static let statusGood = Color(hex: "1ABC9C")
    static let statusWarning = Color(hex: "F1C40F")
    static let statusAlert = Color(hex: "E74C3C")

    // Dark mode variants
    static let darkBackground = Color(hex: "1A2332")
    static let darkCardBackground = Color(hex: "243040")
    static let dimOverlay = Color.black.opacity(0.4)

    // MARK: - Typography

    static let painLevelFont = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let headingFont = Font.title3.weight(.semibold)
    static let bodyFont = Font.body
    static let captionFont = Font.caption
    static let pillFont = Font.body.weight(.medium)

    // MARK: - Layout

    static let minTouchTarget: CGFloat = 60
    static let sliderWidth: CGFloat = 300
    static let sliderThumbSize: CGFloat = 44
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let pillHeight: CGFloat = 60
    static let pillCornerRadius: CGFloat = 30

    // MARK: - Pain Color Helpers

    static func painColor(for level: Int) -> Color {
        switch level {
        case 0...3: return painMild
        case 4...5: return painModerate
        case 6...7: return painSevere
        case 8...10: return painExtreme
        default: return painMild
        }
    }

    static func painGradient(for level: Int) -> LinearGradient {
        let color = painColor(for: level)
        return LinearGradient(
            colors: [color.opacity(0.8), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static let fullPainGradient = LinearGradient(
        colors: [painMild, painModerate, painSevere, painExtreme],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Days Since Color

    static func daysSinceColor(_ days: Int) -> Color {
        switch days {
        case 7...: return statusGood
        case 3...6: return statusWarning
        default: return statusAlert
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
