import SwiftUI
import CoreData

struct AddProductSearchSheet: View {
    let context: NSManagedObjectContext
    let onDone: () -> Void

    @State private var query = ""
    @State private var results: [Product] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var searchError: String? = nil
    @State private var selectedProduct: Product? = nil

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    HStack {
                        Spacer()
                        ProgressView("Zoeken…").tint(Theme.primary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if let error = searchError {
                    Text(error)
                        .font(.fooyouCaption())
                        .foregroundStyle(Theme.warning)
                        .listRowBackground(Color.clear)
                } else if results.isEmpty && hasSearched {
                    Text("Geen resultaten voor \"\(query)\"")
                        .font(.fooyouBody())
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(results) { product in
                        Button {
                            selectedProduct = product
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
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
                                    Text("\(Int(product.caloriesPer100)) kcal/100g")
                                        .font(.fooyouMono())
                                        .foregroundStyle(Theme.primary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Theme.surface)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Product zoeken")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Productnaam…")
            .onSubmit(of: .search) { search() }
            .onChange(of: query) { _, new in
                if new.isEmpty { results = []; searchError = nil; hasSearched = false }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { onDone() }
                }
            }
            .sheet(item: $selectedProduct) { product in
                AddToVoorraadSheet(product: product, context: context) {
                    selectedProduct = nil
                    onDone()
                }
            }
        }
    }

    private func search() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        searchError = nil
        Task {
            do {
                results = try await OpenFoodFactsService.shared.search(name: query)
                isSearching = false
                hasSearched = true
            } catch {
                isSearching = false
                hasSearched = true
                searchError = "Fout bij zoeken: \(error.localizedDescription)"
            }
        }
    }
}
