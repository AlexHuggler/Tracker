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
                                .font(.system(size: 18, weight: .semibold))
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
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(AuraTheme.accent)
                                    Text("avg minutes\nto relief")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }

                            if let reduction = med.avgPainReduction {
                                VStack(spacing: 2) {
                                    Text(String(format: "%.1f", reduction))
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(AuraTheme.painMild)
                                    Text("avg pain\nreduction")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }

                            VStack(spacing: 2) {
                                Text("\(med.timesUsed)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(AuraTheme.primary)
                                Text("times\nused")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
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
        .navigationTitle("Medication Effectiveness")
        .navigationBarTitleDisplayMode(.inline)
    }
}
