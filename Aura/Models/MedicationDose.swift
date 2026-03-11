import Foundation
import SwiftData

@Model
final class MedicationDose {
    var id: UUID
    var timestamp: Date
    var dosage: String?

    @Relationship
    var medication: Medication?

    @Relationship
    var episode: Episode?

    init(
        medication: Medication? = nil,
        episode: Episode? = nil,
        timestamp: Date = Date(),
        dosage: String? = nil
    ) {
        self.id = UUID()
        self.medication = medication
        self.episode = episode
        self.timestamp = timestamp
        self.dosage = dosage ?? medication?.dosage
    }
}
