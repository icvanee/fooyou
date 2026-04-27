import SwiftUI

enum MealSlot: String, CaseIterable, Codable, Identifiable {
    case breakfast      = "Ontbijt"
    case morningSnack   = "Snack ochtend"
    case lunch          = "Lunch"
    case afternoonSnack = "Snack middag"
    case dinner         = "Avondeten"
    case eveningSnack   = "Snack avond"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .breakfast:      return "🌅"
        case .morningSnack:   return "🍎"
        case .lunch:          return "☀️"
        case .afternoonSnack: return "🍊"
        case .dinner:         return "🌙"
        case .eveningSnack:   return "🌟"
        }
    }

    var defaultHour: Int {
        switch self {
        case .breakfast:      return 7
        case .morningSnack:   return 10
        case .lunch:          return 13
        case .afternoonSnack: return 16
        case .dinner:         return 18
        case .eveningSnack:   return 21
        }
    }

    var color: Color {
        switch self {
        case .breakfast:      return Color(hex: "FFD166")
        case .morningSnack:   return Color(hex: "FFE8A3")
        case .lunch:          return Color(hex: "52B788")
        case .afternoonSnack: return Color(hex: "A8E6CF")
        case .dinner:         return Color(hex: "457B9D")
        case .eveningSnack:   return Color(hex: "A8DADC")
        }
    }

    var healthKitMetadataLabel: String { rawValue }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }
        self.init(
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255
        )
    }
}
