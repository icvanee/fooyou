import SwiftUI
import CoreData

struct AfboekenSheet: View {
    let item: PantryItem
    let context: NSManagedObjectContext
    let onDone: (Double) -> Void

    enum Mode { case totaal, stuks }

    @State private var mode: Mode
    @State private var amountText: String = ""
    @State private var stuks: Int = 1
    @FocusState private var focused: Bool

    private var unit: String { item.product.unit.rawValue }
    private var packSize: Double {
        item.product.packSizeGrams > 0 ? item.product.packSizeGrams : item.quantity
    }
    private var maxStuks: Int { max(1, Int(item.quantity / packSize)) }

    private var used: Double {
        switch mode {
        case .totaal: return Double(amountText) ?? 0
        case .stuks:  return Double(stuks) * packSize
        }
    }
    private var remaining: Double { max(0, item.quantity - used) }
    private var isValid: Bool { used > 0 && used <= item.quantity }

    init(item: PantryItem, context: NSManagedObjectContext, onDone: @escaping (Double) -> Void) {
        self.item = item
        self.context = context
        self.onDone = onDone
        // Only offer stuks mode when packSize makes sense (< total quantity)
        let pack = item.product.packSizeGrams > 0 ? item.product.packSizeGrams : item.quantity
        _mode = State(initialValue: pack < item.quantity ? .stuks : .totaal)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text(item.product.name)
                        .font(.fooyouHeadline())
                        .foregroundStyle(Theme.textPrimary)
                    Text("Op voorraad: \(fmt(item.quantity)) \(unit)")
                        .font(.fooyouCaption())
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)

                // Mode picker — only show when stuks makes sense
                if packSize < item.quantity {
                    Picker("Modus", selection: $mode) {
                        Text("Stuks").tag(Mode.stuks)
                        Text("Hoeveelheid").tag(Mode.totaal)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                    .onChange(of: mode) { _, _ in amountText = "" }
                }

                // Input
                switch mode {
                case .stuks:
                    stuksInput
                case .totaal:
                    totaalInput
                }

                // Remaining
                if used > 0 {
                    Text("Blijft over: \(fmt(remaining)) \(unit)")
                        .font(.fooyouCaption())
                        .foregroundStyle(remaining == 0 ? Theme.warning : Theme.primary)
                        .padding(.top, 12)
                        .animation(.easeInOut, value: used)
                }

                Spacer()

                // Afboeken button
                Button { onDone(used) } label: {
                    Text("Afboeken")
                        .font(.fooyouHeadline())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Theme.primary : Theme.primary.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!isValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Voorraad afboeken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { onDone(0) }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Klaar") { focused = false }
                        .fontWeight(.semibold).tint(Theme.primary)
                }
            }
            .onAppear { if mode == .totaal { focused = true } }
        }
    }

    // MARK: - Stuks input

    private var stuksInput: some View {
        VStack(spacing: 16) {
            Text("Hoeveel flesjes / stuks?")
                .font(.fooyouBody())
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                Button {
                    if stuks > 1 { stuks -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(stuks > 1 ? Theme.primary : Theme.primary.opacity(0.3))
                }

                VStack(spacing: 2) {
                    Text("\(stuks)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                    Text("× \(fmt(packSize)) \(unit)")
                        .font(.fooyouCaption())
                        .foregroundStyle(.secondary)
                }

                Button {
                    if stuks < maxStuks { stuks += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(stuks < maxStuks ? Theme.primary : Theme.primary.opacity(0.3))
                }
            }

            Text("= \(fmt(used)) \(unit)")
                .font(.fooyouBody())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Totaal input

    private var totaalInput: some View {
        VStack(spacing: 8) {
            Text("Hoeveel gebruik je?")
                .font(.fooyouBody())
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .focused($focused)
                    .frame(maxWidth: 200)
                Text(unit)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 32)
    }

    private func fmt(_ q: Double) -> String {
        q == q.rounded() ? String(Int(q)) : String(format: "%.1f", q)
    }
}
