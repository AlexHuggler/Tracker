import SwiftUI
import SwiftData

struct DataExportView: View {
    @Query(sort: \Episode.timestamp, order: .reverse)
    private var episodes: [Episode]

    @State private var exportedCSV: Data?
    @State private var exportedJSON: Data?
    @State private var isExporting = false
    @State private var errorMessage: String?

    private let exportService = DataExportService()

    var body: some View {
        List {
            Section {
                Text("\(episodes.count) episodes available to export")
                    .font(AuraTheme.bodyFont)
                    .foregroundStyle(.secondary)
            }

            Section("Export Format") {
                Button {
                    Task { await exportCSV() }
                } label: {
                    Label("Export as CSV", systemImage: "tablecells")
                }

                Button {
                    Task { await exportJSON() }
                } label: {
                    Label("Export as JSON", systemImage: "curlybraces")
                }
            }

            if let exportedCSV {
                Section {
                    ShareLink(
                        item: exportedCSV,
                        preview: SharePreview("Aura Episodes.csv", icon: "tablecells")
                    ) {
                        Label("Share CSV", systemImage: "square.and.arrow.up")
                            .foregroundStyle(AuraTheme.accent)
                    }
                }
            }

            if let exportedJSON {
                Section {
                    ShareLink(
                        item: exportedJSON,
                        preview: SharePreview("Aura Episodes.json", icon: "curlybraces")
                    ) {
                        Label("Share JSON", systemImage: "square.and.arrow.up")
                            .foregroundStyle(AuraTheme.accent)
                    }
                }
            }

            Section {
                Text("Your data stays on your device. Export creates a local file for you to share or save.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .loadingOverlay(isExporting, message: "Exporting...")
        .errorAlert($errorMessage)
    }

    private func exportCSV() async {
        isExporting = true
        let data = await exportService.exportEpisodes(episodes, format: .csv)
        isExporting = false
        if let data {
            exportedCSV = data
            HapticsManager.shared.saveSuccess()
        } else {
            errorMessage = "Failed to export CSV. Please try again."
        }
    }

    private func exportJSON() async {
        isExporting = true
        let data = await exportService.exportEpisodes(episodes, format: .json)
        isExporting = false
        if let data {
            exportedJSON = data
            HapticsManager.shared.saveSuccess()
        } else {
            errorMessage = "Failed to export JSON. Please try again."
        }
    }
}
