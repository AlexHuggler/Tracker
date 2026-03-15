import SwiftUI
import SwiftData

@main
struct AuraApp: App {
    @State private var appState = AppState()
    @State private var showDataError = false

    static let containerResult: (container: ModelContainer, isFallback: Bool) = {
        do {
            return (try SharedModelContainer.makeContainer(), false)
        } catch {
            // Fallback to in-memory container so the app can launch
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let fallback = try! ModelContainer(for: SharedModelContainer.schema, configurations: config)
            return (fallback, true)
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .modelContainer(Self.containerResult.container)
                .alert("Data Unavailable", isPresented: $showDataError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your data could not be loaded. The app is running with temporary storage. Please restart or contact support if the issue persists.")
                }
                .onAppear {
                    if Self.containerResult.isFallback {
                        showDataError = true
                    }
                }
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
                    // 2.1: Pass pre-filled context (date, medications) to QuickLogView
                    QuickLogView(
                        preselectedDate: appState.quickLogDate,
                        preselectedMedicationIDs: appState.quickLogMedicationIDs
                    )
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
