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

        for file in files {
            defer { try? FileManager.default.removeItem(at: file) }
            guard let data = try? Data(contentsOf: file),
                  let inbox = try? decoder.decode([InboxItem].self, from: data) else { continue }

            for item in inbox {
                let productReq = NSFetchRequest<NSManagedObject>(entityName: "CDProduct")
                productReq.predicate = NSPredicate(format: "name CONTAINS[cd] %@", item.receiptName.lowercased())
                productReq.fetchLimit = 1

                let cdProduct: NSManagedObject
                if let existing = (try? context.fetch(productReq))?.first {
                    cdProduct = existing
                } else {
                    cdProduct = NSEntityDescription.insertNewObject(forEntityName: "CDProduct", into: context)
                    cdProduct.setValue(UUID(), forKey: "id")
                    cdProduct.setValue(item.resolvedName ?? item.receiptName, forKey: "name")
                    cdProduct.setValue(item.brand, forKey: "brand")
                    cdProduct.setValue(item.caloriesPer100, forKey: "caloriesPer100")
                    cdProduct.setValue(0.0, forKey: "proteinPer100")
                    cdProduct.setValue(0.0, forKey: "fatPer100")
                    cdProduct.setValue(0.0, forKey: "carbsPer100")
                    cdProduct.setValue(100.0, forKey: "packSizeGrams")
                    cdProduct.setValue(item.unit, forKey: "unit")
                    cdProduct.setValue(Int32(0), forKey: "usageCount")
                    cdProduct.setValue(100.0, forKey: "lowStockThreshold")
                    cdProduct.setValue(100.0, forKey: "defaultPortionSize")
                    cdProduct.setValue("[]", forKey: "ingredientCategories")
                }

                let cdItem = NSEntityDescription.insertNewObject(forEntityName: "CDPantryItem", into: context)
                cdItem.setValue(UUID(), forKey: "id")
                cdItem.setValue(item.quantity, forKey: "quantity")
                cdItem.setValue(Date(), forKey: "purchasedDate")
                cdItem.setValue(item.expiryDate, forKey: "expiryDate")
                cdItem.setValue(item.location, forKey: "location")
                cdItem.setValue(cdProduct, forKey: "product")
            }
        }

        if context.hasChanges { try? context.save() }
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
