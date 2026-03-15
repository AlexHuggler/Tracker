import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \Episode.timestamp, order: .reverse)
    private var allEpisodes: [Episode]

    @Query(filter: #Predicate<Medication> { $0.isActive && $0.medicationTypeRaw == "Acute" },
           sort: \Medication.name)
    private var acuteMedications: [Medication]

    @Query(sort: \DailyLog.date, order: .reverse)
    private var dailyLogs: [DailyLog]

    @State private var quickLogDate: Date?
    @State private var showingDailyLog = false
    @State private var statsPeriod: StatsPeriod = .thirtyDays

    enum StatsPeriod: Int, CaseIterable {
        case sevenDays = 7
        case thirtyDays = 30
        case ninetyDays = 90

        var label: String {
            switch self {
            case .sevenDays: return "7d"
            case .thirtyDays: return "30d"
            case .ninetyDays: return "90d"
            }
        }

        var subtitle: String {
            switch self {
            case .sevenDays: return "this week"
            case .thirtyDays: return "this month"
            case .ninetyDays: return "3 months"
            }
        }
    }

    // 2.2: Track which medication was just quick-taken for visual confirmation
    @State private var justTakenMedID: UUID?

    // 3.2: Dashboard entry animation state
    @State private var appeared = false

    // 4.3: Dose toast with undo
    @State private var lastDose: MedicationDose?
    @State private var lastDoseMedName: String?
    @State private var showingDoseToast = false

    // 4.4: Streak milestone celebration
    @AppStorage("lastCelebratedStreak") private var lastCelebratedStreak = 0
    @State private var showingStreakCelebration = false
    private let milestones = [7, 14, 21, 30, 60, 90, 365]

    private var daysSinceLastEpisode: Int {
        guard let lastEpisode = allEpisodes.first else { return -1 }
        return lastEpisode.timestamp.daysBetween(Date())
    }

    private var periodEpisodes: [Episode] {
        let cutoff = Date().adding(days: -statsPeriod.rawValue)
        return allEpisodes.filter { $0.timestamp >= cutoff }
    }

    private var averagePain: Double {
        let episodes = periodEpisodes
        guard !episodes.isEmpty else { return 0 }
        let total = episodes.reduce(0) { $0 + $1.painLevel }
        return Double(total) / Double(episodes.count)
    }

    private var mostCommonSymptom: String {
        var counts: [String: Int] = [:]
        for episode in periodEpisodes {
            for symptom in episode.symptoms ?? [] {
                counts[symptom.name, default: 0] += 1
            }
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? "—"
    }

    private var daysWithEpisodes: Int {
        Set(periodEpisodes.map { $0.timestamp.startOfDay }).count
    }

    private var recentEpisodes: [Episode] {
        Array(allEpisodes.prefix(3))
    }

    private var hasLoggedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyLogs.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Streak Badge
                StreakBadgeView(streak: appState.currentStreak)
                    .padding(.horizontal)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                // MARK: - Days Since Last Episode
                daysSinceCard
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                // MARK: - Quick Log Button
                Button {
                    appState.showingQuickLog = true
                } label: {
                    Label("Log Episode", systemImage: "plus.circle.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AuraTheme.minTouchTarget)
                        .background {
                            RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                                .fill(AuraTheme.accent)
                        }
                }
                .padding(.horizontal)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                // MARK: - Daily Log Card
                if hasLoggedToday && !dailyLogs.isEmpty {
                    NavigationLink {
                        DailyLogHistoryView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(AuraTheme.accent)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Today logged")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AuraTheme.primary)
                                Text("View daily log history")
                                    .font(AuraTheme.captionFont)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(AuraTheme.cardPadding)
                        .auraCard()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                } else if !hasLoggedToday {
                    Button {
                        showingDailyLog = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "moon.zzz")
                                .font(.title2)
                                .foregroundStyle(AuraTheme.accent)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("How did you sleep?")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AuraTheme.primary)
                                Text("Log sleep, stress & notes to improve pattern detection")
                                    .font(AuraTheme.captionFont)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(AuraTheme.cardPadding)
                        .auraCard()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                }

                // MARK: - Quick-Take Medications
                if !acuteMedications.isEmpty {
                    quickMedicationRow
                        .padding(.horizontal)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                }

                // MARK: - 30-Day Stats
                statsRow
                    .padding(.horizontal)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                // MARK: - Calendar Heatmap
                // 2.1: Pass calendar date context to QuickLog via AppState
                CalendarHeatmapView(episodes: allEpisodes) { date in
                    appState.quickLogDate = date
                    appState.showingQuickLog = true
                }
                .padding(.horizontal)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                // MARK: - Recent Episodes
                if !recentEpisodes.isEmpty {
                    recentEpisodesSection
                        .padding(.horizontal)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 8)
        }
        // 4.3: Dose toast overlay
        .overlay(alignment: .bottom) {
            if showingDoseToast, let medName = lastDoseMedName {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AuraTheme.accent)
                    Text("\(medName) logged")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AuraTheme.primary)
                    Spacer()
                    Button("Undo") {
                        if let dose = lastDose {
                            modelContext.delete(dose)
                            HapticsManager.shared.lightTap()
                        }
                        withAnimation { showingDoseToast = false }
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
        // 4.4: Streak celebration overlay
        .overlay {
            if showingStreakCelebration {
                StreakCelebrationOverlay(
                    streak: appState.currentStreak,
                    reduceMotion: reduceMotion
                ) {
                    withAnimation { showingStreakCelebration = false }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingDailyLog) {
            DailyLogView()
        }
        .navigationTitle("Aura")
        .onAppear {
            appState.recordActivity()
            // 3.2: Staggered dashboard entry animation
            if !reduceMotion {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    appeared = true
                }
            } else {
                appeared = true
            }

            // 4.4: Check for streak milestone celebration
            let streak = appState.currentStreak
            if milestones.contains(streak) && streak != lastCelebratedStreak {
                lastCelebratedStreak = streak
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showingStreakCelebration = true
                    }
                    HapticsManager.shared.saveSuccess()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
                    withAnimation { showingStreakCelebration = false }
                }
            }
        }
    }

    // MARK: - Days Since Card

    private var daysSinceCard: some View {
        VStack(spacing: 4) {
            if daysSinceLastEpisode < 0 {
                Image(systemName: "waveform.path.ecg")
                    .font(.largeTitle)
                    .foregroundStyle(AuraTheme.accent)
                    .padding(.bottom, 4)

                Text("Welcome to Aura")
                    .font(AuraTheme.headingFont)
                    .foregroundStyle(AuraTheme.primary)

                Text("Log your first episode to start discovering patterns.")
                    .font(AuraTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    appState.showingQuickLog = true
                } label: {
                    Text("Log Episode")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background {
                            Capsule().fill(AuraTheme.accent)
                        }
                }
                .padding(.top, 4)
            } else {
                Text("\(daysSinceLastEpisode)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(AuraTheme.daysSinceColor(daysSinceLastEpisode))
                Text(daysSinceLastEpisode == 1 ? "day since last episode" : "days since last episode")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .auraCard()
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityValue(daysSinceLastEpisode < 0 ? "No episodes logged" : "\(daysSinceLastEpisode) days since last episode")
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        VStack(spacing: 8) {
            Picker("Period", selection: $statsPeriod) {
                ForEach(StatsPeriod.allCases, id: \.self) { period in
                    Text(period.label).tag(period)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                StatsCardView(
                    title: "Episodes",
                    value: "\(periodEpisodes.count)",
                    subtitle: statsPeriod.subtitle
                )
                StatsCardView(
                    title: "Avg Pain",
                    value: String(format: "%.1f", averagePain),
                    subtitle: "out of 10",
                    accentColor: AuraTheme.painColor(for: Int(averagePain.rounded()))
                )
                StatsCardView(
                    title: "Days",
                    value: "\(daysWithEpisodes)/\(statsPeriod.rawValue)",
                    subtitle: "with episodes",
                    accentColor: daysWithEpisodes > (statsPeriod.rawValue / 2) ? AuraTheme.statusAlert : AuraTheme.primary
                )
            }
        }
    }

    // MARK: - Quick-Take Medications

    // 2.2: Quick Take with visual confirmation feedback
    private var quickMedicationRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Take")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(acuteMedications) { med in
                        Button {
                            let dose = MedicationDose(medication: med, episode: nil)
                            modelContext.insert(dose)
                            HapticsManager.shared.saveSuccess()
                            // 2.2: Show confirmation state
                            withAnimation(.easeInOut(duration: 0.2)) {
                                justTakenMedID = med.id
                            }
                            // 4.3: Show dose toast with undo
                            lastDose = dose
                            lastDoseMedName = "\(med.name) \(med.dosage)"
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingDoseToast = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if justTakenMedID == med.id {
                                        justTakenMedID = nil
                                    }
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation { showingDoseToast = false }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if justTakenMedID == med.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.footnote)
                                        .foregroundStyle(AuraTheme.accent)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Image(systemName: "pill.fill")
                                        .font(.caption)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(justTakenMedID == med.id ? "Logged!" : med.name)
                                        .font(.footnote.weight(.semibold))
                                    Text(med.dosage)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(justTakenMedID == med.id ? AuraTheme.accent : AuraTheme.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .auraCard()
                        }
                        .accessibilityLabel("\(med.name), \(med.dosage)")
                        .accessibilityHint("Double tap to log a dose of \(med.name)")
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
                    .font(.headline)
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
                    .font(.subheadline.weight(.medium))
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
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .auraCard()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Streak Celebration Overlay (4.4)

struct StreakCelebrationOverlay: View {
    let streak: Int
    let reduceMotion: Bool
    let onDismiss: () -> Void

    @State private var showContent = false

    private var milestoneMessage: String {
        switch streak {
        case 365: return "One full year of tracking!"
        case 90: return "90 days strong!"
        case 60: return "Two months of consistency!"
        case 30: return "One month milestone!"
        case 21: return "Three weeks going!"
        case 14: return "Two weeks in a row!"
        default: return "One week streak!"
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                // Confetti particles using Canvas
                if !reduceMotion {
                    TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                        Canvas { context, size in
                            let time = timeline.date.timeIntervalSinceReferenceDate
                            let colors: [Color] = [AuraTheme.accent, AuraTheme.painMild, AuraTheme.painModerate, AuraTheme.statusGood]
                            for i in 0..<30 {
                                let seed = Double(i) * 1.7
                                let x = (sin(seed * 3.14 + time * 2) * 0.4 + 0.5) * size.width
                                let fallSpeed = (seed.truncatingRemainder(dividingBy: 3) + 1) * 40
                                let y = ((time * fallSpeed + seed * 50).truncatingRemainder(dividingBy: size.height))
                                let color = colors[i % colors.count]
                                context.fill(
                                    Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)),
                                    with: .color(color)
                                )
                            }
                        }
                    }
                    .frame(height: 200)
                    .allowsHitTesting(false)
                }

                VStack(spacing: 12) {
                    Text("\(streak)")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(AuraTheme.accent)

                    Text("Day Streak!")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AuraTheme.primary)

                    Text(milestoneMessage)
                        .font(AuraTheme.bodyFont)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .scaleEffect(showContent ? 1 : 0.7)
                .opacity(showContent ? 1 : 0)
                .padding(32)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                }
            }
            .padding(32)
        }
        .transition(.opacity)
        .onAppear {
            if reduceMotion {
                showContent = true
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showContent = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .environment(AppState())
    .modelContainer(for: Episode.self)
}
