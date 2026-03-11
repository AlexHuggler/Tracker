import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Episode.timestamp, order: .reverse)
    private var allEpisodes: [Episode]

    @Query(filter: #Predicate<Medication> { $0.isActive && $0.medicationTypeRaw == "Acute" },
           sort: \Medication.name)
    private var acuteMedications: [Medication]

    @State private var quickLogDate: Date?

    private var daysSinceLastEpisode: Int {
        guard let lastEpisode = allEpisodes.first else { return -1 }
        return lastEpisode.timestamp.daysBetween(Date())
    }

    private var last30DayEpisodes: [Episode] {
        let cutoff = Date().adding(days: -30)
        return allEpisodes.filter { $0.timestamp >= cutoff }
    }

    private var averagePain: Double {
        let episodes = last30DayEpisodes
        guard !episodes.isEmpty else { return 0 }
        let total = episodes.reduce(0) { $0 + $1.painLevel }
        return Double(total) / Double(episodes.count)
    }

    private var mostCommonSymptom: String {
        var counts: [String: Int] = [:]
        for episode in last30DayEpisodes {
            for symptom in episode.symptoms ?? [] {
                counts[symptom.name, default: 0] += 1
            }
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? "—"
    }

    private var daysWithEpisodes: Int {
        let cutoff = Date().adding(days: -30)
        let days = Set(last30DayEpisodes.filter { $0.timestamp >= cutoff }.map { $0.timestamp.startOfDay })
        return days.count
    }

    private var recentEpisodes: [Episode] {
        Array(allEpisodes.prefix(3))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Streak Badge
                StreakBadgeView(streak: appState.currentStreak)
                    .padding(.horizontal)

                // MARK: - Days Since Last Episode
                daysSinceCard

                // MARK: - Quick Log Button
                Button {
                    appState.showingQuickLog = true
                } label: {
                    Label("Log Episode", systemImage: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AuraTheme.minTouchTarget)
                        .background {
                            RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                                .fill(AuraTheme.accent)
                        }
                }
                .padding(.horizontal)

                // MARK: - Quick-Take Medications
                if !acuteMedications.isEmpty {
                    quickMedicationRow
                        .padding(.horizontal)
                }

                // MARK: - 30-Day Stats
                statsRow
                    .padding(.horizontal)

                // MARK: - Calendar Heatmap
                CalendarHeatmapView(episodes: allEpisodes) { date in
                    quickLogDate = date
                    appState.showingQuickLog = true
                }
                .padding(.horizontal)

                // MARK: - Recent Episodes
                if !recentEpisodes.isEmpty {
                    recentEpisodesSection
                        .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Aura")
        .onAppear {
            appState.recordActivity()
        }
    }

    // MARK: - Days Since Card

    private var daysSinceCard: some View {
        VStack(spacing: 4) {
            if daysSinceLastEpisode < 0 {
                Text("No episodes logged yet")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Start tracking to see patterns")
                    .font(AuraTheme.captionFont)
                    .foregroundStyle(.tertiary)
            } else {
                Text("\(daysSinceLastEpisode)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(AuraTheme.daysSinceColor(daysSinceLastEpisode))
                Text(daysSinceLastEpisode == 1 ? "day since last episode" : "days since last episode")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .auraCard()
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 8) {
            StatsCardView(
                title: "Episodes",
                value: "\(last30DayEpisodes.count)",
                subtitle: "this month"
            )
            StatsCardView(
                title: "Avg Pain",
                value: String(format: "%.1f", averagePain),
                subtitle: "out of 10",
                accentColor: AuraTheme.painColor(for: Int(averagePain.rounded()))
            )
            StatsCardView(
                title: "Days",
                value: "\(daysWithEpisodes)/30",
                subtitle: "with episodes",
                accentColor: daysWithEpisodes > 15 ? AuraTheme.statusAlert : AuraTheme.primary
            )
        }
    }

    // MARK: - Quick-Take Medications

    private var quickMedicationRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Take")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(acuteMedications) { med in
                        Button {
                            let dose = MedicationDose(medication: med, episode: nil)
                            modelContext.insert(dose)
                            HapticsManager.shared.saveSuccess()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "pill.fill")
                                    .font(.system(size: 12))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(med.name)
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(med.dosage)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(AuraTheme.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .auraCard()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Episodes

    private var recentEpisodesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Episodes")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AuraTheme.primary)
                Spacer()
                NavigationLink("See all") {
                    EpisodeListView()
                }
                .font(AuraTheme.captionFont)
            }

            ForEach(recentEpisodes) { episode in
                NavigationLink {
                    EpisodeDetailView(episode: episode)
                } label: {
                    EpisodeRowView(episode: episode)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Episode Row

struct EpisodeRowView: View {
    let episode: Episode

    var body: some View {
        HStack(spacing: 12) {
            PainBadge(level: episode.painLevel)

            VStack(alignment: .leading, spacing: 2) {
                Text(episode.timestamp.shortDateTimeString)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AuraTheme.primary)

                if let symptoms = episode.symptoms, !symptoms.isEmpty {
                    Text(symptoms.prefix(3).map(\.name).joined(separator: ", "))
                        .font(AuraTheme.captionFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .auraCard()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .environment(AppState())
    .modelContainer(for: Episode.self)
}
