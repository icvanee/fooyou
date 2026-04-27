import Foundation

enum StockStatus: String {
    case ok       = "Ok"
    case low      = "Bijna op"
    case empty    = "Op"
}

enum ExpiryStatus: String {
    case fresh    = "Vers"
    case warning  = "Binnenkort"
    case critical = "Bijna verlopen"
    case expired  = "Verlopen"
    case none     = "Geen datum"
}

struct PantryItem: Identifiable, Codable {
    var id: UUID = UUID()
    var product: Product
    var quantity: Double
    var expiryDate: Date?
    var purchasedDate: Date
    var location: StorageLocation

    var stockStatus: StockStatus {
        if quantity <= 0 { return .empty }
        if quantity <= product.lowStockThreshold { return .low }
        return .ok
    }

    var expiryStatus: ExpiryStatus {
        guard let expiry = expiryDate else { return .none }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
        if days < 0  { return .expired }
        if days < 3  { return .critical }
        if days < 7  { return .warning }
        return .fresh
    }
}
