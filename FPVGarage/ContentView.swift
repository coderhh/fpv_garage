import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            HomeView(appState: appState)
                .tabItem { Label("Home", systemImage: "house.fill") }
            FlightListView()
                .tabItem { Label("Flights", systemImage: "airplane") }
            AircraftListView()
                .tabItem { Label("Aircraft", systemImage: "cube.box.fill") }
            BatteryListView()
                .tabItem { Label("Batteries", systemImage: "battery.100") }
            PartListView()
                .tabItem { Label("Parts", systemImage: "wrench.and.screwdriver") }
        }
        .tint(.green)
    }
}
