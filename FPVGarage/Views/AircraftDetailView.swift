import SwiftUI

struct AircraftDetailView: View {
    @EnvironmentObject var appState: AppState
    let aircraft: Aircraft
    @State private var showEdit = false

    private var imageURL: URL? {
        appState.imageStorage.imageURL(aircraftId: aircraft.id, fileName: aircraft.imageFileName)
    }

    private var setup: AircraftSetup {
        aircraft.setupOrEmpty
    }

    /// The battery used on this aircraft's most recent flight. There is no direct
    /// aircraft→battery link in the data model, so the latest flight record is the
    /// only real association. Returns nil when the aircraft has no logged battery.
    private var linkedBattery: Battery? {
        AircraftBatteryResolver.mostRecentBattery(
            for: aircraft,
            flightRecords: appState.flightRecords,
            batteries: appState.batteries
        )
    }

    private var twrResult: ThrustToWeightResult? {
        ThrustToWeightCalculator.calculate(aircraft: aircraft, linkedBattery: linkedBattery)
    }

    private var compatibilityWarnings: [CompatibilityWarning] {
        CompatibilityChecker.check(aircraft: aircraft, linkedBattery: linkedBattery)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    if let url = imageURL,
                       let data = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray.opacity(0.15))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "cube.box")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(aircraft.name)
                            .font(.title2)
                            .bold()
                        if let model = aircraft.model, !model.isEmpty {
                            Text(model)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let remark = aircraft.remark, !remark.isEmpty {
                            Text(remark)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }
                    Spacer()
                }

                // TWR gauge (shown only when enough data is present)
                if let twr = twrResult {
                    TWRGaugeView(result: twr)
                }

                // Compatibility warnings (only when there are inputs to actually check,
                // otherwise "No issues detected" would be misleading)
                if hasCompatibilityData {
                    CompatibilityWarningsView(warnings: compatibilityWarnings)
                }

                if !setup.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detailed Setup")
                            .font(.headline)
                        detailRow(label: "Frame", value: setup.frame)
                        detailRow(label: "Motor", value: setup.motor)
                        detailRow(label: "ESC", value: setup.esc)
                        detailRow(label: "Flight Controller", value: setup.flightController)
                        detailRow(label: "VTX", value: setup.vtx)
                        detailRow(label: "Camera", value: setup.camera)
                        detailRow(label: "Receiver", value: setup.receiver)
                        detailRow(label: "Propeller", value: setup.propeller)
                        detailRow(label: "Other", value: setup.other)
                    }
                    .padding()
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if hasPerformanceData {
                    performanceSection
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Metadata")
                        .font(.headline)
                    detailRow(label: "Created", value: DateFormatter.localizedString(from: aircraft.createdAt, dateStyle: .medium, timeStyle: .short))
                    detailRow(label: "Last Updated", value: DateFormatter.localizedString(from: aircraft.updatedAt, dateStyle: .medium, timeStyle: .short))
                }
                .padding()
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationTitle("Aircraft Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            AircraftEditView(appState: appState, aircraft: aircraft)
        }
    }

    private var hasPerformanceData: Bool {
        aircraft.flightStyle != nil
        || aircraft.motorKv != nil
        || aircraft.motorThrustGrams != nil
        || aircraft.allUpWeightGrams != nil
        || aircraft.escCurrentRating != nil
        || aircraft.motorMaxCurrentAmps != nil
    }

    /// True when at least one compatibility rule has the inputs it needs to run.
    private var hasCompatibilityData: Bool {
        let escRule = aircraft.escCurrentRating != nil && aircraft.motorMaxCurrentAmps != nil
        let kvRule = aircraft.motorKv != nil && (aircraft.batteryCellCount != nil || linkedBattery?.cells != nil)
        let cRule = aircraft.motorMaxCurrentAmps != nil && linkedBattery?.cRating != nil
        return escRule || kvRule || cRule
    }

    @ViewBuilder
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Performance Data")
                .font(.headline)
            detailRow(label: "Flight Style", value: aircraft.flightStyle?.displayName)
            detailRow(label: "Pilot Level", value: aircraft.pilotSkillLevel?.displayName)
            detailRow(label: "Frame Size", value: aircraft.frameSizeInch.map { String(format: "%.0f\"", $0) })
            detailRow(label: "Motor Model", value: aircraft.motorModel)
            detailRow(label: "Motor KV", value: aircraft.motorKv.map { "\($0) KV" })
            detailRow(label: "Motor Thrust", value: aircraft.motorThrustGrams.map { "\($0) g/motor" })
            detailRow(label: "Thrust Source", value: aircraft.motorThrustDataSource?.displayName)
            detailRow(label: "Prop Size", value: aircraft.propSize)
            detailRow(label: "Cell Count", value: aircraft.batteryCellCount.map { "\($0)S" })
            detailRow(label: "All-Up Weight", value: aircraft.allUpWeightGrams.map { "\($0) g" })
            detailRow(label: "ESC Rating", value: aircraft.escCurrentRating.map { "\($0) A" })
            detailRow(label: "Motor Max Current", value: aircraft.motorMaxCurrentAmps.map { "\($0) A" })
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func detailRow(label: LocalizedStringKey, value: String?) -> some View {
        if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.body)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
