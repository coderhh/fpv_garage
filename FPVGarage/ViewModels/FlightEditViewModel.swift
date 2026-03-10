import SwiftUI
import MapKit
import CoreLocation
import Combine

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
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

final class FlightEditViewModel: ObservableObject {
    let appState: AppState
    let flight: FlightRecord?

    @Published var selectedAircraftId: UUID?
    @Published var startAt = Date()
    @Published var durationSeconds = "0"
    @Published var address = ""
    @Published var remark = ""
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var mapPosition: MapCameraPosition = .region(FlightEditViewModel.defaultMapRegion)

    private let locationFetcher = CurrentLocationFetcher()
    private var cancellables = Set<AnyCancellable>()

    var isNew: Bool { flight == nil }
    var aircraftList: [Aircraft] { appState.aircraft }
    var canSave: Bool {
        selectedAircraftId != nil &&
        Int(durationSeconds) != nil &&
        (Int(durationSeconds) ?? 0) >= 0
    }

    static let defaultMapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9, longitude: 116.4),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    init(appState: AppState, flight: FlightRecord?) {
        self.appState = appState
        self.flight = flight

        locationFetcher.$lastCoordinate
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] coord in
                self?.setCoordinate(coord)
            }
            .store(in: &cancellables)
    }

    func setupInitial() {
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
                mapPosition = .region(MKCoordinateRegion(center: c, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
            }
        } else if selectedAircraftId == nil, let first = appState.aircraft.first {
            selectedAircraftId = first.id
        }
    }

    func setCoordinate(_ coord: CLLocationCoordinate2D) {
        coordinate = coord
        mapPosition = .region(MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
        reverseGeocode(coord)
    }

    func clearCoordinate() { coordinate = nil }

    func requestCurrentLocation() { locationFetcher.requestLocation() }

    func save() {
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
            appState.updateFlight(f)
        } else {
            let new = FlightRecord(
                aircraftId: aircraftId, batteryIds: [],
                startAt: startAt, durationSeconds: sec,
                address: address.isEmpty ? nil : address,
                latitude: coordinate?.latitude, longitude: coordinate?.longitude,
                remark: remark.isEmpty ? nil : remark
            )
            appState.addFlight(new)
        }
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self, let place = placemarks?.first else { return }
            let parts = [place.thoroughfare, place.subThoroughfare, place.locality, place.administrativeArea]
                .compactMap { $0 }
            let newAddress = parts.isEmpty ? nil : parts.joined(separator: " ")
            DispatchQueue.main.async {
                if let newAddress, self.address.isEmpty {
                    self.address = newAddress
                }
            }
        }
    }
}
