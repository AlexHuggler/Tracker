import HealthKit
import Foundation

actor HealthKitService {
    static let shared = HealthKitService()
    private let healthStore = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        guard isAvailable else { return false }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        return true
    }

    // MARK: - Sleep Data

    struct SleepData {
        let totalHours: Double
        let bedtime: Date?
        let wakeTime: Date?
    }

    func fetchSleepData(for date: Date) async throws -> SleepData? {
        guard isAvailable else { return nil }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Look at the previous night's sleep (6pm to noon)
        let sleepStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay)!
        let sleepEnd = calendar.date(byAdding: .hour, value: 12, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: sleepStart,
            end: sleepEnd,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = results as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Filter for asleep samples (not just in bed)
                let asleepSamples = samples.filter { sample in
                    sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                }

                let totalSeconds = asleepSamples.reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate)
                }

                let data = SleepData(
                    totalHours: totalSeconds / 3600,
                    bedtime: asleepSamples.first?.startDate,
                    wakeTime: asleepSamples.last?.endDate
                )
                continuation.resume(returning: data)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Step Count

    func fetchStepCount(for date: Date) async throws -> Double {
        guard isAvailable else { return 0 }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let steps = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: steps)
            }

            healthStore.execute(query)
        }
    }
}
