import SwiftUI

struct MealPlanView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm: MealPlanViewModel
    @State private var slotToAdd: MealSlot? = nil
    @State private var mealToEat: PlannedMeal? = nil

    init() {
        _vm = StateObject(wrappedValue: MealPlanViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    macroSummary
                        .padding(.horizontal)

                    ForEach(MealSlot.allCases) { slot in
                        MealSlotCard(
                            slot: slot,
                            plannedMeal: vm.meal(for: slot),
                            mealLog: vm.log(for: slot),
                            onAdd: { slotToAdd = slot },
                            onMarkEaten: { meal in mealToEat = meal }
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                }
                .padding(.top, 8)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { dateNavigation }
        }
        .sheet(item: $mealToEat) { meal in
            MarkAsEatenSheet(meal: meal) { time in
                vm.markAsEaten(meal, at: time)
                mealToEat = nil
            }
        }
    }

    // MARK: - Macro summary bar

    private var macroSummary: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(Int(vm.totalCaloriesToday)) / \(Int(appState.dailyCalorieGoal)) kcal")
                    .font(.fooyouTitle())
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.primary)
                        .frame(width: geo.size.width * min(vm.totalCaloriesToday / max(appState.dailyCalorieGoal, 1), 1))
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    // MARK: - Date nav

    private var dateTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "EEEE d MMMM"
        let s = f.string(from: vm.selectedDate)
        if Calendar.current.isDateInToday(vm.selectedDate) { return "Vandaag" }
        if Calendar.current.isDateInYesterday(vm.selectedDate) { return "Gisteren" }
        if Calendar.current.isDateInTomorrow(vm.selectedDate) { return "Morgen" }
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    @ToolbarContentBuilder
    private var dateNavigation: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { vm.goToPreviousDay() } label: {
                Image(systemName: "chevron.left")
            }.tint(Theme.primary)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { vm.goToNextDay() } label: {
                Image(systemName: "chevron.right")
            }.tint(Theme.primary)
        }
    }
}

// MARK: - Mark-as-eaten sheet

struct MarkAsEatenSheet: View {
    let meal: PlannedMeal
    let onConfirm: (Date) -> Void

    @State private var eatenAt: Date = Date()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Tijdstip") {
                    DatePicker("Gegeten om", selection: $eatenAt, displayedComponents: [.hourAndMinute])
                }
                Section {
                    Text(meal.dishName)
                        .font(.fooyouHeadline())
                    Text("~\(Int(meal.totalCalories)) kcal")
                        .font(.fooyouCaption())
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Markeer als gegeten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bevestig") {
                        onConfirm(eatenAt)
                    }
                    .tint(Theme.primary)
                }
            }
        }
    }
}
