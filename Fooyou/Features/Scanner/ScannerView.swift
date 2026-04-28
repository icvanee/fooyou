import SwiftUI
import CoreData

struct ScannerView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var showBarcodeScanner = false
    @State private var isLooking = false
    @State private var lookupError: String? = nil
    @State private var foundProduct: Product? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ScannerButton(icon: "barcode.viewfinder", label: "Barcode") {
                        lookupError = nil
                        showBarcodeScanner = true
                    }
                    ScannerButton(icon: "doc.text.viewfinder", label: "Kassabon") {
                        // Phase 1b — Share Extension
                    }
                    ScannerButton(icon: "camera.viewfinder", label: "Maaltijd foto") {
                        // Phase 3 — Claude Vision
                    }
                    ScannerButton(icon: "square.and.pencil", label: "Handmatig") {
                        // Phase 1 — manual product entry
                    }
                }
                .padding(.horizontal)

                if isLooking {
                    ProgressView("Opzoeken…")
                        .tint(Theme.primary)
                }

                if let error = lookupError {
                    Text(error)
                        .font(.fooyouCaption())
                        .foregroundStyle(Theme.warning)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Scannen")
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView { barcode in
                    showBarcodeScanner = false
                    handleBarcode(barcode)
                } onCancel: {
                    showBarcodeScanner = false
                }
                .ignoresSafeArea()
            }
            .sheet(item: $foundProduct) { product in
                AddToVoorraadSheet(product: product, context: context) {
                    foundProduct = nil
                }
            }
        }
    }

    private func handleBarcode(_ barcode: String) {
        // Check local CoreData first
        if let cached = localProduct(for: barcode) {
            foundProduct = cached
            return
        }

        isLooking = true
        lookupError = nil

        Task {
            do {
                if let product = try await OpenFoodFactsService.shared.product(for: barcode) {
                    isLooking = false
                    foundProduct = product
                } else {
                    isLooking = false
                    lookupError = "Product niet gevonden voor barcode \(barcode)."
                }
            } catch {
                isLooking = false
                lookupError = "Fout bij opzoeken: \(error.localizedDescription)"
            }
        }
    }

    private func localProduct(for barcode: String) -> Product? {
        let request = CDProduct.fetchRequest()
        request.predicate = NSPredicate(format: "barcode == %@", barcode)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first.flatMap { Product(from: $0) }
    }
}

// MARK: - Reusable scanner button

private struct ScannerButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.primary)
                Text(label)
                    .font(.fooyouHeadline())
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}
