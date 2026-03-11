import SwiftUI
import SwiftData

struct CalendarHeatmapView: View {
    let episodes: [Episode]
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var painByDay: [Date: Int] {
        var result: [Date: Int] = [:]
        for episode in episodes {
            let day = episode.timestamp.startOfDay
            let existing = result[day] ?? 0
            result[day] = max(existing, episode.painLevel)
        }
        return result
    }

    private var daysInMonth: [Date?] {
        let startOfMonth = displayedMonth.startOfMonth
        let firstWeekday = startOfMonth.firstWeekdayOfMonth - 1 // 0-indexed
        let daysCount = displayedMonth.daysInMonth

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in 0..<daysCount {
            if let date = Calendar.current.date(byAdding: .day, value: day, to: startOfMonth) {
                days.append(date)
            }
        }

        // Pad to complete the last row
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = displayedMonth.adding(months: -1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: AuraTheme.minTouchTarget, height: AuraTheme.minTouchTarget)
                }

                Spacer()

                Text(displayedMonth.monthYearString)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AuraTheme.primary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = displayedMonth.adding(months: 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: AuraTheme.minTouchTarget, height: AuraTheme.minTouchTarget)
                }
                .disabled(Calendar.current.isDate(displayedMonth, equalTo: Date(), toGranularity: .month))
            }

            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(height: 20)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(
                            date: date,
                            painLevel: painByDay[date.startOfDay],
                            isToday: date.isSameDay(as: Date()),
                            isSelected: selectedDate?.isSameDay(as: date) == true
                        )
                        .onTapGesture {
                            selectedDate = date
                            HapticsManager.shared.lightTap()
                        }
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }

            // Selected day detail
            if let selectedDate,
               let dayEpisodes = episodesForDate(selectedDate),
               !dayEpisodes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedDate.shortDateString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AuraTheme.primary)

                    ForEach(dayEpisodes) { episode in
                        HStack {
                            PainBadge(level: episode.painLevel)
                            Text(episode.timestamp.shortTimeString)
                                .font(AuraTheme.captionFont)
                                .foregroundStyle(.secondary)
                            if let symptoms = episode.symptoms, !symptoms.isEmpty {
                                Text(symptoms.prefix(2).map(\.name).joined(separator: ", "))
                                    .font(AuraTheme.captionFont)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                }
            }
        }
        .padding(AuraTheme.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: AuraTheme.cardShadow, radius: 4, y: 2)
        }
    }

    private func episodesForDate(_ date: Date) -> [Episode]? {
        let filtered = episodes.filter { $0.timestamp.isSameDay(as: date) }
        return filtered.isEmpty ? nil : filtered.sorted { $0.timestamp < $1.timestamp }
    }
}

struct DayCell: View {
    let date: Date
    let painLevel: Int?
    let isToday: Bool
    let isSelected: Bool

    var body: some View {
        ZStack {
            if let painLevel {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AuraTheme.painColor(for: painLevel).opacity(0.7))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray6))
            }

            Text("\(date.dayOfMonth)")
                .font(.system(size: 13, weight: painLevel != nil ? .semibold : .regular))
                .foregroundStyle(painLevel != nil ? .white : .primary)

            if isToday {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AuraTheme.primary, lineWidth: 2)
            }

            if isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AuraTheme.accent, lineWidth: 2)
            }
        }
        .frame(height: 36)
        .accessibilityLabel(
            "\(date.shortDateString)\(painLevel.map { ", pain level \($0)" } ?? ", no episodes")"
        )
    }
}

struct PainBadge: View {
    let level: Int

    var body: some View {
        Text("\(level)")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Circle().fill(AuraTheme.painColor(for: level)))
    }
}
