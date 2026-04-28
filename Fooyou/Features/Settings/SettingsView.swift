import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("Doelen") {
                    goalRow(label: "Calorieën", unit: "kcal", value: $appState.dailyCalorieGoal)
                    goalRow(label: "Eiwitten",  unit: "g",    value: $appState.dailyProteinGoal)
                    goalRow(label: "Vetten",    unit: "g",    value: $appState.dailyFatGoal)
                    goalRow(label: "Koolhyd.",  unit: "g",    value: $appState.dailyCarbsGoal)
                }

                Section("Gezondheid") {
                    Toggle("HealthKit synchronisatie", isOn: $appState.healthKitEnabled)
                        .tint(Theme.primary)
                    if appState.healthKitEnabled {
                        Text("Maaltijden worden weggeschreven naar Apple Gezondheid zodat Coach Leo ze kan gebruiken.")
                            .font(.fooyouCaption())
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Over") {
                    LabeledContent("Versie", value: "1.0 (Phase 1)")
                    LabeledContent("Data", value: "Open Food Facts · CloudKit")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Instellingen")
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Klaar") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil)
                    }
                    .fontWeight(.semibold)
                    .tint(Theme.primary)
                }
            }
        }
    }

    @ViewBuilder
    private func goalRow(label: String, unit: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: value, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.numberPad)
                .frame(width: 60)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}
