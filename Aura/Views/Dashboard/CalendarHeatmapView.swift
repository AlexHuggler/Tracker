import SwiftUI
import SwiftData

struct CalendarHeatmapView: View {
    let episodes: [Episode]
    var onLogDate: ((Date) -> Void)? = nil
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date?
    @State private var navigationDirection: NavigationDirection = .forward

    enum NavigationDirection {
        case forward, backward
    }

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
                    navigationDirection = .backward
                    withAnimation(.easeInOut(duration: 0.3)) {
                        displayedMonth = displayedMonth.adding(months: -1)
                        selectedDate = nil
                    }
                    HapticsManager.shared.lightTap()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: AuraTheme.minTouchTarget, height: AuraTheme.minTouchTarget)
                }

                Spacer()

                Text(displayedMonth.monthYearString)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AuraTheme.primary)
                    .id(displayedMonth.monthYearString)
                    .transition(.asymmetric(
                        insertion: .move(edge: navigationDirection == .forward ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: navigationDirection == .forward ? .leading : .trailing).combined(with: .opacity)
                    ))

                Spacer()

                Button {
                    navigationDirection = .forward
                    withAnimation(.easeInOut(duration: 0.3)) {
                        displayedMonth = displayedMonth.adding(months: 1)
                        selectedDate = nil
                    }
                    HapticsManager.shared.lightTap()
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
            if let selectedDate {
                let dayEpisodes = episodesForDate(selectedDate)

                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedDate.shortDateString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AuraTheme.primary)

                    if let dayEpisodes, !dayEpisodes.isEmpty {
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
                    } else if let onLogDate {
                        Button {
                            onLogDate(selectedDate)
                            HapticsManager.shared.lightTap()
                        } label: {
                            Label("Log episode for this day", systemImage: "plus.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AuraTheme.accent)
                        }
                    } else {
                        Text("No episodes")
                            .font(AuraTheme.captionFont)
                            .foregroundStyle(.secondary)
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
        .auraCard()
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
