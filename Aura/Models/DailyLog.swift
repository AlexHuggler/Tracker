import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: UUID
    var date: Date
    var sleepHours: Double?
    var stressLevel: Int?
    var weatherPressure: Double?
    var weatherTemperature: Double?
    var weatherHumidity: Double?
    var weatherDescription: String?
    var notes: String?

    init(
        date: Date = Date(),
        sleepHours: Double? = nil,
        stressLevel: Int? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.sleepHours = sleepHours
        self.stressLevel = stressLevel
        self.notes = notes
    }
}
