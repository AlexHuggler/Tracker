import SwiftUI
import SwiftData

struct ConditionProfileView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ConditionProfile.createdAt)
    private var profiles: [ConditionProfile]

    private var activeProfiles: [ConditionProfile] {
        profiles.filter(\.isActive)
    }

    private var inactiveProfiles: [ConditionProfile] {
        profiles.filter { !$0.isActive }
    }

    private var availableConditions: [ConditionType] {
        let existing = Set(profiles.map(\.conditionTypeRaw))
        return ConditionType.allCases.filter { !existing.contains($0.rawValue) }
    }

    var body: some View {
        List {
            if !activeProfiles.isEmpty {
                Section("Active") {
                    ForEach(activeProfiles) { profile in
                        HStack {
                            Image(systemName: profile.conditionType.icon)
                                .foregroundStyle(AuraTheme.accent)
                                .frame(width: 30)
                            Text(profile.displayName)
                            Spacer()
                            Button {
                                profile.isActive = false
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                        }
                    }
                }
            }

            if !inactiveProfiles.isEmpty {
                Section("Inactive") {
                    ForEach(inactiveProfiles) { profile in
                        HStack {
                            Image(systemName: profile.conditionType.icon)
                                .foregroundStyle(.secondary)
                                .frame(width: 30)
                            Text(profile.displayName)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                profile.isActive = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(AuraTheme.accent)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                        }
                    }
                }
            }

            if !availableConditions.isEmpty {
                Section("Add Condition") {
                    ForEach(availableConditions) { condition in
                        Button {
                            let profile = ConditionProfile(conditionType: condition)
                            modelContext.insert(profile)
                            HapticsManager.shared.selectionChanged()
                        } label: {
                            HStack {
                                Image(systemName: condition.icon)
                                    .foregroundStyle(AuraTheme.accent)
                                    .frame(width: 30)
                                Text(condition.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(AuraTheme.accent)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Conditions")
        .navigationBarTitleDisplayMode(.inline)
    }
}
