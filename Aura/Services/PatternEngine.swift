import Foundation
import SwiftData

enum ConfidenceLevel: String, Codable {
    case preliminary = "Early Signal"
    case likely = "Likely"
    case strong = "Strong"
    case veryStrong = "Very Strong"

    static func from(correlation: Double, isPreliminary: Bool = false) -> ConfidenceLevel? {
        let abs = Swift.abs(correlation)
        switch abs {
        case 0.90...: return .veryStrong
        case 0.75..<0.90: return .strong
        case 0.60..<0.75: return .likely
        case 0.50..<0.60 where isPreliminary: return .preliminary
        default: return nil
        }
    }

    var icon: String {
        switch self {
        case .preliminary: return "sparkles"
        case .likely: return "chart.bar.fill"
        case .strong: return "chart.bar.xaxis.ascending"
        case .veryStrong: return "checkmark.seal.fill"
        }
    }
}

/// Represents how frequently a trigger appears across episodes.
/// Note: Because triggers are only logged during episodes (no non-episode baseline),
/// this is a frequency measure, not a statistical correlation.
struct TriggerCorrelation: Identifiable {
    let id = UUID()
    let triggerName: String
    let episodesWithTrigger: Int
    let totalEpisodes: Int
    /// Proportion of episodes where this trigger was logged (0–1).
    let frequency: Double
    let confidence: ConfidenceLevel

    var percentage: Double {
        guard totalEpisodes > 0 else { return 0 }
        return Double(episodesWithTrigger) / Double(totalEpisodes) * 100
    }
}

struct TemporalPattern: Identifiable {
    let id = UUID()
    let description: String
    let detail: String
    let confidence: ConfidenceLevel
}

struct WeatherPattern: Identifiable {
    let id = UUID()
    let description: String
    let avgPressureDropBeforeEpisode: Double
    let avgPressureDropNonEpisode: Double
    let confidence: ConfidenceLevel
}

struct MedicationEffectiveness: Identifiable {
    let id = UUID()
    let medicationName: String
    let timesUsed: Int
    let avgReliefMinutes: Double?
    let avgPainReduction: Double?
    let friendlyDescription: String
}

