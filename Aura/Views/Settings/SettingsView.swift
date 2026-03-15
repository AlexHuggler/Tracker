import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        List {
            Section("Tracking") {
                NavigationLink {
                    ConditionProfileView()
                } label: {
                    Label("Conditions", systemImage: "heart.text.clipboard")
                }

                NavigationLink {
                    CustomSymptomsView()
                } label: {
                    Label("Custom Symptoms", systemImage: "stethoscope")
                }

                NavigationLink {
                    CustomTriggersView()
                } label: {
                    Label("Custom Triggers", systemImage: "exclamationmark.triangle")
                }
            }

            Section("Display") {
                Toggle(isOn: $state.isDimMode) {
                    Label("Dim Mode", systemImage: "moon.fill")
                }

                Text("Reduces screen brightness for mid-episode logging when light is painful.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Reports") {
                NavigationLink {
                    ReportBuilderView()
                } label: {
                    HStack {
                        Label("Doctor Report", systemImage: "doc.text.fill")
                        if !appState.isPremium {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Premium") {
                if appState.isPremium {
                    Label("Premium Unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(AuraTheme.accent)
                } else {
                    Button {
                        appState.showingPaywall = true
                    } label: {
                        Label("Unlock Premium", systemImage: "star.fill")
                            .foregroundStyle(AuraTheme.accent)
                    }
                }

                Button("Restore Purchase") {
                    // StoreKit 2 restore handled by PaywallView
                    appState.showingPaywall = true
                }
            }

            Section("Data") {
                NavigationLink {
                    DataExportView()
                } label: {
                    Label("Export My Data", systemImage: "square.and.arrow.up")
                }

                if appState.isPremium {
                    Label("iCloud Sync", systemImage: "icloud")
                    Text("Coming in a future update.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Data Storage")
                    Spacer()
                    Text("On-device only")
                        .foregroundStyle(.secondary)
                }

                Text("Aura does not collect any data. Your health information stays on your device. No accounts, no analytics, no tracking.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
    }
}
