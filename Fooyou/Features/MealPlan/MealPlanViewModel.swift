import Foundation
import CoreData
import Combine

@MainActor
final class MealPlanViewModel: ObservableObject {
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var plannedMeals: [PlannedMeal] = []
    @Published var mealLogs: [MealLog] = []

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetch()
    }

    func fetch() {
        fetchPlanned()
        fetchLogs()
    }

    func meal(for slot: MealSlot) -> PlannedMeal? {
        plannedMeals.first { $0.slot == slot && Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    func log(for slot: MealSlot) -> MealLog? {
        mealLogs.first { $0.slot == slot && Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var totalCaloriesToday: Double {
        mealLogs
            .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .reduce(0) { $0 + $1.totalCalories }
    }

    func markAsEaten(_ meal: PlannedMeal, at time: Date = Date()) {
        let request = CDPlannedMeal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", meal.id as CVarArg)
        guard let cd = try? context.fetch(request).first else { return }
        cd.isEaten = true
        cd.eatenAt = time
        try? context.save()
        fetch()
    }

    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        fetch()
    }

    func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        fetch()
    }

    private func fetchPlanned() {
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end   = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let req = CDPlannedMeal.fetchRequest()
        req.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as CVarArg, end as CVarArg)
        req.sortDescriptors = [NSSortDescriptor(key: "slot", ascending: true)]
        let cds = (try? context.fetch(req)) ?? []
        plannedMeals = cds.compactMap { PlannedMeal(from: $0) }
    }

    private func fetchLogs() {
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end   = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let req = CDMealLog.fetchRequest()
        req.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as CVarArg, end as CVarArg)
        let cds = (try? context.fetch(req)) ?? []
        mealLogs = cds.compactMap { MealLog(from: $0) }
    }
}

// MARK: - PlannedMeal CoreData mapping

extension PlannedMeal {
    init?(from cd: CDPlannedMeal) {
        guard let id = cd.id, let slot = MealSlot(rawValue: cd.slot ?? "") else { return nil }
        self.id = id
        self.date = cd.date ?? Date()
        self.slot = slot
        self.dishName = cd.dishName ?? ""
        self.servings = Int(cd.servings)
        self.servingsToEat = Int(cd.servingsToEat)
        self.isEaten = cd.isEaten
        self.eatenAt = cd.eatenAt
        self.photo = cd.photo
        self.sourceRecipeURL = cd.sourceRecipeURLString.flatMap { URL(string: $0) }
        self.ingredients = (cd.ingredients as? Set<CDPlannedIngredient>)?
            .compactMap { PlannedIngredient(from: $0) } ?? []
    }
}

extension PlannedIngredient {
    init?(from cd: CDPlannedIngredient) {
        guard let id = cd.id else { return nil }
        self.id = id
        self.ingredientName = cd.ingredientName ?? ""
        self.category = cd.category ?? ""
        self.amount = cd.amount
        self.unit = cd.unit ?? "gram"
        self.calories = cd.calories
        self.product = cd.product.flatMap { Product(from: $0) }
    }
}

// MARK: - MealLog CoreData mapping

extension MealLog {
    init?(from cd: CDMealLog) {
        guard let id = cd.id, let slot = MealSlot(rawValue: cd.slot ?? "") else { return nil }
        self.id = id
        self.date = cd.date ?? Date()
        self.slot = slot
        self.dishName = cd.dishName ?? ""
        self.photo = cd.photo
        self.healthKitCorrelationUUID = cd.healthKitCorrelationUUID
        self.ingredients = (cd.ingredients as? Set<CDConsumedIngredient>)?
            .compactMap { ConsumedIngredient(from: $0) } ?? []
    }
}

extension ConsumedIngredient {
    init?(from cd: CDConsumedIngredient) {
        guard let id = cd.id,
              let cdProduct = cd.product,
              let product = Product(from: cdProduct) else { return nil }
        self.id = id
        self.product = product
        self.amountGrams = cd.amountGrams
    }
}
