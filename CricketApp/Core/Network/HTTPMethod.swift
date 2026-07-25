import Foundation

// MARK: - HTTP Method

/// Supported HTTP verbs for the app network layer.
enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
}
