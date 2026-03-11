import Foundation
import SwiftData

@Model
final class Trigger {
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

extension Trigger {
    static let defaultTriggers: [String] = [
        "Poor sleep",
        "Stress",
        "Weather change",
        "Alcohol",
        "Caffeine (too much)",
        "Caffeine (withdrawal)",
        "Dehydration",
        "Skipped meal",
        "Bright lights",
        "Strong smells",
        "Hormonal",
        "Exercise",
        "Screen time",
        "I don't know"
    ]
}
