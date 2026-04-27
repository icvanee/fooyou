import SwiftUI

struct MealSlotCard: View {
    let slot: MealSlot
    let plannedMeal: PlannedMeal?
    let mealLog: MealLog?
    let onAdd: () -> Void
    let onMarkEaten: (PlannedMeal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            slotHeader
            cardContent
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, style: borderStyle)
        )
    }

    // MARK: - Header

    private var slotHeader: some View {
        HStack {
            Text("\(slot.emoji) \(slot.rawValue)")
                .font(.fooyouHeadline())
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let cal = calorieDisplay {
                Text(cal)
                    .font(.fooyouMono())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(slot.color.opacity(0.18))
    }

    // MARK: - Content

    @ViewBuilder
    private var cardContent: some View {
        if let log = mealLog {
            // Eaten
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.eaten)
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.dishName)
                        .font(.fooyouBody())
                    Text(timeLabel(log.date))
                        .font(.fooyouCaption())
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
        } else if let meal = plannedMeal {
            // Planned — not yet eaten
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "list.clipboard")
                        .foregroundStyle(Theme.planned)
                    Text(meal.dishName)
                        .font(.fooyouBody())
                    Spacer()
                }
                Button {
                    onMarkEaten(meal)
                } label: {
                    Label("Markeer als gegeten", systemImage: "checkmark")
                        .font(.fooyouHeadline())
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        } else {
            // Empty
            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Theme.primary)
                    Text("Maaltijd plannen")
                        .font(.fooyouBody())
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(height: 44)
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var calorieDisplay: String? {
        if let log = mealLog {
            return "\(Int(log.totalCalories)) kcal"
        }
        if let meal = plannedMeal {
            return "~\(Int(meal.totalCalories)) kcal"
        }
        return nil
    }

    private var borderColor: Color {
        if mealLog != nil   { return Theme.eaten }
        if plannedMeal != nil { return Theme.planned }
        return .clear
    }

    private var borderStyle: StrokeStyle {
        if plannedMeal != nil && mealLog == nil {
            return StrokeStyle(lineWidth: 1.5, dash: [6, 4])
        }
        return StrokeStyle(lineWidth: 1.5)
    }

    private func timeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
