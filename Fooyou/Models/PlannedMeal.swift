import Foundation

struct PlannedIngredient: Identifiable, Codable {
    var id: UUID = UUID()
    var product: Product?
    var ingredientName: String
    var category: String
    var amount: Double
    var unit: String
    var calories: Double
}

struct PlannedMeal: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var slot: MealSlot
    var dishName: String
    var ingredients: [PlannedIngredient]
    var sourceRecipeURL: URL?
    var photo: Data?
    var servings: Int
    var servingsToEat: Int
    var isEaten: Bool = false
    var eatenAt: Date?

    var totalCalories: Double {
        guard servings > 0 else { return 0 }
        let scale = Double(servingsToEat) / Double(servings)
        return ingredients.reduce(0) { $0 + $1.calories } * scale
    }
}
