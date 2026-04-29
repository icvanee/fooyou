import SwiftUI
import CoreData

@main
struct FooyouApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()

    init() {
        let titleColor = UIColor(Theme.textPrimary)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

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

    static let appGroupID = "group.nl.fooyou.app"

    /// SQLite in App Group container — toegankelijk voor zowel de app als de Share Extension.
    static var storeURL: URL {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
            .appendingPathComponent("Fooyou.sqlite")
    }

    let container: NSPersistentCloudKitContainer

    private init() {
        container = NSPersistentCloudKitContainer(name: "Fooyou")

        let description = NSPersistentStoreDescription(url: Self.storeURL)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.nl.fooyou.app"
        )
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber,
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }

        if loadError != nil {
            // CloudKit niet geprovisioneerd — lokaal in App Group container
            description.cloudKitContainerOptions = nil
            container.persistentStoreDescriptions = [description]
            container.loadPersistentStores { _, error in
                if let error {
                    fatalError("CoreData failed to load: \(error.localizedDescription)")
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
