import SwiftUI

struct MedicationEffectivenessView: View {
    let effectiveness: [MedicationEffectiveness]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(effectiveness) { med in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(med.medicationName)
                                .font(.headline)
                                .foregroundStyle(AuraTheme.primary)
                            Spacer()
                            Text("Used \(med.timesUsed)x")
                                .font(AuraTheme.captionFont)
                                .foregroundStyle(.secondary)
                        }

                        // Friendly description
                        Text(med.friendlyDescription)
                            .font(AuraTheme.bodyFont)
                            .foregroundStyle(.secondary)

                        // Stats
                        HStack(spacing: 20) {
                            if let relief = med.avgReliefMinutes {
                                VStack(spacing: 2) {
                                    Text("\(Int(relief))")
                                        .font(.system(.title2, design: .rounded, weight: .bold))
                                        .foregroundStyle(AuraTheme.accent)
                                    Text("avg minutes\nto relief")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Average \(Int(relief)) minutes to relief")
                            }

                            if let reduction = med.avgPainReduction {
                                VStack(spacing: 2) {
                                    Text(String(format: "%.1f", reduction))
                                        .font(.system(.title2, design: .rounded, weight: .bold))
                                        .foregroundStyle(AuraTheme.painMild)
                                    Text("avg pain\nreduction")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Average pain reduction: \(String(format: "%.1f", reduction)) points")
                            }

                            VStack(spacing: 2) {
                                Text("\(med.timesUsed)")
                                    .font(.system(.title2, design: .rounded, weight: .bold))
                                    .foregroundStyle(AuraTheme.primary)
                                Text("times\nused")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Used \(med.timesUsed) times")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(AuraTheme.cardPadding)
                    .background {
                        RoundedRectangle(cornerRadius: AuraTheme.cornerRadius)
                            .fill(Color(.systemBackground))
                            .shadow(color: AuraTheme.cardShadow, radius: 4, y: 2)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Effectiveness data is based on your logged episodes. Discuss medication changes with your doctor.")
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
        .navigationTitle("Medication Effectiveness")
        .navigationBarTitleDisplayMode(.inline)
    }
}
