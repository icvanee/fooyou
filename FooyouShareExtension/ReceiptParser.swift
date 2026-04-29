import PDFKit
import Foundation

// MARK: - Data model

struct BonItem: Identifiable {
    var id = UUID()
    var receiptName: String        // Zoals op de bon: "AH KWARK"
    var displayName: String        // Gecapitaliseerd: "AH Kwark"
    var quantity: Double           // Aantal of gewicht
    var unitRaw: String            // "stuks", "kg", "gram", "ml"
    var isSelected: Bool = true
    var defaultLocation: String    // "Koelkast", "Vriezer", "Kast"
    var defaultExpiry: Date?       // Slimme default op basis van categorie

    // Ingevuld na matching (async)
    var resolvedName: String?      // Naam uit OpenFoodFacts / lokale DB
    var caloriesPer100: Double = 0
    var brand: String = ""
    var matchState: MatchState = .pending

    enum MatchState { case pending, matching, matched, notFound }

    var finalName: String { resolvedName ?? displayName }
    var finalUnit: String {
        // Converteer "kg" naar "gram" voor consistentie met app
        switch unitRaw {
        case "kg": return "gram"
        default:   return unitRaw
        }
    }
    var finalQuantity: Double {
        unitRaw == "kg" ? quantity * 1000 : quantity
    }
}

// MARK: - Parser

struct ReceiptParser {

    static func parse(pdf: PDFDocument) -> [BonItem] {
        let text = (0..<pdf.pageCount)
            .compactMap { pdf.page(at: $0)?.string }
            .joined(separator: "\n")
        return parse(text: text)
    }

    static func parse(text: String) -> [BonItem] {
        text.components(separatedBy: .newlines)
            .compactMap { parseLine($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.receiptName.isEmpty }
    }

    // MARK: - Private

    private static let skipWords: Set<String> = [
        "BONUSKAART", "AIRMILES", "SUBTOTAAL", "TOTAAL", "BTW", "PINNEN",
        "MIJN AH MILES", "UW VOORDEEL", "WAARVAN", "BONUS BOX", "KOOPZEGELS",
        "SPAARACTIES", "ESPAARZEGELS", "KLANTTICKET", "MERCHANT", "TRANSACTIE",
        "POI", "TOKEN", "PERIODE", "TERMINAL", "OVER", "EUR", "BETAALD",
        "VRAGEN", "HELPEN", "MEDEWERKERS", "KASSABON", "PREMIUM"
    ]

    /// Probeert een bon-regel te parsen.
    /// Formaten die voorkomen op AH bons:
    ///   "2 SLA MELANGE 1,09 2,18"          → qty=2, naam=SLA MELANGE
    ///   "1 AH KIPFILET 4,24"               → qty=1, naam=AH KIPFILET
    ///   "0.657KG BROCCOLI 3,18 2,09"       → qty=0.657 kg, naam=BROCCOLI
    private static func parseLine(_ line: String) -> BonItem? {
        guard !line.isEmpty else { return nil }

        // Skip regels met bekende niet-product woorden
        let upper = line.uppercased()
        for word in skipWords where upper.contains(word) { return nil }

        // Probeer gewicht-gebaseerd patroon: "0.657KG NAAM ..."
        if let item = parseWeightLine(line) { return item }

        // Probeer stuk-gebaseerd patroon: "2 NAAM [prijs] [bedrag]"
        if let item = parseCountLine(line) { return item }

        return nil
    }

    // "0.657KG BROCCOLI 3,18 2,09"
    private static func parseWeightLine(_ line: String) -> BonItem? {
        let pattern = #"^(\d+[.,]\d+)\s*[Kk][Gg]\s+([A-Z][A-Z0-9 &]+?)\s+[\d,]+.*$"#
        guard let match = line.range(of: pattern, options: .regularExpression) else { return nil }
        let parts = line[match].components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count >= 2 else { return nil }

        let qtyStr = parts[0].replacingOccurrences(of: "[Kk][Gg]", with: "", options: .regularExpression)
                             .replacingOccurrences(of: ",", with: ".")
        guard let qty = Double(qtyStr) else { return nil }

        // Naam = alles na het KG-token tot aan de prijs
        let nameEnd = parts.firstIndex(where: { isPrice($0) }) ?? parts.endIndex
        let nameParts = Array(parts[1..<nameEnd])
        let name = nameParts.joined(separator: " ").uppercased()
        guard !name.isEmpty, !skipWords.contains(where: { name.contains($0) }) else { return nil }

        return makeBonItem(name: name, quantity: qty, unit: "kg")
    }

    // "2 AH KWARK 2,49"  of  "2 SLA MELANGE 1,09 2,18"
    private static func parseCountLine(_ line: String) -> BonItem? {
        let pattern = #"^(\d+)\s+([A-Z][A-Z0-9 &]+?)\s+[\d,]+(?:\s+[\d,]+)?$"#
        guard line.range(of: pattern, options: .regularExpression) != nil else { return nil }

        let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count >= 3, let qty = Double(parts[0]) else { return nil }

        // Naam = alles tussen het getal en de eerste prijs
        let nameEnd = parts.dropFirst().firstIndex(where: { isPrice($0) }) ?? parts.endIndex
        let nameStart = parts.index(after: parts.startIndex)
        guard nameStart < nameEnd else { return nil }
        let name = parts[nameStart..<nameEnd].joined(separator: " ").uppercased()
        guard !name.isEmpty, !skipWords.contains(where: { name.contains($0) }) else { return nil }

        return makeBonItem(name: name, quantity: qty, unit: "stuks")
    }

    private static func isPrice(_ s: String) -> Bool {
        s.range(of: #"^\d+[,\.]\d{2}$"#, options: .regularExpression) != nil
    }

    // MARK: - Smart defaults

    private static func makeBonItem(name: String, quantity: Double, unit: String) -> BonItem {
        let display = name.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")

        let location = defaultLocation(for: name)
        let expiry   = defaultExpiry(for: name)

        return BonItem(
            receiptName: name,
            displayName: display,
            quantity: quantity,
            unitRaw: unit,
            defaultLocation: location,
            defaultExpiry: expiry
        )
    }

    private static func defaultLocation(for name: String) -> String {
        let n = name.uppercased()
        let koelkast = ["KWARK", "MELK", "YOGHURT", "ACTIVIA", "KAAS", "KIP",
                        "VLEES", "VIS", "BROCCOLI", "SLA", "GROENTE", "FRUIT",
                        "KOOKZUIVE", "ROOMBOTER", "BOTER", "EI"]
        let vriezer  = ["DIEPVRIES", "IJS", "PIZZA"]
        if vriezer.contains(where: { n.contains($0) }) { return "Vriezer" }
        if koelkast.contains(where: { n.contains($0) }) { return "Koelkast" }
        return "Kast"
    }

    private static func defaultExpiry(for name: String) -> Date? {
        let n = name.uppercased()
        let cal = Calendar.current
        let days: Int?
        if ["KIPFILET", "GEHAKT", "VIS"].contains(where: { n.contains($0) }) {
            days = 2
        } else if ["KWARK", "MELK", "YOGHURT", "ACTIVIA", "KOOKZUIVE"].contains(where: { n.contains($0) }) {
            days = 10
        } else if ["BROCCOLI", "SLA", "GROENTE", "FRUIT"].contains(where: { n.contains($0) }) {
            days = 5
        } else if ["KAAS"].contains(where: { n.contains($0) }) {
            days = 14
        } else {
            days = nil
        }
        return days.map { cal.date(byAdding: .day, value: $0, to: Date())! }
    }
}
