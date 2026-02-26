import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: DataStore

    var totalDuration: Int {
        store.flightRecords.reduce(0) { $0 + $1.durationSeconds }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("概览") {
                    HStack {
                        Label("飞行次数", systemImage: "airplane")
                        Spacer()
                        Text("\(store.flightRecords.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("总时长(秒)", systemImage: "clock")
                        Spacer()
                        Text("\(totalDuration)")
                            .foregroundStyle(.green)
                    }
                    HStack {
                        Label("飞机", systemImage: "cube.box")
                        Spacer()
                        Text("\(store.aircraft.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("电池", systemImage: "battery.100")
                        Spacer()
                        Text("\(store.batteries.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("开发与测试") {
                    Button {
                        store.seedTestData()
                    } label: {
                        Label("生成测试数据", systemImage: "doc.badge.plus")
                    }
                }
            }
            .navigationTitle("FPV Garage")
        }
    }
}

