import Foundation
import CoreData

/// Convenience wrapper: scan a barcode → look up on Open Food Facts → persist as CDProduct.
final class BarcodeService {
    static let shared = BarcodeService()
    private init() {}

    func lookupAndSave(barcode: String, context: NSManagedObjectContext) async throws -> Product? {
        // Return existing product if already in DB
        let req = CDProduct.fetchRequest()
        req.predicate = NSPredicate(format: "barcode == %@", barcode)
        if let existing = try? context.fetch(req).first,
           let product = Product(from: existing) {
            return product
        }

        // Fetch from Open Food Facts
        guard let product = try await OpenFoodFactsService.shared.product(for: barcode) else {
            return nil
        }

        // Persist
        await MainActor.run {
            let cd = CDProduct(context: context)
            cd.populate(from: product)
            try? context.save()
        }
        return product
    }
}
