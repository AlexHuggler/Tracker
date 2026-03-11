import SwiftData

/// Shared ModelContainer configuration for use by both the main app and widgets.
/// Requires the App Group entitlement: group.com.aura.shared
enum SharedModelContainer {
    static let appGroupID = "group.com.aura.shared"

    static let schema = Schema([
        Episode.self,
        Symptom.self,
        Trigger.self,
        Medication.self,
        MedicationDose.self,
        DailyLog.self,
        ConditionProfile.self,
        DoctorReport.self,
    ])

    /// Returns a ModelContainer using the shared App Group URL (if available) or the default location.
    static func makeContainer() throws -> ModelContainer {
        let config: ModelConfiguration
        if let storeURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )?.appendingPathComponent("Aura.sqlite") {
            config = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
        } else {
            // Fallback: no App Group available (e.g. simulator without entitlement)
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        }
        return try ModelContainer(for: schema, configurations: [config])
    }
}
