import Foundation

// Stub — Claude API integration is Phase 1b
struct ClaudeReceiptItem: Codable {
    var name: String
    var quantity: Double
    var unit: String
    var pricePerUnit: Double?

    enum CodingKeys: String, CodingKey {
        case name, quantity, unit
        case pricePerUnit = "price_per_unit"
    }
}

struct ClaudeReceiptResponse: Codable {
    var store: String?
    var date: String?
    var items: [ClaudeReceiptItem]
}

struct ClaudeIngredient: Codable {
    var name: String
    var category: String
    var amount: Double
    var unit: String
    var optional: Bool
    var calories: Double?
}

struct ClaudeRecipeResponse: Codable {
    var dishName: String
    var servings: Int
    var prepTimeMinutes: Int?
    var caloriesPerServing: Double?
    var ingredients: [ClaudeIngredient]

    enum CodingKeys: String, CodingKey {
        case servings
        case dishName         = "dish_name"
        case prepTimeMinutes  = "prep_time_minutes"
        case caloriesPerServing = "calories_per_serving"
        case ingredients
    }
}
