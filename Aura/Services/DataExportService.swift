import Foundation
import SwiftData

actor DataExportService {

    enum ExportFormat {
        case csv
        case json
    }

    func exportEpisodes(_ episodes: [Episode], format: ExportFormat) -> Data? {
        switch format {
        case .csv: return exportCSV(episodes)
        case .json: return exportJSON(episodes)
        }
    }

    private func exportCSV(_ episodes: [Episode]) -> Data? {
        var lines: [String] = []
        lines.append("Date,Pain Level,End Pain Level,Duration (min),Symptoms,Triggers,Medications,Notes")

        for episode in episodes.sorted(by: { $0.timestamp > $1.timestamp }) {
            let date = episode.timestamp.shortDateTimeString
            let pain = "\(episode.painLevel)"
            let endPain = episode.endPainLevel.map { "\($0)" } ?? ""

            let durationMin: String
            if let dur = episode.duration {
                durationMin = "\(Int(dur / 60))"
            } else {
                durationMin = ""
            }

            let symptoms = (episode.symptoms ?? []).map(\.name).joined(separator: "; ")
            let triggers = (episode.triggers ?? []).map(\.name).joined(separator: "; ")
            let meds = (episode.medicationDoses ?? []).compactMap { $0.medication?.name }.joined(separator: "; ")
            let notes = episode.notes?.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "\n", with: " ") ?? ""

            lines.append("\(csvEscape(date)),\(pain),\(endPain),\(durationMin),\(csvEscape(symptoms)),\(csvEscape(triggers)),\(csvEscape(meds)),\(csvEscape(notes))")
        }

        return lines.joined(separator: "\n").data(using: .utf8)
    }

    private func exportJSON(_ episodes: [Episode]) -> Data? {
        let records = episodes.sorted(by: { $0.timestamp > $1.timestamp }).map { episode -> [String: Any] in
            var record: [String: Any] = [
                "date": episode.timestamp.shortDateTimeString,
                "painLevel": episode.painLevel
            ]
            if let endPain = episode.endPainLevel {
                record["endPainLevel"] = endPain
            }
            if let dur = episode.duration {
                record["durationMinutes"] = Int(dur / 60)
            }
            if let symptoms = episode.symptoms, !symptoms.isEmpty {
                record["symptoms"] = symptoms.map(\.name)
            }
            if let triggers = episode.triggers, !triggers.isEmpty {
                record["triggers"] = triggers.map(\.name)
            }
            if let doses = episode.medicationDoses, !doses.isEmpty {
                record["medications"] = doses.compactMap { $0.medication?.name }
            }
            if let notes = episode.notes, !notes.isEmpty {
                record["notes"] = notes
            }
            return record
        }

        return try? JSONSerialization.data(withJSONObject: records, options: [.prettyPrinted, .sortedKeys])
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
