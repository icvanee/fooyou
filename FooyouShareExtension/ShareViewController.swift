import UIKit
import SwiftUI
import UniformTypeIdentifiers
import PDFKit

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        Task { await handleSharedContent() }
    }

    private func handleSharedContent() async {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first else {
            showError("Geen inhoud ontvangen.")
            return
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
            do {
                if let url = try? await provider.loadItem(forTypeIdentifier: UTType.pdf.identifier) as? URL,
                   let pdf = PDFDocument(url: url) {
                    showBonReview(for: pdf)
                    return
                }
                if let data = try await provider.loadItem(forTypeIdentifier: UTType.pdf.identifier) as? Data,
                   let pdf = PDFDocument(data: data) {
                    showBonReview(for: pdf)
                    return
                }
            } catch {
                showError("Kon de PDF niet openen: \(error.localizedDescription)")
                return
            }
        }

        showError("Alleen PDF-kassabonnen worden ondersteund.\nDeel de bon als PDF vanuit de AH app.")
    }

    private func showBonReview(for pdf: PDFDocument) {
        let items = ReceiptParser.parse(pdf: pdf)

        guard !items.isEmpty else {
            showError("Geen producten gevonden in de kassabon.")
            return
        }

        let reviewView = BonReviewView(items: items) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let host = UIHostingController(rootView: reviewView)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            self.addChild(host)
            self.view.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                host.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            ])
            host.didMove(toParent: self)
        }
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "Fooyou", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Sluiten", style: .default) { [weak self] _ in
                self?.extensionContext?.completeRequest(returningItems: nil)
            })
            self.present(alert, animated: true)
        }
    }
}
