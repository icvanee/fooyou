import SwiftUI
import CoreData

struct PantryView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var vm: PantryViewModel
    @State private var showAddProduct = false

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
                .shadow(color: Theme.cardShadow as! Color, radius: 4, y: 2)
            }
            Spacer()
        }
    }

    private var itemList: some View {
        List {
            ForEach(vm.filteredItems) { item in
                PantryItemRow(item: item) {
                    vm.updateQuantity(for: item, delta: -1)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Color.gray.opacity(0.15))
            }
            .onDelete { offsets in
                offsets.forEach { idx in
                    vm.delete(vm.filteredItems[idx])
                }
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
