import Foundation
import CoreData
import Combine

@MainActor
final class PantryViewModel: ObservableObject {
    @Published var items: [PantryItem] = []
    @Published var selectedLocation: StorageLocation? = nil
    @Published var searchText: String = ""

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetch()
    }

    var filteredItems: [PantryItem] {
        items.filter { item in
            let matchesLocation = selectedLocation == nil || item.location == selectedLocation
            let matchesSearch = searchText.isEmpty ||
                item.product.name.localizedCaseInsensitiveContains(searchText) ||
                item.product.brand.localizedCaseInsensitiveContains(searchText)
            return matchesLocation && matchesSearch
        }
        .sorted { $0.product.name < $1.product.name }
    }

    func fetch() {
        let request = CDPantryItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "product.name", ascending: true)]
        do {
            let cdItems = try context.fetch(request)
            items = cdItems.compactMap { PantryItem(from: $0) }
        } catch {
            print("PantryViewModel fetch error: \(error)")
        }
    }

    func add(_ item: PantryItem) {
        let cd = CDPantryItem(context: context)
        cd.populate(from: item, context: context)
        save()
        fetch()
    }

    func delete(_ item: PantryItem) {
        let request = CDPantryItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        if let cd = try? context.fetch(request).first {
            context.delete(cd)
            save()
            fetch()
        }
    }

    func updateQuantity(for item: PantryItem, delta: Double) {
        let request = CDPantryItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        if let cd = try? context.fetch(request).first {
            cd.quantity = max(0, cd.quantity + delta)
            save()
            fetch()
        }
    }

    private func save() {
        guard context.hasChanges else { return }
        try? context.save()
    }
}

// MARK: - CoreData ↔ Model mapping

extension PantryItem {
    init?(from cd: CDPantryItem) {
        guard let cdProduct = cd.product,
              let product = Product(from: cdProduct),
              let id = cd.id else { return nil }
        self.id = id
        self.product = product
        self.quantity = cd.quantity
        self.expiryDate = cd.expiryDate
        self.purchasedDate = cd.purchasedDate ?? Date()
        self.location = StorageLocation(rawValue: cd.location ?? "Kast") ?? .pantry
    }
}

extension CDPantryItem {
    func populate(from item: PantryItem, context: NSManagedObjectContext) {
        id = item.id
        quantity = item.quantity
        expiryDate = item.expiryDate
        purchasedDate = item.purchasedDate
        location = item.location.rawValue

        let productReq = CDProduct.fetchRequest()
        productReq.predicate = NSPredicate(format: "id == %@", item.product.id as CVarArg)
        if let existing = try? context.fetch(productReq).first {
            product = existing
        } else {
            let cdProd = CDProduct(context: context)
            cdProd.populate(from: item.product)
            product = cdProd
        }
    }
}

extension Product {
    init?(from cd: CDProduct) {
        guard let id = cd.id else { return nil }
        self.id = id
        self.name = cd.name ?? ""
        self.brand = cd.brand ?? ""
        self.barcode = cd.barcode
        self.imageURL = cd.imageURLString.flatMap { URL(string: $0) }
        self.caloriesPer100 = cd.caloriesPer100
        self.proteinPer100 = cd.proteinPer100
        self.fatPer100 = cd.fatPer100
        self.carbsPer100 = cd.carbsPer100
        self.packSizeGrams = cd.packSizeGrams
        self.unit = FoodUnit(rawValue: cd.unit ?? "gram") ?? .gram
        self.ingredientCategories = cd.ingredientCategories
            .flatMap { try? JSONDecoder().decode([String].self, from: Data($0.utf8)) } ?? []
        self.usageCount = Int(cd.usageCount)
        self.lastUsed = cd.lastUsed
        self.lowStockThreshold = cd.lowStockThreshold
        self.defaultPortionSize = cd.defaultPortionSize
    }
}

extension CDProduct {
    func populate(from product: Product) {
        id = product.id
        name = product.name
        brand = product.brand
        barcode = product.barcode
        imageURLString = product.imageURL?.absoluteString
        caloriesPer100 = product.caloriesPer100
        proteinPer100 = product.proteinPer100
        fatPer100 = product.fatPer100
        carbsPer100 = product.carbsPer100
        packSizeGrams = product.packSizeGrams
        unit = product.unit.rawValue
        ingredientCategories = (try? JSONEncoder().encode(product.ingredientCategories))
            .flatMap { String(data: $0, encoding: .utf8) }
        usageCount = Int32(product.usageCount)
        lastUsed = product.lastUsed
        lowStockThreshold = product.lowStockThreshold
        defaultPortionSize = product.defaultPortionSize
    }
}
