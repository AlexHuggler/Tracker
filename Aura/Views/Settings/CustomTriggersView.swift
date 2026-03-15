import SwiftUI
import SwiftData

struct CustomTriggersView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var newTriggerName = ""

    @Query(filter: #Predicate<Trigger> { $0.isCustom && $0.episode == nil })
    private var customTriggers: [Trigger]

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New trigger name", text: $newTriggerName)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        addTrigger()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(AuraTheme.accent)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .disabled(newTriggerName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Add Custom Trigger")
            } footer: {
                Text("Custom triggers appear in the trigger picker when logging episodes.")
            }

            if !customTriggers.isEmpty {
                Section("Your Custom Triggers") {
                    ForEach(customTriggers) { trigger in
                        Text(trigger.name)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(customTriggers[index])
                        }
                    }
                }
            }

            Section("Default Triggers") {
                ForEach(Trigger.defaultTriggers, id: \.self) { name in
                    Text(name)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Custom Triggers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addTrigger() {
        let name = newTriggerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let trigger = Trigger(name: name, isCustom: true)
        modelContext.insert(trigger)
        newTriggerName = ""
        HapticsManager.shared.saveSuccess()
    }
}
