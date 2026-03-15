import SwiftUI
import SwiftData

struct DailyLogHistoryView: View {
    @Query(sort: \DailyLog.date, order: .reverse)
    private var dailyLogs: [DailyLog]

    private let stressEmojis = ["😌", "🙂", "😐", "😣", "😫"]

    private var last14DaysLogs: [DailyLog] {
        let cutoff = Date().adding(days: -14)
        return dailyLogs.filter { $0.date >= cutoff }
    }

    var body: some View {
        List {
            if last14DaysLogs.count >= 3 {
                Section("14-Day Trends") {
                    VStack(alignment: .leading, spacing: 12) {
                        trendRow(label: "Sleep", icon: "moon.zzz", values: last14DaysLogs.reversed().compactMap(\.sleepHours), maxValue: 12, color: AuraTheme.accent)
                        trendRow(label: "Stress", icon: "brain.head.profile", values: last14DaysLogs.reversed().compactMap(\.stressLevel).map(Double.init), maxValue: 5, color: AuraTheme.statusAlert)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("History") {
                if dailyLogs.isEmpty {
                    ContentUnavailableView {
                        Label("No Daily Logs", systemImage: "moon.zzz")
                    } description: {
                        Text("Start logging your daily sleep and stress to see trends.")
                    }
                } else {
                    ForEach(dailyLogs) { log in
                        DailyLogRowView(log: log, stressEmojis: stressEmojis)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Daily Logs")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func trendRow(label: String, icon: String, values: [Double], maxValue: Double, color: Color) -> some View {
        HStack(spacing: 12) {
            Label(label, systemImage: icon)
                .font(AuraTheme.captionFont)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            SparklineView(values: values, maxValue: maxValue, color: color)
                .frame(height: 24)
        }
    }
}

struct SparklineView: View {
    let values: [Double]
    let maxValue: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            if values.count >= 2 {
                Path { path in
                    let stepX = geometry.size.width / CGFloat(values.count - 1)
                    for (index, value) in values.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height * (1 - CGFloat(value / maxValue))
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

struct DailyLogRowView: View {
    let log: DailyLog
    let stressEmojis: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(log.date.shortDateString)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AuraTheme.primary)

            HStack(spacing: 16) {
                if let sleep = log.sleepHours {
                    Label(String(format: "%.1fh", sleep), systemImage: "moon.zzz")
                        .font(AuraTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
                if let stress = log.stressLevel, stress >= 1 && stress <= 5 {
                    HStack(spacing: 4) {
                        Text(stressEmojis[stress - 1])
                        Text("Stress \(stress)/5")
                            .font(AuraTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let notes = log.notes, !notes.isEmpty {
                Text(notes)
                    .font(AuraTheme.captionFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}
