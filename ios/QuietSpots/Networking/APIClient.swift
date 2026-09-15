/*
Abstract:
A small async/await client for the Quiet Spots REST API.
*/

import Foundation

enum APIConfig {
    #if targetEnvironment(simulator)
    // The Simulator shares the Mac's network, so it can reach `npx wrangler dev` directly.
    static let baseURL = URL(string: "http://localhost:8787")!
    #else
    static let baseURL = URL(string: "https://quiet-spots-api.cfakhir3.workers.dev")!
    #endif
}

struct APIError: LocalizedError {
    var status: Int
    var message: String
    var errorDescription: String? { message }
}

final class APIClient {
    static let shared = APIClient()

    /// Bearer token for the signed-in user, set by `AuthStore`.
    var token: String?

    private let session = URLSession(configuration: .default)
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    func get<Response: Decodable>(_ path: String) async throws -> Response {
        try decoder.decode(Response.self, from: await send(path, method: "GET", body: nil))
    }

    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        try decoder.decode(Response.self, from: await send(path, method: "POST", body: encoder.encode(body)))
    }

    /// For calls where the response body doesn't matter.
    func post<Body: Encodable>(_ path: String, body: Body) async throws {
        _ = try await send(path, method: "POST", body: encoder.encode(body))
    }

    func delete(_ path: String) async throws {
        _ = try await send(path, method: "DELETE", body: nil)
    }

    private func send(_ path: String, method: String, body: Data?) async throws -> Data {
        var request = URLRequest(url: APIConfig.baseURL.appending(path: path))
        request.httpMethod = method
        request.timeoutInterval = 15
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw APIError(status: status, message: message ?? "The server returned an error (\(status)).")
        }
        return data
    }
}
