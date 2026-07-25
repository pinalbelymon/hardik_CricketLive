import Foundation

// MARK: - Rankings Repository Protocol

/// Provides rankings by format and category.
protocol RankingsRepositoryProtocol: Sendable {
    func rankings(format: CricketFormat, category: RankingCategory) async throws -> RepositoryResult<[RankingEntry]>
}

// MARK: - Rankings Repository

final class RankingsRepository: RankingsRepositoryProtocol, @unchecked Sendable {
    private let service: RankingsServiceProtocol
    private let cache = MemoryCache<String, [RankingEntry]>()
    private let diskCache = DiskCacheStore.shared
    private let inFlightStore = InFlightRequestStore<String, [RankingEntry]>()

    init(service: RankingsServiceProtocol) {
        self.service = service
    }

    func rankings(format: CricketFormat, category: RankingCategory) async throws -> RepositoryResult<[RankingEntry]> {
        let cacheKey = CacheKey.rankings(format: format, category: category)

        if let cached = await cache.value(for: cacheKey) {
            return RepositoryResult(value: cached, lastUpdated: .now, isFromCache: false)
        }

        do {
            let rankings = try await fetchRankings(format: format, category: category, cacheKey: cacheKey)
            await cache.set(rankings, for: cacheKey, ttl: CacheTTL.rankings)
            try await diskCache.save(rankings, key: cacheKey)
            return RepositoryResult(value: rankings, lastUpdated: .now, isFromCache: false)
        } catch {
            if let offline = await diskCache.load([RankingEntry].self, key: cacheKey) {
                return RepositoryResult(value: offline.value, lastUpdated: offline.updatedAt, isFromCache: true)
            }
            throw error
        }
    }

    private func fetchRankings(format: CricketFormat, category: RankingCategory, cacheKey: String) async throws -> [RankingEntry] {
        try await inFlightStore.run(for: cacheKey) { [service] in
            try await service.rankings(format: format, category: category)
        }
    }
}
