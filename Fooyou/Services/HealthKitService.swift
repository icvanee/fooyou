import Foundation
import HealthKit

// Phase 2 — HealthKit writes are implemented when "markeer als gegeten" is done.
final class HealthKitService {
    static let shared = HealthKitService()
    private let store = HKHealthStore()
    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        let writeTypes: Set<HKSampleType> = [
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.dietaryCarbohydrates),
        ]
        try await store.requestAuthorization(toShare: writeTypes, read: [])
    }

    /// Writes a MealLog to HealthKit as an HKCorrelation.
    /// Returns the correlation UUID for back-reference.
    func writeMeal(_ log: MealLog) async throws -> UUID {
        guard isAvailable else { throw HKError(.errorHealthDataUnavailable) }

        let time = log.date
        let meta = mealMetadata(for: log)

        let samples: Set<HKSample> = [
            HKQuantitySample(
                type: HKQuantityType(.dietaryEnergyConsumed),
                quantity: .init(unit: .kilocalorie(), doubleValue: log.totalCalories),
                start: time, end: time, metadata: meta),
            HKQuantitySample(
                type: HKQuantityType(.dietaryProtein),
                quantity: .init(unit: .gram(), doubleValue: log.totalProtein),
                start: time, end: time, metadata: meta),
            HKQuantitySample(
                type: HKQuantityType(.dietaryFatTotal),
                quantity: .init(unit: .gram(), doubleValue: log.totalFat),
                start: time, end: time, metadata: meta),
            HKQuantitySample(
                type: HKQuantityType(.dietaryCarbohydrates),
                quantity: .init(unit: .gram(), doubleValue: log.totalCarbs),
                start: time, end: time, metadata: meta),
        ]

        let correlation = HKCorrelation(
            type: HKCorrelationType(.food),
            start: time, end: time,
            objects: samples,
            metadata: meta
        )

        try await store.save(correlation)
        return correlation.uuid
    }

    private func mealMetadata(for log: MealLog) -> [String: Any] {
        [
            HKMetadataKeyFoodType:          log.dishName,
            "FooyouMealSlot":               log.slot.rawValue,
            "FooyouMealSlotKey":            log.slot.healthKitMetadataLabel,
            "FooyouTotalCalories":          log.totalCalories,
            "FooyouSourceApp":              "Fooyou",
        ]
    }
}
