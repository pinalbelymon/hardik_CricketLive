import Foundation

// MARK: - Repository Result

/// Repository output that distinguishes fresh network data from offline cache.
struct RepositoryResult<Value: Sendable>: Sendable {
    let value: Value
    let lastUpdated: Date?
    let isFromCache: Bool
}

// MARK: - Cache Keys

enum CacheTTL {
    static let fixtures: TimeInterval = 60
    static let rankings: TimeInterval = 6 * 60 * 60
}

enum CacheKey {
    static func fixtures(startDate: Date, isBackward: Bool, timeZone: TimeZone) -> String {
        "fixtures-\(DateFormatters.cricketAustraliaDateString(from: startDate, timeZone: timeZone))-\(isBackward)"
    }

    static func rankings(format: CricketFormat, category: RankingCategory) -> String {
        "rankings-\(format.rawValue)-\(category.rawValue)"
    }

    static func scorecard(fixtureId: Int) -> String {
        "scorecard-\(fixtureId)"
    }
}

// MARK: - Background Fetch

/// Runs network and parsing off the main actor; view models apply results on `@MainActor`.
enum BackgroundFetch {
    static func perform<T: Sendable>(
        priority: TaskPriority = .utility,
        _ operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        try await Task.detached(priority: priority, operation: operation).value
    }
}

// MARK: - In-Flight Requests

/// Deduplicates concurrent repository requests on a detached task so MainActor view models do not deadlock.
actor InFlightRequestStore<Key: Hashable & Sendable, Value: Sendable> {
    private var tasks: [Key: Task<Value, Error>] = [:]

    func run(for key: Key, operation: @Sendable @escaping () async throws -> Value) async throws -> Value {
        if let existingTask = tasks[key] {
            return try await existingTask.value
        }

        let task = Task.detached(priority: .userInitiated) {
            try await operation()
        }
        tasks[key] = task

        do {
            let value = try await task.value
            tasks[key] = nil
            return value
        } catch {
            tasks[key] = nil
            throw error
        }
    }
}
