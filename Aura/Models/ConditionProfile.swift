import Foundation
import SwiftData

enum ConditionType: String, Codable, CaseIterable, Identifiable {
    case migraine = "Migraine"
    case tensionHeadache = "Tension Headache"
    case clusterHeadache = "Cluster Headache"
    case ibs = "IBS"
    case fibromyalgia = "Fibromyalgia"
    case chronicFatigue = "Chronic Fatigue"
    case jointPain = "Joint Pain"
    case backPain = "Back Pain"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .migraine: return "brain.head.profile"
        case .tensionHeadache: return "head.profile.arrow.forward.and.visionpro"
        case .clusterHeadache: return "bolt.circle"
        case .ibs: return "stomach"
        case .fibromyalgia: return "figure.walk"
        case .chronicFatigue: return "battery.25percent"
        case .jointPain: return "figure.flexibility"
        case .backPain: return "figure.stand"
        case .other: return "cross.circle"
        }
    }

    var defaultSymptoms: [String] {
        switch self {
        case .migraine:
            return ["Throbbing", "Aura", "Nausea", "Light sensitivity", "Sound sensitivity",
                    "Dizziness", "Neck pain", "Brain fog", "Visual disturbance"]
        case .tensionHeadache:
            return ["Pressure", "Tightness", "Neck tension", "Jaw pain", "Fatigue"]
        case .clusterHeadache:
            return ["Eye pain", "Tearing", "Nasal congestion", "Restlessness", "Sharp pain"]
        case .ibs:
            return ["Cramping", "Bloating", "Nausea", "Urgency", "Constipation", "Fatigue"]
        case .fibromyalgia:
            return ["Widespread pain", "Fatigue", "Brain fog", "Sleep issues", "Stiffness",
                    "Tingling", "Sensitivity to touch"]
        case .chronicFatigue:
            return ["Extreme tiredness", "Brain fog", "Muscle pain", "Joint pain",
                    "Sleep issues", "Dizziness"]
        case .jointPain:
            return ["Swelling", "Stiffness", "Reduced range", "Warmth", "Grinding"]
        case .backPain:
            return ["Lower back", "Upper back", "Radiating pain", "Stiffness", "Spasm"]
        case .other:
            return ["Pain", "Fatigue", "Nausea", "Stiffness", "Brain fog"]
        }
    }
}

@Model
final class ConditionProfile {
    var id: UUID
    var conditionTypeRaw: String
    var customName: String?
    var isActive: Bool
    var createdAt: Date

    @Relationship(inverse: \Episode.conditions)
    var episodes: [Episode]?

    var conditionType: ConditionType {
        get { ConditionType(rawValue: conditionTypeRaw) ?? .other }
        set { conditionTypeRaw = newValue.rawValue }
    }

    var displayName: String {
        customName ?? conditionType.rawValue
    }

    init(
        conditionType: ConditionType,
        customName: String? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.conditionTypeRaw = conditionType.rawValue
        self.customName = customName
        self.isActive = isActive
        self.createdAt = Date()
    }
}
