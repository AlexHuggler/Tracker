import SwiftUI

struct TriggerCorrelationView: View {
    let correlations: [TriggerCorrelation]
    let totalEpisodes: Int

    @State private var selectedCorrelation: TriggerCorrelation?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary
                Text("Based on \(totalEpisodes) logged episodes")
                    .font(AuraTheme.captionFont)
                    .foregroundStyle(.secondary)

                // Bar chart
                ForEach(correlations) { correlation in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedCorrelation?.id == correlation.id {
                                selectedCorrelation = nil
                            } else {
                                selectedCorrelation = correlation
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(correlation.triggerName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AuraTheme.primary)
                                Spacer()
                                Text("\(String(format: "%.0f", correlation.percentage))%")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(AuraTheme.painColor(for: Int(correlation.correlationStrength * 10)))
                            }

                            // Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray5))

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AuraTheme.painColor(for: Int(correlation.correlationStrength * 10)))
                                        .frame(width: geometry.size.width * correlation.correlationStrength)
                                }
                            }
                            .frame(height: 12)

                            // Confidence badge
                            HStack(spacing: 4) {
                                Image(systemName: correlation.confidence.icon)
                                    .font(.system(size: 11))
                                Text(correlation.confidence.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(.secondary)

                            // Detail if selected
                            if selectedCorrelation?.id == correlation.id {
                                Text("\(correlation.triggerName) was logged as a trigger in \(correlation.episodesWithTrigger) of your \(correlation.totalEpisodes) episodes (\(String(format: "%.0f", correlation.percentage))%).")
                                    .font(AuraTheme.captionFont)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(AuraTheme.cardPadding)
                        .background {
                            RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                                .fill(Color(.systemBackground))
                                .shadow(color: AuraTheme.cardShadow, radius: 4, y: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Disclaimer
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Correlation is not causation. Discuss patterns with your doctor.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                Spacer(minLength: 20)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Trigger Correlations")
        .navigationBarTitleDisplayMode(.inline)
    }
}
