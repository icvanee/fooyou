import Foundation

// Open Food Facts API — barcode lookup and Dutch name search
final class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Fooyou/1.0 (iOS; nl) - github.com/icvanee/fooyou"
        ]
        return URLSession(configuration: config)
    }()

    // MARK: - Barcode lookup

    /// Fetches a product by EAN/UPC barcode.
    func product(for barcode: String) async throws -> Product? {
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json"
        guard let url = URL(string: urlString) else { throw OFFError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OFFError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let decoded = try JSONDecoder().decode(OFFProductResponse.self, from: data)
        guard decoded.status == 1, let p = decoded.product else { return nil }
        return product(from: p, barcode: barcode)
    }

    // MARK: - Name search (Dutch)

    /// Searches Open Food Facts for products matching the query (v2 API).
    func search(name: String, maxResults: Int = 20) async throws -> [Product] {
        var comps = URLComponents(string: "https://world.openfoodfacts.org/api/v2/search")!
        comps.queryItems = [
            URLQueryItem(name: "search_terms", value: name),
            URLQueryItem(name: "fields", value: "code,product_name,product_name_nl,brands,quantity,image_front_small_url,nutriments,categories_tags"),
            URLQueryItem(name: "lc", value: "nl"),
            URLQueryItem(name: "page_size", value: "\(maxResults)"),
        ]
        guard let url = comps.url else { throw OFFError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OFFError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let decoded = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
        return decoded.products.compactMap { product(from: $0, barcode: nil) }
    }

    // MARK: - Mapping

    private func product(from p: OFFProduct, barcode: String?) -> Product? {
        guard let name = p.productName ?? p.productNameNl, !name.isEmpty else { return nil }

        let nut = p.nutriments
        return Product(
            barcode: barcode ?? p.code,
            name: name,
            brand: p.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? "",
            imageURL: p.imageFrontSmallUrl.flatMap { URL(string: $0) },
            caloriesPer100: nut?.energyKcal100g ?? nut?.energyKcal ?? 0,
            proteinPer100: nut?.proteins100g ?? 0,
            fatPer100: nut?.fat100g ?? 0,
            carbsPer100: nut?.carbohydrates100g ?? 0,
            packSizeGrams: parseQuantity(p.quantity),
            unit: unitFrom(p.quantity),
            ingredientCategories: p.categoriesTags?.map { tag in
                tag.replacingOccurrences(of: "en:", with: "")
                   .replacingOccurrences(of: "nl:", with: "")
            } ?? [],
            usageCount: 0,
            lowStockThreshold: 100,
            defaultPortionSize: 100
        )
    }

    private func parseQuantity(_ raw: String?) -> Double {
        guard let raw else { return 100 }
        let digits = raw.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Double(digits) ?? 100
    }

    private func unitFrom(_ raw: String?) -> FoodUnit {
        guard let raw = raw?.lowercased() else { return .gram }
        if raw.contains("ml") || raw.contains("l ") || raw.contains("liter") { return .ml }
        if raw.contains("stuk") || raw.contains("piece") || raw.contains("x ") { return .stuks }
        return .gram
    }
}

// MARK: - Error

enum OFFError: LocalizedError {
    case invalidURL
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:     return "Ongeldige URL."
        case .httpError(let code): return "Server fout \(code)."
        }
    }
}

// MARK: - Decodable response types

private struct OFFProductResponse: Decodable {
    var status: Int
    var product: OFFProduct?
}

private struct OFFSearchResponse: Decodable {
    var products: [OFFProduct]
}

private struct OFFProduct: Decodable {
    var code: String?
    var productName: String?
    var productNameNl: String?
    var brands: String?
    var quantity: String?
    var imageFrontSmallUrl: String?
    var categoriesTags: [String]?
    var nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case code
        case productName        = "product_name"
        case productNameNl      = "product_name_nl"
        case brands
        case quantity
        case imageFrontSmallUrl = "image_front_small_url"
        case categoriesTags     = "categories_tags"
        case nutriments
    }
}

private struct OFFNutriments: Decodable {
    var energyKcal100g: Double?
    var energyKcal: Double?
    var proteins100g: Double?
    var fat100g: Double?
    var carbohydrates100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g    = "energy-kcal_100g"
        case energyKcal        = "energy-kcal"
        case proteins100g      = "proteins_100g"
        case fat100g           = "fat_100g"
        case carbohydrates100g = "carbohydrates_100g"
    }
}