actor PatternEngine {
    static let minimumEpisodes = 10
    static let preliminaryEpisodes = 5
    static let minimumCorrelation = 0.60
    static let preliminaryCorrelation = 0.50

    // MARK: - Trigger Correlations

    func analyzeTriggerCorrelations(episodes: [Episode]) -> [TriggerCorrelation] {
        let isPreliminary = episodes.count < Self.minimumEpisodes
        guard episodes.count >= Self.preliminaryEpisodes else { return [] }

        let minCorrelation = isPreliminary ? Self.preliminaryCorrelation : Self.minimumCorrelation

        var triggerCounts: [String: Int] = [:]
        for episode in episodes {
            for trigger in episode.triggers ?? [] {
                triggerCounts[trigger.name, default: 0] += 1
            }
        }

        var results: [TriggerCorrelation] = []
        for (triggerName, count) in triggerCounts {
            let proportion = Double(count) / Double(episodes.count)
            guard proportion >= minCorrelation,
                  let confidence = ConfidenceLevel.from(correlation: proportion, isPreliminary: isPreliminary) else {
                continue
            }

            results.append(TriggerCorrelation(
                triggerName: triggerName,
                episodesWithTrigger: count,
                totalEpisodes: episodes.count,
                frequency: proportion,
                confidence: confidence
            ))
        }

        return results.sorted { $0.frequency > $1.frequency }
    }

    // MARK: - Temporal Patterns

    func analyzeTemporalPatterns(episodes: [Episode]) -> [TemporalPattern] {
        guard episodes.count >= Self.preliminaryEpisodes else { return [] }

        var patterns: [TemporalPattern] = []

        // Day of week analysis
        var dayCounts = [Int](repeating: 0, count: 7)
        for episode in episodes {
            let weekday = Calendar.current.component(.weekday, from: episode.timestamp) - 1
            dayCounts[weekday] += 1
        }

        let avgPerDay = Double(episodes.count) / 7.0
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        for (index, count) in dayCounts.enumerated() {
            let ratio = Double(count) / avgPerDay
            if ratio >= 1.8, let confidence = ConfidenceLevel.from(correlation: min(ratio / 3.0, 1.0)) {
                patterns.append(TemporalPattern(
                    description: "\(dayNames[index])s are harder",
                    detail: "\(count) of your \(episodes.count) episodes occurred on \(dayNames[index])s — \(String(format: "%.0f", ratio))x the average.",
                    confidence: confidence
                ))
            }
        }

        // Time of day analysis
        var timeBuckets = [Int](repeating: 0, count: 4) // morning, afternoon, evening, night
        for episode in episodes {
            let hour = Calendar.current.component(.hour, from: episode.timestamp)
            switch hour {
            case 5..<12: timeBuckets[0] += 1
            case 12..<17: timeBuckets[1] += 1
            case 17..<22: timeBuckets[2] += 1
            default: timeBuckets[3] += 1
            }
        }

        let bucketNames = ["mornings", "afternoons", "evenings", "nights"]
        let avgPerBucket = Double(episodes.count) / 4.0
        for (index, count) in timeBuckets.enumerated() {
            let ratio = Double(count) / avgPerBucket
            if ratio >= 1.8, let confidence = ConfidenceLevel.from(correlation: min(ratio / 3.0, 1.0)) {
                patterns.append(TemporalPattern(
                    description: "Episodes cluster in \(bucketNames[index])",
                    detail: "\(count) of your \(episodes.count) episodes started during \(bucketNames[index]).",
                    confidence: confidence
                ))
            }
        }

        return patterns
    }

    // MARK: - Weather Correlation

    func analyzeWeatherCorrelation(
        episodes: [Episode],
        dailyLogs: [DailyLog]
    ) -> [WeatherPattern] {
        guard episodes.count >= Self.preliminaryEpisodes else { return [] }

        let logsByDate = Dictionary(grouping: dailyLogs) { $0.date.startOfDay }
        let episodeDates = Set(episodes.map { $0.timestamp.startOfDay })

        var pressureBeforeEpisode: [Double] = []
        var pressureNonEpisode: [Double] = []

        for (date, logs) in logsByDate {
            guard let pressure = logs.first?.weatherPressure else { continue }
            if episodeDates.contains(date) {
                pressureBeforeEpisode.append(pressure)
            } else {
                pressureNonEpisode.append(pressure)
            }
        }

        guard pressureBeforeEpisode.count >= 5, pressureNonEpisode.count >= 5 else { return [] }

        let avgEpisodePressure = pressureBeforeEpisode.reduce(0, +) / Double(pressureBeforeEpisode.count)
        let avgNonEpisodePressure = pressureNonEpisode.reduce(0, +) / Double(pressureNonEpisode.count)

        // Build paired arrays: pressure vs binary episode indicator (1 = episode day, 0 = no episode)
        var pressures: [Double] = []
        var episodeIndicators: [Double] = []
        for (date, logs) in logsByDate {
            guard let pressure = logs.first?.weatherPressure else { continue }
            pressures.append(pressure)
            episodeIndicators.append(episodeDates.contains(date) ? 1.0 : 0.0)
        }

        let r = pearsonCorrelation(x: pressures, y: episodeIndicators)

        if abs(r) > 0.15 {
            let confidence: ConfidenceLevel = abs(r) > 0.4 ? .strong : .likely
            return [WeatherPattern(
                description: "Barometric pressure may be a factor",
                avgPressureDropBeforeEpisode: avgEpisodePressure,
                avgPressureDropNonEpisode: avgNonEpisodePressure,
                confidence: confidence
            )]
        }

        return []
    }

    // MARK: - Medication Effectiveness

    func analyzeMedicationEffectiveness(
        medications: [Medication],
        episodes: [Episode]
    ) -> [MedicationEffectiveness] {
        var results: [MedicationEffectiveness] = []

        for medication in medications where medication.medicationType == .acute {
            let doses = medication.doses ?? []
            guard doses.count >= 3 else { continue }

            // Calculate average pain reduction for episodes where this med was used
            var painReductions: [Double] = []
            var reliefTimes: [Double] = []

            for dose in doses {
                guard let episode = dose.episode else { continue }

                // If episode has end time, calculate relief time from dose to episode end
                if let endTime = episode.endTimestamp {
                    let minutes = endTime.timeIntervalSince(dose.timestamp) / 60
                    if minutes > 0 && minutes < 480 {
                        reliefTimes.append(minutes)
                    }
                }
            }
                // Calculate pain reduction if endPainLevel is available
                if let endPain = episode.endPainLevel {
                    let reduction = Double(episode.painLevel - endPain)
                    if reduction > 0 {
                        painReductions.append(reduction)
                    }
                }

            let avgRelief = reliefTimes.isEmpty ? nil : reliefTimes.reduce(0, +) / Double(reliefTimes.count)
            let avgPainReduction = painReductions.isEmpty ? nil : painReductions.reduce(0, +) / Double(painReductions.count)

            var description = "\(medication.name) was used \(doses.count) times."
            if let avgRelief {
                let minutes = Int(avgRelief)
                description = "\(medication.name) seems to help most episodes within about \(minutes) minutes."
            }

            results.append(MedicationEffectiveness(
                medicationName: medication.name,
                timesUsed: doses.count,
                avgReliefMinutes: avgRelief,
                avgPainReduction: avgPainReduction,
                friendlyDescription: description
            ))
        }

        return results
    }

    // MARK: - Statistical Helpers

    private func pearsonCorrelation(x: [Double], y: [Double]) -> Double {
        guard x.count == y.count, x.count > 2 else { return 0 }

        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        guard denominator > 0 else { return 0 }
        return numerator / denominator
    }
}
