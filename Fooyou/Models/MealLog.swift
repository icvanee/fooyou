import Foundation

struct ConsumedIngredient: Identifiable, Codable {
    var id: UUID = UUID()
    var product: Product
    var amountGrams: Double

    var calories: Double { product.caloriesPer100 / 100 * amountGrams }
    var protein: Double  { product.proteinPer100  / 100 * amountGrams }
    var fat: Double      { product.fatPer100      / 100 * amountGrams }
    var carbs: Double    { product.carbsPer100    / 100 * amountGrams }
}

struct MealLog: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var slot: MealSlot
    var dishName: String
    var photo: Data?
    var ingredients: [ConsumedIngredient]
    var healthKitCorrelationUUID: UUID?

    var totalCalories: Double { ingredients.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double  { ingredients.reduce(0) { $0 + $1.protein  } }
    var totalFat: Double      { ingredients.reduce(0) { $0 + $1.fat      } }
    var totalCarbs: Double    { ingredients.reduce(0) { $0 + $1.carbs    } }
}
