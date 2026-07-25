import Foundation

// MARK: - API Client

/// Async/await URLSession client with retries, validation, cancellation, and generic decoding.
protocol APIClientProtocol: Sendable {
    func send<T: Decodable>(_ endpoint: Endpoint, decoder: JSONDecoder) async throws -> T
    func data(for endpoint: Endpoint) async throws -> Data
}

final class APIClient: APIClientProtocol, @unchecked Sendable {
    private let session: URLSession
    private let requestBuilder: RequestBuilding
    private let logger: NetworkLogging
    private let retryPolicy: RetryPolicy

    init(
        session: URLSession = APIClient.makeDefaultSession(),
        requestBuilder: RequestBuilding = RequestBuilder(),
        logger: NetworkLogging = NetworkLogger(),
        retryPolicy: RetryPolicy = .standard
    ) {
        self.session = session
        self.requestBuilder = requestBuilder
        self.logger = logger
        self.retryPolicy = retryPolicy
    }

    private static func makeDefaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }

    func send<T: Decodable>(_ endpoint: Endpoint, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        let responseData = try await data(for: endpoint)

        do {
            let decoded = try decoder.decode(T.self, from: responseData)
            #if DEBUG
            logger.logDecodedModel(String(describing: T.self))
            #endif
            return decoded
        } catch {
            #if DEBUG
            logger.logDecodingFailure(
                model: String(describing: T.self),
                response: String(data: responseData, encoding: .utf8) ?? "Unable to decode response body",
                error: error
            )
            #endif
            throw APIError.decoding(error)
        }
    }

    func data(for endpoint: Endpoint) async throws -> Data {
        var lastError: Error?

        for attempt in 0...retryPolicy.maxRetries {
            do {
                return try await perform(endpoint)
            } catch let error as APIError {
                lastError = error
                guard shouldRetry(error), attempt < retryPolicy.maxRetries else {
                    throw error
                }
                try await Task.sleep(nanoseconds: retryPolicy.delayNanoseconds(forAttempt: attempt))
            } catch {
                lastError = error
                guard attempt < retryPolicy.maxRetries else {
                    throw APIError.transport(error)
                }
                try await Task.sleep(nanoseconds: retryPolicy.delayNanoseconds(forAttempt: attempt))
            }
        }

        throw lastError.map(APIError.transport) ?? APIError.emptyData
    }

    private func perform(_ endpoint: Endpoint) async throws -> Data {
        let request = try requestBuilder.makeRequest(from: endpoint)
        logger.log(request: request)
        let startedAt = CFAbsoluteTimeGetCurrent()

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            let duration = CFAbsoluteTimeGetCurrent() - startedAt
            logger.log(response: httpResponse, byteCount: data.count, duration: duration)
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.statusCode(httpResponse.statusCode)
            }

            return data
        } catch let error as APIError {
            logger.log(error: error)
            throw error
        } catch {
            logger.log(error: error)
            throw APIError.transport(error)
        }
    }

    private func shouldRetry(_ error: APIError) -> Bool {
        switch error {
        case let .statusCode(code):
            retryPolicy.shouldRetry(statusCode: code)
        case let .transport(underlying):
            !isNonRetryableTransportError(underlying)
        case .invalidResponse:
            true
        case .decoding, .emptyData, .invalidURL:
            false
        }
    }

    private func isNonRetryableTransportError(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else {
            return false
        }

        return [
            NSURLErrorTimedOut,
            NSURLErrorCannotFindHost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorNotConnectedToInternet
        ].contains(nsError.code)
    }
}
