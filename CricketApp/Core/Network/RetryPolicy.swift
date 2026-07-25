import Foundation

// MARK: - Retry Policy

/// Small exponential backoff policy for transient network failures.
struct RetryPolicy: Sendable {
    let maxRetries: Int
    let baseDelayNanoseconds: UInt64

    static let standard = RetryPolicy(maxRetries: 2, baseDelayNanoseconds: 350_000_000)

    func delayNanoseconds(forAttempt attempt: Int) -> UInt64 {
        baseDelayNanoseconds * UInt64(max(1, attempt + 1))
    }

    func shouldRetry(statusCode: Int) -> Bool {
        [408, 429, 500, 502, 503, 504].contains(statusCode)
    }
}
