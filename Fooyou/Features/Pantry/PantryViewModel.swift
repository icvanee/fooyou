import Foundation
import CoreData
import Combine

@MainActor
final class PantryViewModel: ObservableObject {
    @Published var items: [PantryItem] = []
    @Published var selectedLocation: StorageLocation? = nil
    @Published var searchText: String = ""

    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext) {
        self.context = context
        importInbox()
        fetch()

        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: context)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.fetch() }
            .store(in: &cancellables)
    }

    // MARK: - Share Extension inbox

    private struct InboxItem: Codable {
        var receiptName: String
        var resolvedName: String?
        var brand: String
        var caloriesPer100: Double
        var quantity: Double
        var unit: String
        var location: String
        var expiryDate: Date?
    }

    private func importInbox() {
        guard let dir = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.nl.fooyou.app") else { return }

        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil))?
            .filter { $0.lastPathComponent.hasPrefix("inbox_") && $0.pathExtension == "json" } ?? []

        guard !files.isEmpty else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Track pantry items created in this batch so same-product lines accumulate
        var batchItems: [String: CDPantryItem] = [:]

        for file in files {
            defer { try? FileManager.default.removeItem(at: file) }
            guard let data = try? Data(contentsOf: file),
                  let inbox = try? decoder.decode([InboxItem].self, from: data) else { continue }

            for item in inbox {
                let key = item.receiptName.lowercased()

                // 1. Find or create CDProduct
                let productReq = CDProduct.fetchRequest()
                productReq.predicate = NSPredicate(format: "name CONTAINS[cd] %@", key)
                productReq.fetchLimit = 1

                let cdProduct: CDProduct
                if let existing = (try? context.fetch(productReq))?.first {
                    cdProduct = existing
                    if item.caloriesPer100 > 0 && existing.caloriesPer100 == 0 {
                        existing.caloriesPer100 = item.caloriesPer100
                    }
                    if !item.brand.isEmpty && (existing.brand?.isEmpty ?? true) {
                        existing.brand = item.brand
                    }
                } else {
                    cdProduct = CDProduct(context: context)
                    cdProduct.id = UUID()
                    cdProduct.name = item.resolvedName ?? item.receiptName
                    cdProduct.brand = item.brand
                    cdProduct.caloriesPer100 = item.caloriesPer100
                    cdProduct.proteinPer100 = 0
                    cdProduct.fatPer100 = 0
                    cdProduct.carbsPer100 = 0
                    cdProduct.packSizeGrams = 100
                    cdProduct.unit = item.unit
                    cdProduct.usageCount = 0
                    cdProduct.lowStockThreshold = 100
                    cdProduct.defaultPortionSize = 100
                    cdProduct.ingredientCategories = "[]"
                }

                // 2. Accumulate into existing pantry item or create new
                if let existing = batchItems[key] {
                    existing.quantity += item.quantity
                } else {
                    let pantryReq = CDPantryItem.fetchRequest()
                    pantryReq.predicate = NSPredicate(format: "product.name CONTAINS[cd] %@", key)
                    pantryReq.fetchLimit = 1

                    if let existingItem = (try? context.fetch(pantryReq))?.first {
                        existingItem.quantity += item.quantity
                        batchItems[key] = existingItem
                    } else {
                        let cdItem = CDPantryItem(context: context)
                        cdItem.id = UUID()
                        cdItem.quantity = item.quantity
                        cdItem.purchasedDate = Date()
                        cdItem.expiryDate = item.expiryDate
                        cdItem.location = item.location
                        cdItem.product = cdProduct
                        batchItems[key] = cdItem
                    }
                }
            }
        }

        if context.hasChanges {
            do { try context.save() } catch { print("importInbox save error: \(error)") }
        }
    }

    // MARK: - Verfijn: link pantry item to richer OFacts product data

    func refine(item: PantryItem, with product: Product) {
        let pantryReq = CDPantryItem.fetchRequest()
        pantryReq.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        guard let cdItem = (try? context.fetch(pantryReq))?.first,
              let currentProduct = cdItem.product else { return }

        if let barcode = product.barcode, !barcode.isEmpty {
            let dupReq = CDProduct.fetchRequest()
            dupReq.predicate = NSPredicate(format: "barcode == %@ AND self != %@", barcode, currentProduct)
            dupReq.fetchLimit = 1

            if let existing = (try? context.fetch(dupReq))?.first {
                // Another CDProduct already has this barcode → merge
                let existingItemReq = CDPantryItem.fetchRequest()
                existingItemReq.predicate = NSPredicate(format: "product == %@", existing)
                existingItemReq.fetchLimit = 1

                if let existingPantryItem = (try? context.fetch(existingItemReq))?.first {
                    existingPantryItem.quantity += cdItem.quantity
                    context.delete(cdItem)
                } else {
                    cdItem.product = existing
                }
                existing.populate(from: product)

                // Remove rough product if now orphaned
                let orphanReq = CDPantryItem.fetchRequest()
                orphanReq.predicate = NSPredicate(format: "product == %@", currentProduct)
                if (try? context.fetch(orphanReq))?.isEmpty ?? true {
                    context.delete(currentProduct)
                }
                save(); fetch(); return
            }
        }

        // No barcode conflict — update in-place
        currentProduct.populate(from: product)
        save(); fetch()
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
        let newQty = item.quantity + delta
        if newQty <= 0 {
            delete(item)
            return
        }
        let request = CDPantryItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        if let cd = try? context.fetch(request).first {
            cd.quantity = newQty
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
