import Foundation

// MARK: - API Error

/// User-presentable network and decoding failures.
enum APIError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case statusCode(Int)
    case decoding(Error)
    case transport(Error)
    case emptyData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The request URL could not be created."
        case .invalidResponse:
            "The server returned an invalid response."
        case let .statusCode(code):
            "The server returned status code \(code)."
        case let .decoding(error):
            "The response could not be decoded. \(error.localizedDescription)"
        case let .transport(error):
            error.localizedDescription
        case .emptyData:
            "The server returned no data."
        }
    }
}
