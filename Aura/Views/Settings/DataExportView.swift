import SwiftUI
import SwiftData

struct DataExportView: View {
    @Query(sort: \Episode.timestamp, order: .reverse)
    private var episodes: [Episode]

    @State private var exportedCSV: Data?
    @State private var exportedJSON: Data?
    @State private var isExporting = false

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
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isExporting {
                ProgressView("Exporting...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func exportCSV() async {
        isExporting = true
        exportedCSV = await exportService.exportEpisodes(episodes, format: .csv)
        isExporting = false
        HapticsManager.shared.saveSuccess()
    }

    private func exportJSON() async {
        isExporting = true
        exportedJSON = await exportService.exportEpisodes(episodes, format: .json)
        isExporting = false
        HapticsManager.shared.saveSuccess()
    }
}
