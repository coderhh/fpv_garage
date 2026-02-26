import SwiftUI

@main
struct FPVGarageApp: App {
    @StateObject private var store = DataStore.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
