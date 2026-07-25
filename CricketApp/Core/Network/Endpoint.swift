import Foundation

// MARK: - Endpoint

/// Fully describes an HTTP request without coupling callers to URLSession.
struct Endpoint: Sendable {
    let baseURL: URL
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let body: Data?
    let timeout: TimeInterval

    init(
        baseURL: URL,
        path: String = "",
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 20
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }
}
