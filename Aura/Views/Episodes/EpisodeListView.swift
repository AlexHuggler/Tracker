import SwiftUI
import SwiftData

struct EpisodeListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Episode.timestamp, order: .reverse)
    private var allEpisodes: [Episode]

    @State private var searchText = ""
    @State private var painFilter: PainFilter = .all

    enum PainFilter: String, CaseIterable {
        case all = "All"
        case mild = "Mild"
        case moderate = "Moderate"
        case severe = "Severe"
        case extreme = "Extreme"
    }

    private var visibleEpisodes: [Episode] {
        var episodes: [Episode]
        if appState.isPremium {
            episodes = allEpisodes
        } else {
            let cutoff = Date().adding(days: -AppState.freeHistoryDays)
            episodes = allEpisodes.filter { $0.timestamp >= cutoff }
        }

        // Apply pain filter
        switch painFilter {
        case .all: break
        case .mild: episodes = episodes.filter { $0.painLevel <= 3 }
        case .moderate: episodes = episodes.filter { (4...6).contains($0.painLevel) }
        case .severe: episodes = episodes.filter { (7...8).contains($0.painLevel) }
        case .extreme: episodes = episodes.filter { $0.painLevel >= 9 }
        }

        // Apply search text
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            episodes = episodes.filter { episode in
                if episode.notes?.lowercased().contains(query) == true { return true }
                if episode.symptoms?.contains(where: { $0.name.lowercased().contains(query) }) == true { return true }
                if episode.triggers?.contains(where: { $0.name.lowercased().contains(query) }) == true { return true }
                return false
            }
        }

        return episodes
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
        // 2.6: Show free tier limit banner
        .safeAreaInset(edge: .top) {
            if !appState.isPremium && !allEpisodes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("Showing last \(AppState.freeHistoryDays) days")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Button {
                        appState.showingPaywall = true
                    } label: {
                        Text("Unlock all")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AuraTheme.accent)
                    }
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
        .searchable(text: $searchText, prompt: "Search symptoms, triggers, notes...")
        .navigationTitle("Episodes")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Pain Level", selection: $painFilter) {
                        ForEach(PainFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        if painFilter != .all {
                            Text(painFilter.rawValue)
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                }
            }
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
        HapticsManager.shared.error()
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
