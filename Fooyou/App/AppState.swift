import SwiftUI
import CoreData

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: Tab = .pantry
    @Published var dailyCalorieGoal: Double = 2200
    @Published var dailyProteinGoal: Double = 150
    @Published var dailyFatGoal: Double = 75
    @Published var dailyCarbsGoal: Double = 250
    @Published var healthKitEnabled: Bool = false

    enum Tab: Int {
        case pantry, day, scanner, settings
    }
}
