/*
Abstract:
Tracks who is signed in and keeps their token in the Keychain.
*/

import Foundation

@Observable
class AuthStore {
    private(set) var username: String?
    var isSignedIn: Bool { username != nil }

    private struct Credentials: Encodable {
        var username: String
        var password: String
    }

    private struct AuthResponse: Decodable {
        struct User: Decodable { var id: Int; var username: String }
        var token: String
        var user: User
    }

    init() {
        if let token = Keychain.read("token"), let name = Keychain.read("username") {
            APIClient.shared.token = token
            username = name
        }
    }

    func signIn(username: String, password: String) async throws {
        try await authenticate(path: "auth/login", username: username, password: password)
    }

    func createAccount(username: String, password: String) async throws {
        try await authenticate(path: "auth/register", username: username, password: password)
    }

    func signOut() {
        Keychain.delete("token")
        Keychain.delete("username")
        APIClient.shared.token = nil
        username = nil
    }

    /// Call when the server rejects the token (for example, it expired).
    func handleUnauthorized(_ error: Error) {
        if (error as? APIError)?.status == 401 { signOut() }
    }

    private func authenticate(path: String, username: String, password: String) async throws {
        let response: AuthResponse = try await APIClient.shared.post(
            path, body: Credentials(username: username.trimmingCharacters(in: .whitespaces), password: password))
        Keychain.save(response.token, for: "token")
        Keychain.save(response.user.username, for: "username")
        APIClient.shared.token = response.token
        self.username = response.user.username
    }
}
