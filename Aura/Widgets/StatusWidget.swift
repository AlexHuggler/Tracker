import WidgetKit
import SwiftUI
import SwiftData

struct StatusWidgetEntry: TimelineEntry {
    let date: Date
    let daysSinceLastEpisode: Int
    let recentDayPainLevels: [Int?] // Last 7 days, nil = no episode
}

struct StatusWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatusWidgetEntry {
        StatusWidgetEntry(
            date: Date(),
            daysSinceLastEpisode: 3,
            recentDayPainLevels: [nil, 5, nil, nil, 7, nil, nil]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StatusWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusWidgetEntry>) -> Void) {
        let entry = fetchEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> StatusWidgetEntry {
        guard let container = try? SharedModelContainer.makeContainer() else {
            return StatusWidgetEntry(date: Date(), daysSinceLastEpisode: 0, recentDayPainLevels: Array(repeating: nil, count: 7))
        }

        let context = ModelContext(container)
        let now = Date()
        let calendar = Calendar.current

        // Fetch most recent episode for "days since"
        var daysSince = 0
        var recentDescriptor = FetchDescriptor<Episode>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        recentDescriptor.fetchLimit = 1
        if let lastEpisode = try? context.fetch(recentDescriptor).first {
            daysSince = max(0, calendar.dateComponents([.day], from: lastEpisode.timestamp, to: now).day ?? 0)
        }

        // Build 7-day pain levels
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        let predicate = #Predicate<Episode> { episode in
            episode.timestamp >= sevenDaysAgo
        }
        var weekDescriptor = FetchDescriptor<Episode>(predicate: predicate)
        weekDescriptor.fetchLimit = 100

        var painByDay: [Date: Int] = [:]
        if let episodes = try? context.fetch(weekDescriptor) {
            for episode in episodes {
                let day = calendar.startOfDay(for: episode.timestamp)
                painByDay[day] = max(painByDay[day] ?? 0, episode.painLevel)
            }
        }

        var painLevels: [Int?] = []
        for offset in (0..<7).reversed() {
            let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: now)) ?? now
            painLevels.append(painByDay[day])
        }

        return StatusWidgetEntry(date: now, daysSinceLastEpisode: daysSince, recentDayPainLevels: painLevels)
    }
}

struct StatusWidgetView: View {
    let entry: StatusWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.daysSinceLastEpisode)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(daysSinceColor)

                    Text(entry.daysSinceLastEpisode == 1 ? "day since\nlast episode" : "days since\nlast episode")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Link(destination: URL(string: "aura://quicklog")!) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: "1ABC9C"))
                }
            }

            // Mini 7-day heatmap
            HStack(spacing: 3) {
                ForEach(0..<7, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(colorForDay(entry.recentDayPainLevels[index]))
                        .frame(height: 16)
                }
            }

            HStack {
                Text("7 days ago")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("Today")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var daysSinceColor: Color {
        switch entry.daysSinceLastEpisode {
        case 7...: return Color(hex: "1ABC9C")
        case 3...6: return Color(hex: "F1C40F")
        default: return Color(hex: "E74C3C")
        }
    }

    private func colorForDay(_ painLevel: Int?) -> Color {
        guard let level = painLevel else {
            return Color(.systemGray5)
        }
        switch level {
        case 0...3: return Color(hex: "82C785")
        case 4...6: return Color(hex: "F1C40F")
        case 7...8: return Color(hex: "E8853A")
        default: return Color(hex: "E74C3C")
        }
    }
}

struct StatusWidget: Widget {
    let kind: String = "StatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatusWidgetProvider()) { entry in
            StatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Episode Status")
        .description("See days since your last episode and a mini heatmap.")
        .supportedFamilies([.systemMedium])
    }
}
