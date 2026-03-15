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
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AuraTheme.primary)
                                Spacer()
                                Text("\(String(format: "%.0f", correlation.percentage))%")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(AuraTheme.painColor(for: Int(correlation.frequency * 10)))
                            }

                            // Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray5))

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AuraTheme.painColor(for: Int(correlation.frequency * 10)))
                                        .frame(width: geometry.size.width * correlation.frequency)
                                }
                            }
                            .frame(height: 12)

                            // Confidence badge
                            HStack(spacing: 4) {
                                Image(systemName: correlation.confidence.icon)
                                    .font(.caption2)
                                Text(correlation.confidence.rawValue)
                                    .font(.caption.weight(.medium))
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
                    .accessibilityLabel("\(correlation.triggerName), \(String(format: "%.0f", correlation.percentage)) percent")
                    .accessibilityValue("\(correlation.episodesWithTrigger) of \(correlation.totalEpisodes) episodes")
                    .accessibilityHint("Double tap to \(selectedCorrelation?.id == correlation.id ? "collapse" : "expand") details")
                }

                // Disclaimer
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Frequency is not causation. Discuss patterns with your doctor.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                Spacer(minLength: 20)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Trigger Frequency")
        .navigationBarTitleDisplayMode(.inline)
    }
}
