import Foundation
import UserNotifications

// Phase 4 — notifications implemented in the polish phase.
final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    private init() {}

    func requestAuthorization() async throws {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Schedule a low-stock alert for a pantry item.
    func scheduleLowStock(for productName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Bijna op"
        content.body = "\(productName) is bijna op."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "low_stock_\(productName)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    /// Schedule an expiry warning.
    func scheduleExpiryWarning(for productName: String, expiryDate: Date) {
        guard let triggerDate = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: expiryDate) else { return }
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let content = UNMutableNotificationContent()
        content.title = "Bijna verlopen"
        content.body = "\(productName) verloopt binnenkort."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "expiry_\(productName)_\(expiryDate.timeIntervalSince1970)",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        )
        center.add(request)
    }
}
