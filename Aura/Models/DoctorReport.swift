import Foundation
import SwiftData

@Model
final class DoctorReport {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var generatedAt: Date
    var includeEpisodeSummary: Bool
    var includeCalendarHeatmap: Bool
    var includeSymptomBreakdown: Bool
    var includeTriggerCorrelations: Bool
    var includeMedicationUsage: Bool
    var includeWeatherCorrelation: Bool
    var includeSleepCorrelation: Bool
    var includeFullLog: Bool
    var pdfBookmark: Data?

    init(
        startDate: Date,
        endDate: Date,
        includeEpisodeSummary: Bool = true,
        includeCalendarHeatmap: Bool = true,
        includeSymptomBreakdown: Bool = true,
        includeTriggerCorrelations: Bool = true,
        includeMedicationUsage: Bool = true,
        includeWeatherCorrelation: Bool = true,
        includeSleepCorrelation: Bool = true,
        includeFullLog: Bool = true
    ) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.generatedAt = Date()
        self.includeEpisodeSummary = includeEpisodeSummary
        self.includeCalendarHeatmap = includeCalendarHeatmap
        self.includeSymptomBreakdown = includeSymptomBreakdown
        self.includeTriggerCorrelations = includeTriggerCorrelations
        self.includeMedicationUsage = includeMedicationUsage
        self.includeWeatherCorrelation = includeWeatherCorrelation
        self.includeSleepCorrelation = includeSleepCorrelation
        self.includeFullLog = includeFullLog
    }
}
