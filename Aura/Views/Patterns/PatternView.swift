import SwiftUI
import SwiftData

struct PatternView: View {
    @Environment(AppState.self) private var appState

    @Query(sort: \Episode.timestamp, order: .reverse)
    private var episodes: [Episode]

    @Query private var dailyLogs: [DailyLog]
    @Query private var medications: [Medication]

    @State private var triggerCorrelations: [TriggerCorrelation] = []
    @State private var temporalPatterns: [TemporalPattern] = []
    @State private var weatherPatterns: [WeatherPattern] = []
    @State private var medicationEffectiveness: [MedicationEffectiveness] = []
    @State private var isAnalyzing = false

    private let engine = PatternEngine()

    var body: some View {
        Group {
            if !appState.isPremium {
                premiumGate
            } else if episodes.count < PatternEngine.preliminaryEpisodes {
                insufficientData
            } else {
                patternsList
            }
        }
        .navigationTitle("Patterns")
        .task {
            if appState.isPremium && episodes.count >= PatternEngine.preliminaryEpisodes {
                await runAnalysis()
            }
        }
    }

    private var premiumGate: some View {
        PremiumGateView(
            feature: "Pattern Analysis",
            icon: "waveform.path.ecg",
            description: "Unlock pattern detection to discover what triggers your episodes."
        )
    }

    // 1.4: Pattern progress indicator with visual progress ring
    private var insufficientData: some View {
        VStack(spacing: 24) {
            Spacer()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(AuraTheme.accent.opacity(0.15), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: CGFloat(episodes.count) / CGFloat(PatternEngine.minimumEpisodes))
                    .stroke(AuraTheme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(episodes.count)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AuraTheme.accent)
                    Text("of \(PatternEngine.minimumEpisodes)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 8) {
                Text("Building Your Patterns")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(AuraTheme.primary)

                let remaining = PatternEngine.preliminaryEpisodes - episodes.count
                if remaining > 0 {
                    Text("Log \(remaining) more episode\(remaining == 1 ? "" : "s") to start seeing early patterns.")
                        .font(AuraTheme.bodyFont)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    let fullRemaining = PatternEngine.minimumEpisodes - episodes.count
                    Text("Early patterns unlocked! Log \(fullRemaining) more for full analysis.")
                        .font(AuraTheme.bodyFont)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button {
                appState.showingQuickLog = true
            } label: {
                Label("Log Episode", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background {
                        Capsule()
                            .fill(AuraTheme.accent)
                    }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    private var patternsList: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Disclaimer
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(AuraTheme.accent)
                    Text("Correlation is not causation. Discuss patterns with your doctor.")
                        .font(AuraTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AuraTheme.accent.opacity(0.08))
                }
                .padding(.horizontal)

                // Trigger correlations
                if !triggerCorrelations.isEmpty {
                    NavigationLink {
                        TriggerCorrelationView(correlations: triggerCorrelations, totalEpisodes: episodes.count)
                    } label: {
                        patternCard(
                            icon: "exclamationmark.triangle.fill",
                            title: "Trigger Patterns",
                            subtitle: "\(triggerCorrelations.count) potential triggers identified",
                            confidence: triggerCorrelations.first?.confidence ?? .likely
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Temporal patterns
                ForEach(temporalPatterns) { pattern in
                    patternCard(
                        icon: "clock.fill",
                        title: pattern.description,
                        subtitle: pattern.detail,
                        confidence: pattern.confidence
                    )
                }

                // Weather patterns
                ForEach(weatherPatterns) { pattern in
                    NavigationLink {
                        WeatherCorrelationView(pattern: pattern, episodes: episodes, dailyLogs: dailyLogs)
                    } label: {
                        patternCard(
                            icon: "cloud.sun.fill",
                            title: pattern.description,
                            subtitle: "Avg pressure on episode days: \(String(format: "%.1f", pattern.avgPressureDropBeforeEpisode)) hPa vs \(String(format: "%.1f", pattern.avgPressureDropNonEpisode)) hPa on others",
                            confidence: pattern.confidence
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Medication effectiveness
                if !medicationEffectiveness.isEmpty {
                    NavigationLink {
                        MedicationEffectivenessView(effectiveness: medicationEffectiveness)
                    } label: {
                        patternCard(
                            icon: "pill.fill",
                            title: "Medication Effectiveness",
                            subtitle: "\(medicationEffectiveness.count) medications analyzed",
                            confidence: .likely
                        )
                    }
                    .buttonStyle(.plain)
                }

                if triggerCorrelations.isEmpty && temporalPatterns.isEmpty && weatherPatterns.isEmpty && medicationEffectiveness.isEmpty {
                    ContentUnavailableView {
                        Label("No Patterns Yet", systemImage: "magnifyingglass")
                    } description: {
                        Text("Keep logging episodes. Patterns will appear as more data accumulates.")
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .overlay {
            if isAnalyzing {
                ProgressView("Analyzing patterns...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func patternCard(icon: String, title: String, subtitle: String, confidence: ConfidenceLevel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(AuraTheme.accent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AuraTheme.primary)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(AuraTheme.captionFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            VStack(spacing: 2) {
                Image(systemName: confidence.icon)
                    .font(.system(size: 14))
                Text(confidence.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(AuraTheme.accent)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(AuraTheme.cardPadding)
        .auraCard()
        .padding(.horizontal)
    }

    @MainActor
    private func runAnalysis() async {
        // 3.7: Use cached results if episode count hasn't changed
        if await engine.isCacheValid(episodeCount: episodes.count) {
            triggerCorrelations = await engine.cachedTriggerCorrelations ?? []
            temporalPatterns = await engine.cachedTemporalPatterns ?? []
            weatherPatterns = await engine.cachedWeatherPatterns ?? []
            medicationEffectiveness = await engine.cachedMedicationEffectiveness ?? []
            return
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        let triggers = await engine.analyzeTriggerCorrelations(episodes: episodes)
        let temporal = await engine.analyzeTemporalPatterns(episodes: episodes)
        let weather = await engine.analyzeWeatherCorrelation(episodes: episodes, dailyLogs: dailyLogs)
        let medication = await engine.analyzeMedicationEffectiveness(
            medications: medications, episodes: episodes
        )

        triggerCorrelations = triggers
        temporalPatterns = temporal
        weatherPatterns = weather
        medicationEffectiveness = medication

        // Cache the results
        await engine.cacheResults(
            episodeCount: episodes.count,
            triggers: triggers,
            temporal: temporal,
            weather: weather,
            medication: medication
        )
    }
}
