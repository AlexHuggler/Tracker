import SwiftUI

struct PremiumGateView: View {
    @Environment(AppState.self) private var appState

    let feature: String
    let icon: String
    let description: String

    var body: some View {
        ContentUnavailableView {
            Label(feature, systemImage: icon)
        } description: {
            Text(description)
        } actions: {
            Button("Unlock \(feature)") {
                appState.showingPaywall = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AuraTheme.accent)
        }
    }
}

#Preview {
    PremiumGateView(
        feature: "Pattern Analysis",
        icon: "waveform.path.ecg",
        description: "Unlock pattern detection to discover what triggers your episodes."
    )
    .environment(AppState())
}
