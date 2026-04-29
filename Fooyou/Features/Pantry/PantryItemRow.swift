import SwiftUI

struct PantryItemRow: View {
    let item: PantryItem
    let onUse: () -> Void
    let onDelete: () -> Void
    let onRefine: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            expiryIndicator
            VStack(alignment: .leading, spacing: 2) {
                Text(item.product.name)
                    .font(.fooyouHeadline())
                    .foregroundStyle(Theme.textPrimary)
                if !item.product.brand.isEmpty {
                    Text(item.product.brand)
                        .font(.fooyouCaption())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(quantityText)
                    .font(.fooyouMono())
                    .foregroundStyle(Theme.textPrimary)
                if let expiry = item.expiryDate {
                    Text(expiryLabel(expiry))
                        .font(.fooyouCaption())
                        .foregroundStyle(expiryColor)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Verwijder", systemImage: "trash")
            }
            Button(action: onUse) {
                Label("Afboeken", systemImage: "minus.circle.fill")
            }
            .tint(Theme.primary)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onRefine) {
                Label("Verfijn", systemImage: "wand.and.stars")
            }
            .tint(.blue)
        }
    }

    private var expiryIndicator: some View {
        Circle()
            .fill(expiryColor)
            .frame(width: 10, height: 10)
    }

    private var expiryColor: Color {
        switch item.expiryStatus {
        case .fresh:    return Theme.eaten
        case .warning:  return .yellow
        case .critical: return Theme.warning
        case .expired:  return .black
        case .none:     return .gray
        }
    }

    private var quantityText: String {
        let q = item.quantity
        let unit = item.product.unit.rawValue
        if q == q.rounded() {
            return "\(Int(q)) \(unit)"
        }
        return String(format: "%.1f \(unit)", q)
    }

    private func expiryLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter.string(from: date)
    }
}
