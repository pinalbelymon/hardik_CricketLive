import Foundation
import OSLog

// MARK: - Network Logging

/// Logs network traffic in debug builds without leaking response bodies in release builds.
protocol NetworkLogging: Sendable {
    func log(request: URLRequest)
    func log(response: HTTPURLResponse, byteCount: Int, duration: TimeInterval)
    func log(error: Error)
    func logDecodedModel(_ modelName: String)
    func logDecodingFailure(model: String, response: String, error: Error)
}

struct NetworkLogger: NetworkLogging {
    private let logger = Logger(subsystem: AppConstants.bundleIdentifier, category: "Network")

    func log(request: URLRequest) {
        #if DEBUG
        logger.debug("Request \(request.httpMethod ?? "GET", privacy: .public) \(request.url?.absoluteString ?? "unknown", privacy: .public)")
        if let headers = request.allHTTPHeaderFields, headers.isEmpty == false {
            logger.debug("Headers \(headers.description, privacy: .public)")
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            logger.debug("Body \(bodyString, privacy: .public)")
        }
        #endif
    }

    func log(response: HTTPURLResponse, byteCount: Int, duration: TimeInterval = 0) {
        #if DEBUG
        logger.debug("Response HTTP \(response.statusCode, privacy: .public) \(byteCount, privacy: .public) bytes in \(duration, privacy: .public)s")
        #endif
    }

    func log(error: Error) {
        #if DEBUG
        logger.error("\(error.localizedDescription, privacy: .public)")
        #endif
    }

    func logDecodedModel(_ modelName: String) {
        #if DEBUG
        logger.debug("Decoded \(modelName, privacy: .public)")
        #endif
    }

    func logDecodingFailure(model: String, response: String, error: Error) {
        #if DEBUG
        logger.error("Decoding failed for \(model, privacy: .public): \(error.localizedDescription, privacy: .public)")
        logger.error("Response body \(response, privacy: .public)")
        #endif
    }
}
