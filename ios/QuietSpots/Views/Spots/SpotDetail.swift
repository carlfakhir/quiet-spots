/*
Derived from Apple's SwiftUI Landmarks sample (LandmarkDetail.swift).
See LICENSE/LICENSE.txt for the sample's licensing information.

Abstract:
A view showing the details for a study spot: live noise level, weather, and recent reports.
*/

import SwiftUI

struct SpotDetail: View {
    @Environment(ModelData.self) var modelData
    @Environment(AuthStore.self) var auth
    var spot: Spot

    @State private var details: SpotDetails?
    @State private var loadError: String?
    @State private var showMeasure = false
    @State private var showSignIn = false

    var body: some View {
        ScrollView {
            MapView(coordinate: spot.locationCoordinate)
                .frame(height: 300)

            CategoryBadge(category: spot.category, size: 120, tint: currentLevel.color)
                .offset(y: -60)
                .padding(.bottom, -60)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(spot.name)
                            .font(.title)
                        FavoriteButton(isSet: Binding(
                            get: { modelData.isFavorite(spot) },
                            set: { _ in modelData.toggleFavorite(spot) }
                        ))
                    }

                    HStack {
                        Text(spot.building)
                        Spacer()
                        Text(spot.area)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                conditions

                Button {
                    if auth.isSignedIn { showMeasure = true } else { showSignIn = true }
                } label: {
                    Label("Measure noise here", systemImage: "waveform.badge.mic")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("spot.measure")

                Divider()

                Text("About this spot")
                    .font(.title2)
                Text(spot.description)

                Divider()

                reportsSection
            }
            .padding()
        }
        .navigationTitle(spot.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .onAppear { Analytics.log("screen_view", ["screen": "spot_detail", "spot_id": "\(spot.id)"]) }
        .sheet(isPresented: $showMeasure) {
            MeasureView(spot: spot) { Task { await load() } }
        }
        .sheet(isPresented: $showSignIn) {
            NavigationStack {
                SignInView()
                    .navigationTitle("Sign in to measure")
                    .toolbar { Button("Close") { showSignIn = false } }
            }
            .onChange(of: auth.isSignedIn) { _, signedIn in
                if signedIn {
                    showSignIn = false
                    showMeasure = true
                }
            }
        }
    }

    private var currentLevel: NoiseLevel { details?.level ?? spot.noiseLevel }

    private var conditions: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Right now").font(.caption).foregroundStyle(.secondary)
                if let db = details?.avgDb ?? spot.avgDb {
                    Text("\(Int(db.rounded())) dB")
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(currentLevel.color)
                } else {
                    Text("–").font(.title.bold())
                }
                Text(currentLevel.label).font(.subheadline)
                if let details, details.recentReports > 0 {
                    Text("^[\(details.recentReports) report](inflect: true) in the last 2 hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let weather = details?.weather {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Outside").font(.caption).foregroundStyle(.secondary)
                    Label("\(Int(weather.tempC.rounded()))°C", systemImage: weather.symbol)
                        .font(.title2)
                        .symbolRenderingMode(.multicolor)
                    Text(weather.weatherDesc).font(.subheadline)
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var reportsSection: some View {
        Text("Recent reports")
            .font(.title2)
        if let loadError {
            Label(loadError, systemImage: "wifi.exclamationmark").foregroundStyle(.secondary)
        } else if let details {
            if details.reports.isEmpty {
                Text("No one has measured this spot yet. Be the first.")
                    .foregroundStyle(.secondary)
            }
            ForEach(details.reports) { report in
                ReportRow(report: report) {
                    Task { await delete(report) }
                }
            }
        } else {
            ProgressView()
        }
    }

    private func load() async {
        do {
            details = try await APIClient.shared.get("spots/\(spot.id)")
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func delete(_ report: Report) async {
        do {
            try await APIClient.shared.delete("reports/\(report.id)")
            Analytics.log("report_deleted", ["spot_id": "\(spot.id)"])
            await load()
            await modelData.refresh()
        } catch {
            auth.handleUnauthorized(error)
            loadError = error.localizedDescription
        }
    }
}

struct ReportRow: View {
    var report: Report
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Text("\(Int(report.db.rounded()))")
                .font(.headline.monospacedDigit())
                .frame(width: 44, height: 44)
                .background(NoiseLevel(db: report.db).color.opacity(0.2), in: Circle())
                .foregroundStyle(NoiseLevel(db: report.db).color)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(report.mine ? String(localized: "You") : report.username).bold()
                    if let vote = report.vote {
                        Label(vote.label, systemImage: vote.symbol)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let note = report.note {
                    Text(note)
                }
                HStack(spacing: 8) {
                    Text(RelativeTime.string(from: report.createdAt))
                    if let distance = report.distanceM, distance < 150 {
                        Label("On site", systemImage: "checkmark.seal.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if report.mine {
                Menu {
                    Button("Delete report", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis").padding(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let modelData = ModelData()
    return NavigationStack {
        SpotDetail(spot: modelData.spots[0])
    }
    .environment(modelData)
    .environment(AuthStore())
}
