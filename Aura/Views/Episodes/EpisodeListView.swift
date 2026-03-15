import SwiftUI
import SwiftData

struct EpisodeListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Episode.timestamp, order: .reverse)
    private var allEpisodes: [Episode]

    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var painFilter: PainFilter = .all
    @State private var sortOption: SortOption = .dateDesc
    @State private var pendingDeletion: Episode?
    @State private var showingUndoToast = false

    enum SortOption: String, CaseIterable {
        case dateDesc = "Newest"
        case dateAsc = "Oldest"
        case painDesc = "Highest Pain"
        case painAsc = "Lowest Pain"
    }

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

        // Apply search text (debounced)
        if !debouncedSearchText.isEmpty {
            let query = debouncedSearchText.lowercased()
            episodes = episodes.filter { episode in
                if episode.notes?.lowercased().contains(query) == true { return true }
                if episode.symptoms?.contains(where: { $0.name.lowercased().contains(query) }) == true { return true }
                if episode.triggers?.contains(where: { $0.name.lowercased().contains(query) }) == true { return true }
                return false
            }
        }

        // Apply sort
        switch sortOption {
        case .dateDesc: episodes.sort { $0.timestamp > $1.timestamp }
        case .dateAsc: episodes.sort { $0.timestamp < $1.timestamp }
        case .painDesc: episodes.sort { $0.painLevel > $1.painLevel }
        case .painAsc: episodes.sort { $0.painLevel < $1.painLevel }
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
                .refreshable {
                    try? await Task.sleep(for: .milliseconds(300))
                    HapticsManager.shared.lightTap()
                }
            }
        }
        // 2.6: Show free tier limit banner
        .safeAreaInset(edge: .top) {
            if !appState.isPremium && !allEpisodes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("Showing last \(AppState.freeHistoryDays) days")
                        .font(.footnote.weight(.medium))
                    Spacer()
                    Button {
                        appState.showingPaywall = true
                    } label: {
                        Text("Unlock all")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AuraTheme.accent)
                    }
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
        .overlay(alignment: .bottom) {
            if showingUndoToast {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(AuraTheme.statusAlert)
                    Text("Episode deleted")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AuraTheme.primary)
                    Spacer()
                    Button("Undo") {
                        pendingDeletion = nil
                        withAnimation { showingUndoToast = false }
                        HapticsManager.shared.lightTap()
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AuraTheme.accent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .searchable(text: $searchText, prompt: "Search symptoms, triggers, notes...")
        .onChange(of: searchText) { _, newValue in
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                if !Task.isCancelled {
                    debouncedSearchText = newValue
                }
            }
        }
        .navigationTitle("Episodes")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Pain Level", selection: $painFilter) {
                        ForEach(PainFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        if painFilter != .all {
                            Text(painFilter.rawValue)
                                .font(.footnote.weight(.medium))
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
        guard let index = offsets.first else { return }
        let episode = episodes[index]

        // Soft delete: hide from list, show undo toast
        pendingDeletion = episode
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showingUndoToast = true
        }
        HapticsManager.shared.error()

        // Auto-delete after 3 seconds unless undone
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if pendingDeletion?.id == episode.id {
                modelContext.delete(episode)
                withAnimation { showingUndoToast = false }
                pendingDeletion = nil
            }
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
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 4) {
                    Text(episode.painCategory.rawValue)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AuraTheme.painColor(for: episode.painLevel))

                    if let duration = episode.formattedDuration {
                        Text("· \(duration)")
                            .font(AuraTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                }

                if let symptoms = episode.symptoms, !symptoms.isEmpty {
                    Text(symptoms.prefix(3).map(\.name).joined(separator: ", "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
