import SwiftUI
import SwiftData

@main
struct AuraApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        do {
            return try SharedModelContainer.makeContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(appState.isDimMode ? .dark : nil)
                .overlay {
                    if appState.isDimMode {
                        Color.black
                            .opacity(0.4)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.hasCompletedOnboarding {
            MainTabView()
                .sheet(isPresented: Bindable(appState).showingQuickLog) {
                    QuickLogView()
                }
                .sheet(isPresented: Bindable(appState).showingPaywall) {
                    PaywallView()
                }
        } else {
            OnboardingFlowView()
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        TabView(selection: $state.selectedTab) {
            Tab("Dashboard", systemImage: "chart.bar.fill", value: .dashboard) {
                NavigationStack {
                    DashboardView()
                }
            }

            Tab("Episodes", systemImage: "list.bullet.clipboard", value: .episodes) {
                NavigationStack {
                    EpisodeListView()
                }
            }

            Tab("Patterns", systemImage: "waveform.path.ecg", value: .patterns) {
                NavigationStack {
                    PatternView()
                }
            }

            Tab("Meds", systemImage: "pill.fill", value: .medications) {
                NavigationStack {
                    MedicationListView()
                }
            }

            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(AuraTheme.accent)
    }
}
