import SwiftUI
import SwiftData

struct YearlyHeatmapView: View {
    let episodes: [Episode]

    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 2
    private let weekdays = ["M", "", "W", "", "F", "", ""]

    private var painByDay: [Date: Int] {
        var result: [Date: Int] = [:]
        for episode in episodes {
            let day = episode.timestamp.startOfDay
            let existing = result[day] ?? 0
            result[day] = max(existing, episode.painLevel)
        }
        return result
    }

    private var weeksInYear: [[Date?]] {
        let calendar = Calendar.current
        let now = Date()
        guard let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) else { return [] }

        // Start from the beginning of that week
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: yearAgo)?.start ?? yearAgo

        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = []
        var date = startOfWeek

        while date <= now {
            let weekday = calendar.component(.weekday, from: date) - 1 // 0=Sun
            if weekday == 0 && !currentWeek.isEmpty {
                // Pad to 7 days
                while currentWeek.count < 7 { currentWeek.append(nil) }
                weeks.append(currentWeek)
                currentWeek = []
            }
            currentWeek.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86400)
        }
        if !currentWeek.isEmpty {
            while currentWeek.count < 7 { currentWeek.append(nil) }
            weeks.append(currentWeek)
        }

        return weeks
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Episode intensity over the past year")
                    .font(AuraTheme.captionFont)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 0) {
                        // Weekday labels
                        VStack(spacing: cellSpacing) {
                            ForEach(weekdays.indices, id: \.self) { i in
                                Text(weekdays[i])
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 16, height: cellSize)
                            }
                        }
                        .padding(.trailing, 4)

                        // Week columns
                        HStack(spacing: cellSpacing) {
                            ForEach(weeksInYear.indices, id: \.self) { weekIndex in
                                VStack(spacing: cellSpacing) {
                                    ForEach(0..<7, id: \.self) { dayIndex in
                                        if let date = weeksInYear[weekIndex][safe: dayIndex] ?? nil {
                                            let pain = painByDay[date.startOfDay]
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(pain.map { AuraTheme.painColor(for: $0).opacity(0.8) } ?? Color(.systemGray6))
                                                .frame(width: cellSize, height: cellSize)
                                                .accessibilityLabel("\(date.shortDateString)\(pain.map { ", pain \($0)" } ?? "")")
                                        } else {
                                            Color.clear
                                                .frame(width: cellSize, height: cellSize)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Legend
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray6))
                        .frame(width: cellSize, height: cellSize)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AuraTheme.painMild.opacity(0.8))
                        .frame(width: cellSize, height: cellSize)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AuraTheme.painModerate.opacity(0.8))
                        .frame(width: cellSize, height: cellSize)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AuraTheme.painSevere.opacity(0.8))
                        .frame(width: cellSize, height: cellSize)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AuraTheme.painExtreme.opacity(0.8))
                        .frame(width: cellSize, height: cellSize)
                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Yearly Overview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
