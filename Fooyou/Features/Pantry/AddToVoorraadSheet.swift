import SwiftUI
import CoreData

struct AddToVoorraadSheet: View {
    let product: Product
    let context: NSManagedObjectContext
    let onDone: () -> Void

    @State private var amountText: String = "1"
    @State private var unit: FoodUnit
    @State private var count: Int = 1
    @State private var location: StorageLocation = .fridge
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var hasExpiry = false

    init(product: Product, context: NSManagedObjectContext, onDone: @escaping () -> Void) {
        self.product = product
        self.context = context
        self.onDone = onDone
        // Pre-fill amount from pack size if available
        let size = product.packSizeGrams > 0 ? product.packSizeGrams : 1
        _amountText = State(initialValue: size == size.rounded() ? String(Int(size)) : String(size))
        _unit = State(initialValue: product.unit)
    }

    private var totalQuantity: Double {
        (Double(amountText) ?? 1) * Double(count)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name)
                                .font(.fooyouHeadline())
                                .foregroundStyle(Theme.textPrimary)
                            if !product.brand.isEmpty {
                                Text(product.brand)
                                    .font(.fooyouCaption())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(product.caloriesPer100)) kcal")
                                .font(.fooyouMono())
                                .foregroundStyle(Theme.primary)
                            Text("per 100\(product.unit == .ml ? "ml" : "g")")
                                .font(.fooyouCaption())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Hoeveelheid per verpakking") {
                    HStack {
                        TextField("Hoeveelheid", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.fooyouBody())
                        Spacer()
                        Picker("Eenheid", selection: $unit) {
                            ForEach(FoodUnit.allCases, id: \.self) { u in
                                Text(u.rawValue).tag(u)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.primary)
                    }
                }

                Section("Aantal verpakkingen") {
                    Stepper(value: $count, in: 1...99) {
                        Text("\(count) × \(amountText) \(unit.rawValue)")
                            .foregroundStyle(Theme.textPrimary)
                    }
                    if count > 1 {
                        Text("Totaal: \(totalQuantity.formatted()) \(unit.rawValue)")
                            .font(.fooyouCaption())
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Locatie") {
                    Picker("Locatie", selection: $location) {
                        ForEach(StorageLocation.allCases, id: \.self) { loc in
                            Text(loc.rawValue).tag(loc)
                        }
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
            .background(Theme.background)
            .navigationTitle("Toevoegen aan voorraad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { onDone() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Toevoegen") {
                        saveToVoorraad()
                        onDone()
                    }
                    .fontWeight(.semibold)
                    .tint(Theme.primary)
                }
            }
        }
    }

    private func saveToVoorraad() {
        var updatedProduct = product
        updatedProduct.unit = unit
        let item = PantryItem(
            id: UUID(),
            product: updatedProduct,
            quantity: totalQuantity,
            expiryDate: hasExpiry ? expiryDate : nil,
            purchasedDate: Date(),
            location: location
        )
        let cd = CDPantryItem(context: context)
        cd.populate(from: item, context: context)
        try? context.save()
    }
}
