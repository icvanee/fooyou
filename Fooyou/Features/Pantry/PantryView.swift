import SwiftUI
import CoreData

struct PantryView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var vm: PantryViewModel
    @State private var showAddProduct = false
    @State private var itemToUse: PantryItem? = nil
    @State private var itemToRefine: PantryItem? = nil

    init() {
        // Initialised with a temporary context; replaced on appear via environment
        _vm = StateObject(wrappedValue: PantryViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                locationPicker
                    .padding(.horizontal)
                    .padding(.top, 8)

                if vm.filteredItems.isEmpty {
                    emptyState
                } else {
                    itemList
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Voorraad")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $vm.searchText, prompt: "Zoek product")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddProduct = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .tint(Theme.primary)
                }
            }
            .sheet(isPresented: $showAddProduct) {
                AddProductSearchSheet(context: context) {
                    showAddProduct = false
                    vm.fetch()
                }
            }
            .sheet(item: $itemToUse) { item in
                AfboekenSheet(item: item, context: context) { delta in
                    if delta > 0 {
                        vm.updateQuantity(for: item, delta: -delta)
                    }
                    itemToUse = nil
                }
            }
            .sheet(item: $itemToRefine) { item in
                RefinePantryItemSheet(item: item) { product in
                    vm.refine(item: item, with: product)
                    itemToRefine = nil
                } onCancel: {
                    itemToRefine = nil
                }
            }
        }
    }

    private var locationPicker: some View {
        HStack(spacing: 8) {
            ForEach([nil] + StorageLocation.allCases.map { Optional($0) }, id: \.self) { loc in
                let label = loc?.rawValue ?? "Alles"
                Button(label) {
                    vm.selectedLocation = loc
                }
                .font(.fooyouCaption())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(vm.selectedLocation == loc ? Theme.primary : Theme.surface)
                .foregroundStyle(vm.selectedLocation == loc ? .white : Theme.textPrimary)
                .clipShape(Capsule())
                .shadow(color: Theme.cardShadow, radius: 4, y: 2)
            }
            Spacer()
        }
    }

    private var itemList: some View {
        List {
            ForEach(vm.filteredItems) { item in
                PantryItemRow(
                    item: item,
                    onUse: { itemToUse = item },
                    onDelete: { vm.delete(item) },
                    onRefine: { itemToRefine = item }
                )
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Color.gray.opacity(0.15))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "cabinet")
                .font(.system(size: 56))
                .foregroundStyle(Theme.primary.opacity(0.4))
            Text("Je voorraad is leeg")
                .font(.fooyouHeadline())
                .foregroundStyle(.secondary)
            Text("Scan een barcode of voeg een product toe.")
                .font(.fooyouBody())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}
