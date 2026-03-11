import Foundation
import SwiftData

@Model
final class Episode {
    var id: UUID
    var painLevel: Int
    var timestamp: Date
    var endTimestamp: Date?
    var notes: String?

    @Relationship(deleteRule: .cascade)
    var symptoms: [Symptom]?

    @Relationship(deleteRule: .cascade)
    var triggers: [Trigger]?

    @Relationship(deleteRule: .nullify)
    var medicationDoses: [MedicationDose]?

    var conditions: [ConditionProfile]?

    var painCategory: PainCategory {
        PainCategory.from(level: painLevel)
    }

    var duration: TimeInterval? {
        guard let end = endTimestamp else { return nil }
        return end.timeIntervalSince(timestamp)
    }

    var formattedDuration: String? {
        guard let dur = duration else { return nil }
        let hours = Int(dur) / 3600
        let minutes = (Int(dur) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    init(
        painLevel: Int,
        timestamp: Date = Date(),
        endTimestamp: Date? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.painLevel = min(10, max(0, painLevel))
        self.timestamp = timestamp
        self.endTimestamp = endTimestamp
        self.notes = notes
    }
}

enum PainCategory: String, Codable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    case extreme = "Extreme"

    static func from(level: Int) -> PainCategory {
        switch level {
        case 0...3: return .mild
        case 4...6: return .moderate
        case 7...8: return .severe
        default: return .extreme
        }
    }

    var colorName: String {
        switch self {
        case .mild: return "painMild"
        case .moderate: return "painModerate"
        case .severe: return "painSevere"
        case .extreme: return "painExtreme"
        }
    }
}
