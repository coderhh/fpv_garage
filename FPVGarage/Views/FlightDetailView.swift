import SwiftUI

struct FlightDetailView: View {
    @EnvironmentObject var store: DataStore
    let flight: FlightRecord
    @State private var showEdit = false

    private var aircraft: Aircraft? {
        store.aircraft(by: flight.aircraftId)
    }

    private var batteries: [Battery] {
        store.batteries(by: flight.batteryIds)
    }

    private var durationText: String {
        "\(flight.durationSeconds) 秒"
    }

    var body: some View {
        List {
            Section("飞机") {
                HStack {
                    Text("名称")
                    Spacer()
                    Text(aircraft?.name ?? "—")
                        .foregroundStyle(.primary)
                }
            }

            Section("时间与时长") {
                HStack {
                    Text("起飞时间")
                    Spacer()
                    Text(DateFormatter.localizedString(from: flight.startAt, dateStyle: .medium, timeStyle: .short))
                        .foregroundStyle(.primary)
                }
                HStack {
                    Text("飞行时长")
                    Spacer()
                    Text(durationText)
                        .foregroundStyle(.primary)
                }
            }

            if !batteries.isEmpty {
                Section("使用电池") {
                    ForEach(batteries) { battery in
                        HStack {
                            Text(battery.name)
                            Spacer()
                            Text("循环 \(battery.cycles)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let address = flight.address, !address.isEmpty {
                Section("地点") {
                    Text(address)
                        .font(.body)
                }
            }

            if flight.latitude != nil || flight.longitude != nil {
                Section("坐标") {
                    HStack {
                        Text("纬度")
                        Spacer()
                        Text(flight.latitude.map { String(format: "%.6f", $0) } ?? "—")
                    }
                    HStack {
                        Text("经度")
                        Spacer()
                        Text(flight.longitude.map { String(format: "%.6f", $0) } ?? "—")
                    }
                }
            }

            if let remark = flight.remark, !remark.isEmpty {
                Section("备注") {
                    Text(remark)
                        .font(.body)
                }
            }
        }
        .navigationTitle("飞行详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") {
                    showEdit = true
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            FlightEditView(flight: flight)
        }
    }
}

