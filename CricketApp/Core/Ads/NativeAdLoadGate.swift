import Foundation

// MARK: - Native Ad Load Gate

/// Limits concurrent native ad network requests so list scrolling stays smooth.
/// Cancellation-safe: scrolled-away cells do not permanently occupy a slot.
@MainActor
final class NativeAdLoadGate {
    static let shared = NativeAdLoadGate()

    private let maxConcurrent: Int
    private var activeCount = 0
    private var waiters: [UUID: CheckedContinuation<Void, Never>] = [:]

    init(maxConcurrent: Int = 2) {
        self.maxConcurrent = max(1, maxConcurrent)
    }

    /// Returns `true` when a slot was taken. Call `release()` only after a successful acquire.
    @discardableResult
    func acquire() async -> Bool {
        if Task.isCancelled { return false }

        if activeCount < maxConcurrent {
            activeCount += 1
            return true
        }

        let id = UUID()
        await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                waiters[id] = continuation
            }
        } onCancel: {
            Task { @MainActor in
                if let continuation = waiters.removeValue(forKey: id) {
                    continuation.resume()
                }
            }
        }

        // Cancelled while queued — do not take a slot.
        if Task.isCancelled { return false }

        activeCount += 1
        return true
    }

    func release() {
        activeCount = max(0, activeCount - 1)
        guard let id = waiters.keys.first,
              let next = waiters.removeValue(forKey: id) else { return }
        next.resume()
    }
}
