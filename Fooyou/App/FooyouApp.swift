import SwiftUI
import CoreData

@main
struct FooyouApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
        }
    }
}

// MARK: - CoreData stack

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    private init() {
        container = NSPersistentCloudKitContainer(name: "Fooyou")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No persistent store descriptions found.")
        }
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.nl.fooyou.app"
        )
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber,
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        if loadError != nil {
            // CloudKit container not yet provisioned — fall back to local store
            description.cloudKitContainerOptions = nil
            container.loadPersistentStores { _, error in
                if let error {
                    fatalError("CoreData failed to load (local fallback): \(error.localizedDescription)")
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
