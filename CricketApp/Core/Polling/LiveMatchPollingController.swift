import Foundation

// MARK: - Live Match Polling Controller

/// Manages independent polling loops off the main thread; refresh handlers hop to `@MainActor` for UI updates.
final class LiveMatchPollingController: @unchecked Sendable {
    private var scorecardTask: Task<Void, Never>?
    private var commentaryTask: Task<Void, Never>?
    private var isRunning = false
    private let lock = NSLock()

    func start(
        isLive: @escaping @Sendable () async -> Bool,
        shouldStop: @escaping @Sendable () async -> Bool,
        isAppActive: @escaping @Sendable () async -> Bool,
        refreshScorecard: @escaping @Sendable () async -> Void,
        refreshCommentary: @escaping @Sendable () async -> Void
    ) {
        lock.lock()
        guard isRunning == false else {
            lock.unlock()
            return
        }
        isRunning = true
        lock.unlock()

        scorecardTask = Task.detached(priority: .utility) { [weak self] in
            while !Task.isCancelled {
                guard await isAppActive(), await isLive(), await shouldStop() == false else {
                    if await shouldStop() {
                        self?.stop()
                        return
                    }
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }

                await refreshScorecard()
                try? await Task.sleep(nanoseconds: 15_000_000_000)
            }
        }

        commentaryTask = Task.detached(priority: .utility) { [weak self] in
            while !Task.isCancelled {
                guard await isAppActive(), await isLive(), await shouldStop() == false else {
                    if await shouldStop() {
                        self?.stop()
                        return
                    }
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    continue
                }

                await refreshCommentary()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    func stop() {
        lock.lock()
        scorecardTask?.cancel()
        commentaryTask?.cancel()
        scorecardTask = nil
        commentaryTask = nil
        isRunning = false
        lock.unlock()
    }
}
