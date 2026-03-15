import SwiftUI
import SwiftData

struct CustomSymptomsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var newSymptomName = ""

    @Query(filter: #Predicate<Symptom> { $0.isCustom && $0.episode == nil })
    private var customSymptoms: [Symptom]

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New symptom name", text: $newSymptomName)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        addSymptom()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(AuraTheme.accent)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .disabled(newSymptomName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Add Custom Symptom")
            } footer: {
                Text("Custom symptoms appear in the symptom picker when logging episodes.")
            }

            if !customSymptoms.isEmpty {
                Section("Your Custom Symptoms") {
                    ForEach(customSymptoms) { symptom in
                        Text(symptom.name)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(customSymptoms[index])
                        }
                    }
                }
            }

            Section("Default Symptoms") {
                ForEach(Symptom.allDefaultSymptoms, id: \.self) { name in
                    Text(name)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Custom Symptoms")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addSymptom() {
        let name = newSymptomName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let symptom = Symptom(name: name, isCustom: true)
        modelContext.insert(symptom)
        newSymptomName = ""
        HapticsManager.shared.saveSuccess()
    }
}
