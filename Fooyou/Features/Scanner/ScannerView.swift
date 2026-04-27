import SwiftUI

struct ScannerView: View {
    @State private var showBarcodeScanner = false
    @State private var scannedBarcode: String? = nil
    @State private var lookupProduct: Product? = nil
    @State private var isLooking = false
    @State private var lookupError: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // 2×2 grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ScannerButton(icon: "barcode.viewfinder", label: "Barcode") {
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
        }
    }

    private func handleBarcode(_ barcode: String) {
        scannedBarcode = barcode
        isLooking = true
        lookupError = nil

        Task {
            do {
                let product = try await OpenFoodFactsService.shared.product(for: barcode)
                isLooking = false
                lookupProduct = product
                if product == nil {
                    lookupError = "Product niet gevonden voor barcode \(barcode)."
                }
            } catch {
                isLooking = false
                lookupError = "Fout bij opzoeken: \(error.localizedDescription)"
            }
        }
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
