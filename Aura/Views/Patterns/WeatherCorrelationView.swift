import SwiftUI

struct WeatherCorrelationView: View {
    let pattern: WeatherPattern
    let episodes: [Episode]
    let dailyLogs: [DailyLog]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary card
                VStack(spacing: 12) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.largeTitle)
                        .foregroundStyle(AuraTheme.accent)

                    Text(pattern.description)
                        .font(.headline)
                        .foregroundStyle(AuraTheme.primary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 4) {
                        Image(systemName: pattern.confidence.icon)
                        Text(pattern.confidence.rawValue)
                    }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AuraTheme.accent)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background {
                    RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                        .fill(Color(.systemBackground))
                        .shadow(color: AuraTheme.cardShadow, radius: 4, y: 2)
                }

                // Pressure comparison
                VStack(alignment: .leading, spacing: 16) {
                    Text("Barometric Pressure")
                        .font(.headline)
                        .foregroundStyle(AuraTheme.primary)

                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f", pattern.avgPressureDropBeforeEpisode))
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundStyle(AuraTheme.painSevere)
                            Text("hPa")
                                .font(AuraTheme.captionFont)
                                .foregroundStyle(.secondary)
                            Text("Episode days")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Average pressure on episode days: \(String(format: "%.1f", pattern.avgPressureDropBeforeEpisode)) hectopascals")

                        Text("vs")
                            .font(AuraTheme.captionFont)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 4) {
                            Text(String(format: "%.1f", pattern.avgPressureDropNonEpisode))
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundStyle(AuraTheme.painMild)
                            Text("hPa")
                                .font(AuraTheme.captionFont)
                                .foregroundStyle(.secondary)
                            Text("Non-episode days")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Average pressure on non-episode days: \(String(format: "%.1f", pattern.avgPressureDropNonEpisode)) hectopascals")
                    }
                }
                .padding(AuraTheme.cardPadding)
                .background {
                    RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                        .fill(Color(.systemBackground))
                        .shadow(color: AuraTheme.cardShadow, radius: 4, y: 2)
                }

                // Explanation
                VStack(alignment: .leading, spacing: 8) {
                    Text("What this means")
                        .font(.headline)
                        .foregroundStyle(AuraTheme.primary)

                    Text("On days when you had episodes, the average barometric pressure was \(String(format: "%.1f", pattern.avgPressureDropBeforeEpisode)) hPa compared to \(String(format: "%.1f", pattern.avgPressureDropNonEpisode)) hPa on non-episode days. Changes in barometric pressure are a commonly reported migraine trigger.")
                        .font(AuraTheme.bodyFont)
                        .foregroundStyle(.secondary)
                }
                .padding(AuraTheme.cardPadding)
                .background {
                    RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                        .fill(Color(.systemBackground))
                        .shadow(color: AuraTheme.cardShadow, radius: 4, y: 2)
                }

                // Disclaimer
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Correlation is not causation. Weather data is approximate and based on your city-level location.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Weather Correlation")
        .navigationBarTitleDisplayMode(.inline)
    }
}
