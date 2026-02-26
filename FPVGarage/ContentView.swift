import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("首页", systemImage: "house.fill") }
            FlightListView()
                .tabItem { Label("飞行", systemImage: "airplane") }
            AircraftListView()
                .tabItem { Label("飞机", systemImage: "cube.box.fill") }
            BatteryListView()
                .tabItem { Label("电池", systemImage: "battery.100") }
            PartListView()
                .tabItem { Label("部件", systemImage: "wrench.and.screwdriver") }
        }
        .tint(.green)
    }
}

