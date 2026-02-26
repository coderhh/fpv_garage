import SwiftUI
import MapKit
import CoreLocation

// MARK: - Current location fetcher
private final class CurrentLocationFetcher: NSObject, ObservableObject {
    @Published var lastCoordinate: CLLocationCoordinate2D?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
}

extension CurrentLocationFetcher: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastCoordinate = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Permission denied or location unavailable
    }
}

// MARK: - Flight edit view
struct FlightEditView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let flight: FlightRecord?

    @State private var selectedAircraftId: UUID?
    @State private var startAt: Date = Date()
    @State private var durationSeconds: String = "0"
    @State private var address: String = ""
    @State private var remark: String = ""
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var mapPosition: MapCameraPosition = .region(defaultMapRegion)
    @StateObject private var locationFetcher = CurrentLocationFetcher()

    private static let defaultMapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9, longitude: 116.4),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    private var isNew: Bool { flight == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("飞机") {
                    Picker("选择飞机", selection: $selectedAircraftId) {
                        Text("请选择").tag(nil as UUID?)
                        ForEach(store.aircraft) { a in
                            Text(a.name).tag(a.id as UUID?)
                        }
                    }
                    .disabled(store.aircraft.isEmpty)
                }

                Section("时间与时长") {
                    DatePicker("起飞时间", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                    TextField("飞行时长(秒)", text: $durationSeconds)
                        .keyboardType(.numberPad)
                }

                Section("地点") {
                    TextField("地址(选填)", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("地图选点") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("点击地图设置飞行位置")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        MapReader { proxy in
                            Map(position: $mapPosition, interactionModes: .all) {
                                if let coord = coordinate {
                                    Annotation("飞行地点", coordinate: coord) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                            .onTapGesture { position in
                                if let coord = proxy.convert(position, from: .local) {
                                    coordinate = coord
                                    mapPosition = .region(MKCoordinateRegion(
                                        center: coord,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    ))
                                    reverseGeocode(coord)
                                }
                            }
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Button {
                            locationFetcher.requestLocation()
                        } label: {
                            Label("使用当前定位", systemImage: "location.fill")
                        }
                        if coordinate != nil {
                            Button(role: .destructive) {
                                coordinate = nil
                            } label: {
                                Label("清除位置", systemImage: "xmark.circle")
                            }
                        }
                    }
                }

                Section("备注") {
                    TextField("备注", text: $remark, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isNew ? "添加飞行" : "编辑飞行")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: setupInitial)
            .onReceive(locationFetcher.$lastCoordinate) { newValue in
                guard let coord = newValue else { return }
                coordinate = coord
                mapPosition = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
                reverseGeocode(coord)
            }
        }
    }

    private var canSave: Bool {
        selectedAircraftId != nil &&
        Int(durationSeconds) != nil &&
        (Int(durationSeconds) ?? 0) >= 0
    }

    private func setupInitial() {
        if let f = flight {
            selectedAircraftId = f.aircraftId
            startAt = f.startAt
            durationSeconds = "\(f.durationSeconds)"
            address = f.address ?? ""
            remark = f.remark ?? ""
            coordinate = f.latitude != nil && f.longitude != nil
                ? CLLocationCoordinate2D(latitude: f.latitude!, longitude: f.longitude!)
                : nil
            if let c = coordinate {
                mapPosition = .region(MKCoordinateRegion(
                    center: c,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        } else if selectedAircraftId == nil, let first = store.aircraft.first {
            selectedAircraftId = first.id
        }
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            guard let place = placemarks?.first else { return }
            let parts = [place.thoroughfare, place.subThoroughfare, place.locality, place.administrativeArea]
                .compactMap { $0 }
            let newAddress = parts.isEmpty ? nil : parts.joined(separator: " ")
            DispatchQueue.main.async {
                if let newAddress, address.isEmpty {
                    address = newAddress
                }
            }
        }
    }

    private func save() {
        guard let aircraftId = selectedAircraftId,
              let sec = Int(durationSeconds), sec >= 0 else { return }

        if var f = flight {
            f.aircraftId = aircraftId
            f.startAt = startAt
            f.durationSeconds = sec
            f.address = address.isEmpty ? nil : address
            f.remark = remark.isEmpty ? nil : remark
            f.updatedAt = Date()
            if let c = coordinate {
                f.latitude = c.latitude
                f.longitude = c.longitude
            }
            store.updateFlight(f)
        } else {
            let new = FlightRecord(
                aircraftId: aircraftId,
                batteryIds: [],
                startAt: startAt,
                durationSeconds: sec,
                address: address.isEmpty ? nil : address,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude,
                remark: remark.isEmpty ? nil : remark
            )
            store.addFlight(new)
        }
        dismiss()
    }
}
