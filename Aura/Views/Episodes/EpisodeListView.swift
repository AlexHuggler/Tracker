import SwiftUI
import SwiftData

struct EpisodeListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Episode.timestamp, order: .reverse)
    private var allEpisodes: [Episode]

    private var visibleEpisodes: [Episode] {
        if appState.isPremium {
            return allEpisodes
        }
        let cutoff = Date().adding(days: -AppState.freeHistoryDays)
        return allEpisodes.filter { $0.timestamp >= cutoff }
    }

    private var groupedEpisodes: [(String, [Episode])] {
        let grouped = Dictionary(grouping: visibleEpisodes) { episode in
            episode.timestamp.monthYearString
        }
        return grouped.sorted { lhs, rhs in
            guard let lhsDate = lhs.value.first?.timestamp,
                  let rhsDate = rhs.value.first?.timestamp else { return false }
            return lhsDate > rhsDate
        }
    }

    var body: some View {
        Group {
            if allEpisodes.isEmpty {
                ContentUnavailableView {
                    Label("No Episodes", systemImage: "list.bullet.clipboard")
                } description: {
                    Text("Log your first episode to start tracking.")
                } actions: {
                    Button("Log Episode") {
                        appState.showingQuickLog = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AuraTheme.accent)
                }
            } else {
                List {
                    ForEach(groupedEpisodes, id: \.0) { month, episodes in
                        Section(month) {
                            ForEach(episodes) { episode in
                                NavigationLink {
                                    EpisodeDetailView(episode: episode)
                                } label: {
                                    EpisodeListRowView(episode: episode)
                                }
                            }
                            .onDelete { offsets in
                                deleteEpisodes(episodes: episodes, at: offsets)
                            }
                        }
                    }

                    if !appState.isPremium && allEpisodes.count > visibleEpisodes.count {
                        Section {
                            Button {
                                appState.showingPaywall = true
                            } label: {
                                HStack {
                                    Image(systemName: "lock.fill")
                                    Text("Unlock full history (\(allEpisodes.count - visibleEpisodes.count) older episodes)")
                                }
                                .foregroundStyle(AuraTheme.accent)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Episodes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.showingQuickLog = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func deleteEpisodes(episodes: [Episode], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(episodes[index])
        }
    }
}

struct EpisodeListRowView: View {
    let episode: Episode

    var body: some View {
        HStack(spacing: 12) {
            PainBadge(level: episode.painLevel)

            VStack(alignment: .leading, spacing: 2) {
                Text(episode.timestamp.shortDateTimeString)
                    .font(.system(size: 15, weight: .medium))

                HStack(spacing: 4) {
                    Text(episode.painCategory.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AuraTheme.painColor(for: episode.painLevel))

                    if let duration = episode.formattedDuration {
                        Text("· \(duration)")
                            .font(AuraTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                }

                if let symptoms = episode.symptoms, !symptoms.isEmpty {
                    Text(symptoms.prefix(3).map(\.name).joined(separator: ", "))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
