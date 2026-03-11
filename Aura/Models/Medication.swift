import Foundation
import SwiftData
import SwiftUI

enum MedicationType: String, Codable, CaseIterable, Identifiable {
    case acute = "Acute"
    case preventive = "Preventive"
    case supplement = "Supplement"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .acute: return AuraTheme.painSevere
        case .preventive: return AuraTheme.accent
        case .supplement: return AuraTheme.painMild
        }
    }
}

@Model
final class Medication {
    var id: UUID
    var name: String
    var medicationTypeRaw: String
    var dosage: String
    var frequency: String?
    var maxDosesPerDay: Int?
    var reminderTime: Date?
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var doses: [MedicationDose]?

    var medicationType: MedicationType {
        get { MedicationType(rawValue: medicationTypeRaw) ?? .acute }
        set { medicationTypeRaw = newValue.rawValue }
    }

    init(
        name: String,
        medicationType: MedicationType,
        dosage: String,
        frequency: String? = nil,
        maxDosesPerDay: Int? = nil,
        reminderTime: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.medicationTypeRaw = medicationType.rawValue
        self.dosage = dosage
        self.frequency = frequency
        self.maxDosesPerDay = maxDosesPerDay
        self.reminderTime = reminderTime
        self.isActive = isActive
        self.createdAt = Date()
    }
}

extension Medication {
    static let commonMedications: [(name: String, type: MedicationType, dosage: String)] = [
        ("Sumatriptan", .acute, "50mg"),
        ("Rizatriptan", .acute, "10mg"),
        ("Ibuprofen", .acute, "400mg"),
        ("Acetaminophen", .acute, "500mg"),
        ("Naproxen", .acute, "500mg"),
        ("Topiramate", .preventive, "50mg"),
        ("Amitriptyline", .preventive, "25mg"),
        ("Propranolol", .preventive, "40mg"),
        ("Verapamil", .preventive, "120mg"),
        ("Magnesium", .supplement, "400mg"),
        ("Riboflavin", .supplement, "400mg"),
        ("CoQ10", .supplement, "100mg"),
    ]
}
