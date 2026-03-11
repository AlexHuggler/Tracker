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
            } else if episodes.count < PatternEngine.minimumEpisodes {
                insufficientData
            } else {
                patternsList
            }
        }
        .navigationTitle("Patterns")
        .task {
            if appState.isPremium && episodes.count >= PatternEngine.minimumEpisodes {
                await runAnalysis()
            }
        }
    }

    private var premiumGate: some View {
        ContentUnavailableView {
            Label("Pattern Analysis", systemImage: "waveform.path.ecg")
        } description: {
            Text("Unlock pattern detection to discover what triggers your episodes.")
        } actions: {
            Button("Unlock Patterns") {
                appState.showingPaywall = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AuraTheme.accent)
        }
    }

    private var insufficientData: some View {
        ContentUnavailableView {
            Label("Not Enough Data", systemImage: "chart.bar.doc.horizontal")
        } description: {
            Text("Log at least \(PatternEngine.minimumEpisodes) episodes to start seeing patterns. You have \(episodes.count) so far.")
        }
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
        .background {
            RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: AuraTheme.cardShadow, radius: 4, y: 2)
        }
        .padding(.horizontal)
    }

    @MainActor
    private func runAnalysis() async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        triggerCorrelations = await engine.analyzeTriggerCorrelations(episodes: episodes)
        temporalPatterns = await engine.analyzeTemporalPatterns(episodes: episodes)
        weatherPatterns = await engine.analyzeWeatherCorrelation(episodes: episodes, dailyLogs: dailyLogs)
        medicationEffectiveness = await engine.analyzeMedicationEffectiveness(
            medications: medications, episodes: episodes
        )
    }
}
