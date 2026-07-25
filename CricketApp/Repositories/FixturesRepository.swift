import Foundation

// MARK: - Fixtures Repository Protocol

/// Provides fixture groups to ViewModels without exposing provider APIs.
protocol FixturesRepositoryProtocol: Sendable {
    func liveMatches() async throws -> RepositoryResult<[Match]>
    func upcomingMatches(from date: Date) async throws -> RepositoryResult<[Match]>
    func previousMatches(from date: Date) async throws -> RepositoryResult<[Match]>
}

// MARK: - Fixtures Repository

final class FixturesRepository: FixturesRepositoryProtocol, @unchecked Sendable {
    private let cricketService: CricketAUServiceProtocol
    private let cache = MemoryCache<String, [Match]>()
    private let diskCache = DiskCacheStore.shared
    private let inFlightStore = InFlightRequestStore<String, [Match]>()

    init(cricketService: CricketAUServiceProtocol) {
        self.cricketService = cricketService
    }

    func liveMatches() async throws -> RepositoryResult<[Match]> {
        let result = try await upcomingMatches(from: .now)
        let live = result.value.filter { $0.shouldPollLiveUpdates || $0.state == .live }
        return RepositoryResult(value: live, lastUpdated: result.lastUpdated, isFromCache: result.isFromCache)
    }

    func upcomingMatches(from date: Date = .now) async throws -> RepositoryResult<[Match]> {
        try await loadFixtures(startDate: date, isBackward: false) { matches in
            matches.filter { $0.state != .completed && $0.isCompleted == false }
        }
    }

    func previousMatches(from date: Date = .now) async throws -> RepositoryResult<[Match]> {
        try await loadFixtures(startDate: date, isBackward: true) { $0 }
    }

    private func loadFixtures(
        startDate: Date,
        isBackward: Bool,
        transform: @Sendable ([Match]) -> [Match]
    ) async throws -> RepositoryResult<[Match]> {
        let cacheKey = CacheKey.fixtures(startDate: startDate, isBackward: isBackward, timeZone: .current)

        if let cached = await cache.value(for: cacheKey) {
            return RepositoryResult(value: transform(cached), lastUpdated: .now, isFromCache: false)
        }

        do {
            let matches = try await fetchFixtures(startDate: startDate, isBackward: isBackward, cacheKey: cacheKey)
            await cache.set(matches, for: cacheKey, ttl: CacheTTL.fixtures)
            try await diskCache.save(matches, key: cacheKey)
            return RepositoryResult(value: transform(matches), lastUpdated: .now, isFromCache: false)
        } catch {
            if let offline = await diskCache.load([Match].self, key: cacheKey) {
                return RepositoryResult(value: transform(offline.value), lastUpdated: offline.updatedAt, isFromCache: true)
            }
            throw error
        }
    }

    private func fetchFixtures(startDate: Date, isBackward: Bool, cacheKey: String) async throws -> [Match] {
        try await inFlightStore.run(for: cacheKey) { [cricketService] in
            try await cricketService.fixtures(startDate: startDate, isBackward: isBackward, timeZone: .current)
        }
    }
}
