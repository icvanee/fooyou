import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            PantryView()
                .tabItem {
                    Label("Voorraad", systemImage: "cabinet.fill")
                }
                .tag(AppState.Tab.pantry)

            MealPlanView()
                .tabItem {
                    Label("Dag", systemImage: "calendar")
                }
                .tag(AppState.Tab.day)

            ScannerView()
                .tabItem {
                    Label("Scannen", systemImage: "camera.fill")
                }
                .tag(AppState.Tab.scanner)

            SettingsView()
                .tabItem {
                    Label("Instellingen", systemImage: "gearshape.fill")
                }
                .tag(AppState.Tab.settings)
        }
        .tint(Theme.primary)
        .background(Theme.background)
    }
}
