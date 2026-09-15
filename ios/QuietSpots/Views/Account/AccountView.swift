/*
Abstract:
Shows the signed-in user's profile and recent reports, or the sign-in form.
*/

import SwiftUI

struct AccountView: View {
    @Environment(AuthStore.self) var auth
    @State private var profile: Profile?
    @State private var error: String?

    struct Profile: Decodable {
        struct RecentReport: Decodable, Identifiable {
            var id: Int
            var spotName: String
            var db: Double
            var vote: String?
            var createdAt: String
        }
        var username: String
        var reports: Int
        var spotsMeasured: Int
        var recent: [RecentReport]
    }

    var body: some View {
        NavigationStack {
            Group {
                if auth.isSignedIn {
                    signedIn
                } else {
                    SignInView()
                }
            }
            .navigationTitle("Account")
        }
    }

    private var signedIn: some View {
        List {
            Section {
                LabeledContent("Username", value: auth.username ?? "")
                if let profile {
                    LabeledContent("Reports posted", value: "\(profile.reports)")
                    LabeledContent("Spots measured", value: "\(profile.spotsMeasured)")
                }
            }

            if let profile, !profile.recent.isEmpty {
                Section("Your recent reports") {
                    ForEach(profile.recent) { report in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(report.spotName)
                                Text(RelativeTime.string(from: report.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(Int(report.db.rounded())) dB")
                                .monospacedDigit()
                                .foregroundStyle(NoiseLevel(db: report.db).color)
                        }
                    }
                }
            }

            AlertsSection()

            if let error {
                Section { Text(error).foregroundStyle(.red) }
            }

            Section {
                Button("Sign out", role: .destructive) { auth.signOut() }
            }
        }
        .task { await loadProfile() }
        .refreshable { await loadProfile() }
    }

    private func loadProfile() async {
        do {
            profile = try await APIClient.shared.get("me")
            error = nil
        } catch {
            auth.handleUnauthorized(error)
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    AccountView()
        .environment(AuthStore())
        .environment(ModelData())
}
