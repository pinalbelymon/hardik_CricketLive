import Foundation

// MARK: - Request Building

/// Converts endpoint descriptors into URLRequest values.
protocol RequestBuilding: Sendable {
    func makeRequest(from endpoint: Endpoint) throws -> URLRequest
}

struct RequestBuilder: RequestBuilding {
    func makeRequest(from endpoint: Endpoint) throws -> URLRequest {
        let url = endpoint.path.isEmpty ? endpoint.baseURL : endpoint.baseURL.appendingPathComponent(endpoint.path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }

        if endpoint.queryItems.isEmpty == false {
            components.queryItems = endpoint.queryItems
        }

        guard let requestURL = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL, timeoutInterval: endpoint.timeout)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        endpoint.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return request
    }
}
