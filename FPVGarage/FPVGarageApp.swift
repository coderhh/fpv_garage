import SwiftUI

@main
struct FPVGarageApp: App {
    @StateObject private var container = DIContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container.appState)
        }
    }
}
