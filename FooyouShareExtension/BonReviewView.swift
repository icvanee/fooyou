import SwiftUI

// MARK: - Inbox item (written to App Group, imported by main app)

struct InboxItem: Codable {
    var receiptName: String
    var resolvedName: String?
    var brand: String
    var caloriesPer100: Double
    var quantity: Double
    var unit: String
    var location: String
    var expiryDate: Date?
}

// MARK: - Main review view

struct BonReviewView: View {
    @State var items: [BonItem]
    let onDone: () -> Void

    @State private var editingItem: BonItem? = nil

    private var selectedCount: Int { items.filter(\.isSelected).count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($items) { $item in
                        BonItemRow(item: $item) {
                            editingItem = item
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                item.isSelected = false
                            } label: {
                                Label("Overslaan", systemImage: "xmark")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    Text("\(selectedCount) van \(items.count) producten geselecteerd")
                        .font(.system(.caption, design: .rounded))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(hex: "FAFAF7"))
            .navigationTitle("Bon verwerkt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { onDone() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        saveAndDismiss()
                    } label: {
                        Text("Voeg \(selectedCount) toe")
                            .fontWeight(.semibold)
                    }
                    .tint(Color(hex: "2D6A4F"))
                    .disabled(selectedCount == 0)
                }
            }
            .sheet(item: $editingItem) { item in
                BonItemEditSheet(item: item) { updated in
                    if let idx = items.firstIndex(where: { $0.id == updated.id }) {
                        items[idx] = updated
                    }
                    editingItem = nil
                }
            }
            .task { await enrichItems() }
        }
    }

    // MARK: - OpenFoodFacts matching

    private func enrichItems() async {
        for idx in items.indices {
            guard items[idx].isSelected else { continue }
            items[idx].matchState = .matching

            do {
                let results = try await searchOpenFoodFacts(query: items[idx].displayName)
                if let first = results.first {
                    items[idx].resolvedName   = first.name
                    items[idx].brand          = first.brand
                    items[idx].caloriesPer100 = first.caloriesPer100
                    items[idx].matchState     = .matched
                } else {
                    items[idx].matchState = .notFound
                }
            } catch {
                items[idx].matchState = .notFound
            }
        }
    }

    private struct OFFResult {
        var name: String
        var brand: String
        var caloriesPer100: Double
    }

    private func searchOpenFoodFacts(query: String) async throws -> [OFFResult] {
        var comps = URLComponents(string: "https://world.openfoodfacts.org/api/v2/search")!
        comps.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "fields", value: "product_name,product_name_nl,brands,nutriments"),
            URLQueryItem(name: "lc", value: "nl"),
            URLQueryItem(name: "page_size", value: "3"),
        ]
        guard let url = comps.url else { return [] }
        var req = URLRequest(url: url)
        req.setValue("Fooyou/1.0 (iOS; nl) - github.com/icvanee/fooyou", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: req)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let products = json["products"] as? [[String: Any]] else { return [] }

        return products.compactMap { p -> OFFResult? in
            let name = (p["product_name_nl"] as? String ?? p["product_name"] as? String ?? "")
                .trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return nil }
            let brand = (p["brands"] as? String ?? "")
                .components(separatedBy: ",").first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            let nut = p["nutriments"] as? [String: Any]
            let kcal = nut?["energy-kcal_100g"] as? Double ?? nut?["energy-kcal"] as? Double ?? 0
            return OFFResult(name: name, brand: brand, caloriesPer100: kcal)
        }
    }

    // MARK: - Write inbox JSON (main app imports on next launch)

    private func saveAndDismiss() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let inbox = items.filter(\.isSelected).map { item in
            InboxItem(
                receiptName: item.receiptName,
                resolvedName: item.resolvedName,
                brand: item.brand,
                caloriesPer100: item.caloriesPer100,
                quantity: item.finalQuantity,
                unit: item.finalUnit,
                location: item.defaultLocation,
                expiryDate: item.defaultExpiry
            )
        }

        if let data = try? encoder.encode(inbox),
           let dir = FileManager.default
               .containerURL(forSecurityApplicationGroupIdentifier: "group.nl.fooyou.app") {
            let file = dir.appendingPathComponent("inbox_\(UUID().uuidString).json")
            try? data.write(to: file)
        }

        onDone()
    }
}

