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

// MARK: - Error Alert Modifier (B.2)

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: String?

    func body(content: Content) -> some View {
        content.alert("Something went wrong", isPresented: .init(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error ?? "")
        }
    }
}

// MARK: - Loading Overlay Modifier (C.5)

struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let message: String

    func body(content: Content) -> some View {
        content.overlay {
            if isLoading {
                ProgressView(message)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AuraTheme.cornerRadius))
            }
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

    func errorAlert(_ error: Binding<String?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }

    func loadingOverlay(_ isLoading: Bool, message: String = "Loading...") -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
}
