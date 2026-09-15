/*
Abstract:
Measures noise for a few seconds with the microphone, then posts a report for a spot.
*/

import SwiftUI
import CoreLocation

struct MeasureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ModelData.self) private var modelData
    @Environment(AuthStore.self) private var auth

    var spot: Spot
    var onPosted: () -> Void

    @State private var meter = NoiseMeter()
    @State private var locator = LocationProvider()
    @State private var vote: Vote?
    @State private var note = ""
    @State private var isPosting = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    reading
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                } footer: {
                    Text("The microphone is only used to measure loudness. No audio is recorded or uploaded.")
                }

                if meter.state == .finished {
                    Section("How does it feel?") {
                        Picker("Vote", selection: $vote) {
                            Text("Skip").tag(Vote?.none)
                            ForEach(Vote.allCases) { vote in
                                Label(vote.label, systemImage: vote.symbol).tag(Vote?.some(vote))
                            }
                        }
                        .pickerStyle(.segmented)
                        TextField("Note (optional)", text: $note)
                    }

                    Section {
                        locationRow
                    }
                }

                if let error {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle(spot.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post report") { Task { await post() } }
                        .disabled(meter.state != .finished || isPosting)
                        .accessibilityIdentifier("measure.post")
                }
            }
            .task {
                locator.request()
                await meter.start()
            }
            .onDisappear { meter.stop() }
        }
    }

    @ViewBuilder
    private var reading: some View {
        switch meter.state {
        case .denied:
            ContentUnavailableView {
                Label("Microphone access is off", systemImage: "mic.slash")
            } description: {
                Text("Turn on microphone access for Quiet Spots in Settings to measure noise.")
            } actions: {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            }
        case .failed(let message):
            ContentUnavailableView("Couldn't measure", systemImage: "exclamationmark.triangle", description: Text(message))
        default:
            let db = meter.state == .finished ? (meter.averageDb ?? 0) : meter.currentDb
            let level = NoiseLevel(db: db)
            VStack(spacing: 12) {
                Gauge(value: min(db, 100), in: 0...100) {
                    Image(systemName: "waveform")
                } currentValueLabel: {
                    Text("\(Int(db.rounded()))")
                        .contentTransition(.numericText())
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(level.color)
                .scaleEffect(2.2)
                .frame(width: 140, height: 140)
                .animation(.easeOut(duration: 0.15), value: Int(db))

                Text(meter.state == .finished ? level.label : "Measuring…")
                    .font(.title3.bold())
                    .foregroundStyle(meter.state == .finished ? level.color : .primary)

                if meter.state == .measuring {
                    ProgressView(value: meter.progress)
                        .frame(maxWidth: 200)
                    Text("Hold still for \(Int(meter.duration)) seconds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if meter.state == .finished {
                    Text("Average \(Int((meter.averageDb ?? 0).rounded())) dB · Peak \(Int((meter.peakDb ?? 0).rounded())) dB")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Measure again") { Task { await meter.start() } }
                        .font(.caption)
                }
            }
        }
    }

    @ViewBuilder
    private var locationRow: some View {
        if let location = locator.location {
            let meters = Int(location.distance(from: spot.location).rounded())
            Label {
                Text(meters < 150 ? "You're at this spot (\(meters) m away)" : "You're \(meters) m from this spot")
            } icon: {
                Image(systemName: meters < 150 ? "location.fill" : "location.slash")
                    .foregroundStyle(meters < 150 ? .green : .orange)
            }
        } else if locator.isDenied {
            Label("Location is off, so this report won't show how close you were", systemImage: "location.slash")
                .foregroundStyle(.secondary)
        } else {
            Label("Finding your location…", systemImage: "location")
                .foregroundStyle(.secondary)
        }
    }

    private func post() async {
        guard let db = meter.averageDb else { return }
        isPosting = true
        defer { isPosting = false }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let report = NewReport(
            db: (db * 10).rounded() / 10,
            vote: vote,
            note: trimmed.isEmpty ? nil : trimmed,
            lat: locator.location?.coordinate.latitude,
            lon: locator.location?.coordinate.longitude)
        do {
            try await APIClient.shared.post("spots/\(spot.id)/reports", body: report)
            Analytics.log("report_posted", ["spot_id": "\(spot.id)", "db": "\(Int(db))", "has_location": "\(locator.location != nil)"])
            await modelData.refresh()
            onPosted()
            dismiss()
        } catch {
            auth.handleUnauthorized(error)
            self.error = error.localizedDescription
        }
    }
}
