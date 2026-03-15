import SwiftUI
import SwiftData

struct ReportBuilderView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Episode.timestamp, order: .reverse)
    private var episodes: [Episode]

    @Query private var medications: [Medication]
    @Query private var dailyLogs: [DailyLog]

    // 1.5: Pre-fill patient name from UserDefaults
    @State private var patientName: String = UserDefaults.standard.string(forKey: "reportPatientName") ?? ""
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var includeEpisodeSummary = true
    @State private var includeCalendarHeatmap = true
    @State private var includeSymptomBreakdown = true
    @State private var includeTriggerCorrelations = true
    @State private var includeMedicationUsage = true
    @State private var includeWeatherCorrelation = true
    @State private var includeSleepCorrelation = true
    @State private var includeFullLog = true
    @State private var isGenerating = false
    @State private var generatedPDFData: Data?
    @State private var showingPreview = false

    var body: some View {
        List {
            Section("Patient Info") {
                TextField("Name (for report header)", text: $patientName)
            }

            Section("Date Range") {
                DatePicker("From", selection: $startDate, displayedComponents: .date)
                DatePicker("To", selection: $endDate, displayedComponents: .date)
            }

            Section("Include in Report") {
                Toggle("Episode Summary", isOn: $includeEpisodeSummary)
                Toggle("Calendar Heatmap", isOn: $includeCalendarHeatmap)
                Toggle("Symptom Breakdown", isOn: $includeSymptomBreakdown)
                Toggle("Trigger Correlations", isOn: $includeTriggerCorrelations)
                Toggle("Medication Usage", isOn: $includeMedicationUsage)
                Toggle("Weather Correlation", isOn: $includeWeatherCorrelation)
                Toggle("Sleep Correlation", isOn: $includeSleepCorrelation)
                Toggle("Full Episode Log", isOn: $includeFullLog)
            }

            Section {
                let filteredCount = episodes.filter {
                    $0.timestamp >= startDate && $0.timestamp <= endDate
                }.count

                Text("\(filteredCount) episodes in selected range")
                    .font(AuraTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    generateReport()
                } label: {
                    HStack {
                        Spacer()
                        if isGenerating {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(isGenerating ? "Generating..." : "Generate PDF Report")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                            .fill(AuraTheme.accent)
                    }
                }
                .disabled(isGenerating || patientName.isEmpty)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Doctor Report")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPreview) {
            if let pdfData = generatedPDFData {
                ReportPreviewView(pdfData: pdfData, patientName: patientName)
            }
        }
    }

    private func generateReport() {
        isGenerating = true

        Task {
            let config = PDFReportGenerator.ReportConfig(
                patientName: patientName,
                startDate: startDate,
                endDate: endDate,
                includeEpisodeSummary: includeEpisodeSummary,
                includeCalendarHeatmap: includeCalendarHeatmap,
                includeSymptomBreakdown: includeSymptomBreakdown,
                includeTriggerCorrelations: includeTriggerCorrelations,
                includeMedicationUsage: includeMedicationUsage,
                includeWeatherCorrelation: includeWeatherCorrelation,
                includeSleepCorrelation: includeSleepCorrelation,
                includeFullLog: includeFullLog
            )

            // Run pattern analysis for correlations
            let engine = PatternEngine()
            let correlations = await engine.analyzeTriggerCorrelations(episodes: episodes)

            let generator = PDFReportGenerator()
            let data = generator.generateReport(
                config: config,
                episodes: episodes,
                medications: medications,
                triggerCorrelations: correlations
            )

            // Save report metadata
            let report = DoctorReport(
                startDate: startDate,
                endDate: endDate,
                includeEpisodeSummary: includeEpisodeSummary,
                includeCalendarHeatmap: includeCalendarHeatmap,
                includeSymptomBreakdown: includeSymptomBreakdown,
                includeTriggerCorrelations: includeTriggerCorrelations,
                includeMedicationUsage: includeMedicationUsage,
                includeWeatherCorrelation: includeWeatherCorrelation,
                includeSleepCorrelation: includeSleepCorrelation,
                includeFullLog: includeFullLog
            )
            modelContext.insert(report)

            await MainActor.run {
                generatedPDFData = data
                isGenerating = false
                showingPreview = true
                // 1.5: Remember patient name for next time
                UserDefaults.standard.set(patientName, forKey: "reportPatientName")
                HapticsManager.shared.saveSuccess()
            }
        }
    }
}
