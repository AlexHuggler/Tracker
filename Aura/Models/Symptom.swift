import Foundation
import SwiftData

@Model
final class Symptom {
    var id: UUID
    var name: String
    var isCustom: Bool

    @Relationship
    var episode: Episode?

    init(name: String, isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.isCustom = isCustom
    }
}

extension Symptom {
    static let defaultMigraineSymptoms: [String] = [
        "Throbbing", "Aura", "Nausea", "Light sensitivity", "Sound sensitivity",
        "Dizziness", "Neck pain", "Brain fog", "Visual disturbance"
    ]

    static let defaultIBSSymptoms: [String] = [
        "Cramping", "Bloating", "Nausea", "Urgency", "Constipation", "Fatigue"
    ]

    static let allDefaultSymptoms: [String] = [
        "Throbbing", "Aura", "Nausea", "Light sensitivity", "Sound sensitivity",
        "Dizziness", "Neck pain", "Brain fog", "Visual disturbance",
        "Cramping", "Bloating", "Urgency", "Constipation", "Fatigue",
        "Pressure", "Tightness", "Jaw pain", "Eye pain", "Tearing",
        "Widespread pain", "Sleep issues", "Stiffness", "Tingling",
        "Swelling", "Reduced range", "Spasm", "Radiating pain"
    ]
}
