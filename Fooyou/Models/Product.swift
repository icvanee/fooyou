import Foundation

enum FoodUnit: String, Codable, CaseIterable {
    case gram   = "gram"
    case ml     = "ml"
    case stuks  = "stuks"
}

enum StorageLocation: String, Codable, CaseIterable {
    case fridge  = "Koelkast"
    case freezer = "Vriezer"
    case pantry  = "Kast"
}

struct Product: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var barcode: String?
    var name: String
    var brand: String
    var imageURL: URL?
    var caloriesPer100: Double
    var proteinPer100: Double
    var fatPer100: Double
    var carbsPer100: Double
    var packSizeGrams: Double
    var unit: FoodUnit
    var ingredientCategories: [String]
    var usageCount: Int
    var lastUsed: Date?
    var lowStockThreshold: Double
    var defaultPortionSize: Double

    static func empty() -> Product {
        Product(
            name: "",
            brand: "",
            caloriesPer100: 0,
            proteinPer100: 0,
            fatPer100: 0,
            carbsPer100: 0,
            packSizeGrams: 100,
            unit: .gram,
            ingredientCategories: [],
            usageCount: 0,
            lowStockThreshold: 100,
            defaultPortionSize: 100
        )
    }
}
