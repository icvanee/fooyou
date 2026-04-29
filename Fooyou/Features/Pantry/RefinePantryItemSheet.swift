import SwiftUI

struct RefinePantryItemSheet: View {
    let item: PantryItem
    let onRefine: (Product) -> Void
    let onCancel: () -> Void

    @State private var query = ""
    @State private var results: [Product] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var searchError: String? = nil
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            List {
                Section("Huidig item") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.product.name)
                                .font(.fooyouBody())
                                .foregroundStyle(Theme.textPrimary)
                            if !item.product.brand.isEmpty {
                                Text(item.product.brand)
                                    .font(.fooyouCaption())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(quantityText)
                            .font(.fooyouMono())
                            .foregroundStyle(Theme.primary)
                    }
                }

                Section("Koppel aan product") {
                    HStack {
                        TextField("Productnaam…", text: $query)
                            .onSubmit { search() }
                            .onChange(of: query) { _, v in
                                if v.isEmpty { results = []; hasSearched = false; searchError = nil }
                            }
                        if isSearching {
                            ProgressView().tint(Theme.primary)
                        } else {
                            Button(action: search) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(Theme.primary)
                            }
                            .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }

                    Button {
                        showScanner = true
                    } label: {
                        Label("Scan barcode", systemImage: "barcode.viewfinder")
                            .foregroundStyle(Theme.primary)
                    }
                }

                if let error = searchError {
                    Text(error)
                        .font(.fooyouCaption())
                        .foregroundStyle(Theme.warning)
                        .listRowBackground(Color.clear)
                } else if hasSearched && results.isEmpty {
                    Text("Geen resultaten voor \"\(query)\"")
                        .font(.fooyouBody())
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else if !results.isEmpty {
                    Section("Zoekresultaten") {
                        ForEach(results) { product in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.name)
                                        .font(.fooyouBody())
                                        .foregroundStyle(Theme.textPrimary)
                                    HStack {
                                        if !product.brand.isEmpty {
                                            Text(product.brand)
                                                .font(.fooyouCaption())
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if product.caloriesPer100 > 0 {
                                            Text("\(Int(product.caloriesPer100)) kcal")
                                                .font(.fooyouMono())
                                                .foregroundStyle(Theme.primary)
                                        }
                                    }
                                }
                                Button("Koppel") {
                                    onRefine(product)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.primary)
                                .font(.fooyouCaption())
                            }
                            .listRowBackground(Theme.surface)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Verfijn product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer", action: onCancel)
                }
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView(
                    onScan: { barcode in
                        showScanner = false
                        lookupBarcode(barcode)
                    },
                    onCancel: { showScanner = false }
                )
                .ignoresSafeArea()
            }
        }
    }

    private var quantityText: String {
        let q = item.quantity
        let u = item.product.unit.rawValue
        return q == q.rounded() ? "\(Int(q)) \(u)" : String(format: "%.1f \(u)", q)
    }

    private func search() {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        isSearching = true; searchError = nil
        Task {
            do {
                results = try await OpenFoodFactsService.shared.search(name: q, maxResults: 10)
                hasSearched = true
            } catch {
                searchError = "Fout bij zoeken: \(error.localizedDescription)"
                hasSearched = true
            }
            isSearching = false
        }
    }

    private func lookupBarcode(_ barcode: String) {
        query = barcode
        isSearching = true; searchError = nil
        Task {
            do {
                if let product = try await OpenFoodFactsService.shared.product(for: barcode) {
                    results = [product]
                } else {
                    results = []
                }
                hasSearched = true
            } catch {
                searchError = "Fout bij barcode opzoeken."
                hasSearched = true
            }
            isSearching = false
        }
    }
}
