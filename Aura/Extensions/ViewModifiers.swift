import SwiftUI

struct AuraCardModifier: ViewModifier {
    var padding: CGFloat? = nil

    func body(content: Content) -> some View {
        Group {
            if let padding {
                content.padding(padding)
            } else {
                content
            }
        }
        .background {
            RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: AuraTheme.cardShadow, radius: 4, y: 2)
        }
    }
}

extension View {
    func auraCard() -> some View {
        modifier(AuraCardModifier())
    }

    func auraCard(padding: CGFloat) -> some View {
        modifier(AuraCardModifier(padding: padding))
    }
}