// MARK: - Row

struct BonItemRow: View {
    @Binding var item: BonItem
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                item.isSelected.toggle()
            } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(item.isSelected ? Color(hex: "2D6A4F") : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.finalName)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(item.isSelected ? Color(hex: "1A1A2E") : .secondary)
                    if item.matchState == .matching {
                        ProgressView().scaleEffect(0.7)
                    } else if item.matchState == .matched && item.caloriesPer100 > 0 {
                        Text("\(Int(item.caloriesPer100)) kcal")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color(hex: "2D6A4F"))
                    }
                }
                HStack(spacing: 8) {
                    Text("\(item.quantity.formatted()) \(item.unitRaw)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                    Label(item.defaultLocation, systemImage: locationIcon(item.defaultLocation))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                    if let expiry = item.defaultExpiry {
                        Text("THT \(expiry.formatted(.dateTime.day().month(.abbreviated)))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .opacity(item.isSelected ? 1 : 0.4)
    }

    private func locationIcon(_ loc: String) -> String {
        switch loc {
        case "Koelkast": return "refrigerator"
        case "Vriezer":  return "snowflake"
        default:         return "cabinet"
        }
    }
}

// MARK: - Edit sheet (per item)

struct BonItemEditSheet: View {
    @State var item: BonItem
    let onDone: (BonItem) -> Void

    @State private var quantityText: String
    @State private var selectedLocation: String
    @State private var hasExpiry: Bool
    @State private var expiryDate: Date

    init(item: BonItem, onDone: @escaping (BonItem) -> Void) {
        self.onDone = onDone
        _item = State(initialValue: item)
        _quantityText = State(initialValue: {
            let q = item.quantity
            return q == q.rounded() ? String(Int(q)) : String(format: "%.3f", q)
        }())
        _selectedLocation = State(initialValue: item.defaultLocation)
        _hasExpiry = State(initialValue: item.defaultExpiry != nil)
        _expiryDate = State(initialValue: item.defaultExpiry ?? Calendar.current.date(byAdding: .day, value: 7, to: Date())!)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    HStack {
                        Text(item.finalName)
                            .font(.system(.headline, design: .rounded))
                        Spacer()
                        if item.caloriesPer100 > 0 {
                            Text("\(Int(item.caloriesPer100)) kcal/100g")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Color(hex: "2D6A4F"))
                        }
                    }
                    if !item.brand.isEmpty {
                        Text(item.brand).foregroundStyle(.secondary).font(.caption)
                    }
                }

                Section("Hoeveelheid") {
                    HStack {
                        TextField("Hoeveelheid", text: $quantityText)
                            .keyboardType(.decimalPad)
                        Text(item.unitRaw).foregroundStyle(.secondary)
                    }
                }

                Section("Locatie") {
                    Picker("Locatie", selection: $selectedLocation) {
                        Text("Koelkast").tag("Koelkast")
                        Text("Vriezer").tag("Vriezer")
                        Text("Kast").tag("Kast")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Houdbaarheidsdatum") {
                    Toggle("THT instellen", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("THT", selection: $expiryDate, displayedComponents: .date)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "FAFAF7"))
            .navigationTitle("Bewerken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Gereed") {
                        var updated = item
                        updated.quantity = Double(quantityText.replacingOccurrences(of: ",", with: ".")) ?? item.quantity
                        updated.defaultLocation = selectedLocation
                        updated.defaultExpiry = hasExpiry ? expiryDate : nil
                        onDone(updated)
                    }
                    .fontWeight(.semibold)
                    .tint(Color(hex: "2D6A4F"))
                }
            }
        }
    }
}

// MARK: - Color(hex:) helper (standalone voor extension)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
