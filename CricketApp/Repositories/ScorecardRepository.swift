import Foundation

// MARK: - Scorecard Repository Protocol

/// Provides scorecard data for a match.
protocol ScorecardRepositoryProtocol: Sendable {
    func scorecard(fixtureId: Int, isLive: Bool) async throws -> RepositoryResult<Scorecard>
    func matchSummary(fixtureId: Int) async throws -> RepositoryResult<Match?>
}

// MARK: - Scorecard Repository

final class ScorecardRepository: ScorecardRepositoryProtocol, @unchecked Sendable {
    private let cricketService: CricketAUServiceProtocol
    private let diskCache = DiskCacheStore.shared
    private let scorecardInFlight = InFlightRequestStore<Int, Scorecard>()
    private let summaryInFlight = InFlightRequestStore<Int, Match?>()

    init(cricketService: CricketAUServiceProtocol) {
        self.cricketService = cricketService
    }

    func scorecard(fixtureId: Int, isLive: Bool = false) async throws -> RepositoryResult<Scorecard> {
        do {
            let scorecard = try await fetchScorecard(fixtureId: fixtureId)
            if isLive == false {
                try await diskCache.save(scorecard, key: CacheKey.scorecard(fixtureId: fixtureId))
            }
            return RepositoryResult(value: scorecard, lastUpdated: .now, isFromCache: false)
        } catch {
            if isLive == false,
               let offline = await diskCache.load(Scorecard.self, key: CacheKey.scorecard(fixtureId: fixtureId)) {
                return RepositoryResult(value: offline.value, lastUpdated: offline.updatedAt, isFromCache: true)
            }
            throw error
        }
    }

    func matchSummary(fixtureId: Int) async throws -> RepositoryResult<Match?> {
        do {
            let match = try await fetchMatchSummary(fixtureId: fixtureId)
            return RepositoryResult(value: match, lastUpdated: .now, isFromCache: false)
        } catch {
            if let offline = await diskCache.load(Scorecard.self, key: CacheKey.scorecard(fixtureId: fixtureId)),
               let match = offlineMatch(from: offline.value, fixtureId: fixtureId) {
                return RepositoryResult(value: match, lastUpdated: offline.updatedAt, isFromCache: true)
            }
            throw error
        }
    }

    private func fetchScorecard(fixtureId: Int) async throws -> Scorecard {
        try await scorecardInFlight.run(for: fixtureId) { [cricketService] in
            try await cricketService.scorecard(fixtureId: fixtureId)
        }
    }

    private func fetchMatchSummary(fixtureId: Int) async throws -> Match? {
        try await summaryInFlight.run(for: fixtureId) { [cricketService] in
            try await cricketService.matchSummary(fixtureId: fixtureId)
        }
    }

    private func offlineMatch(from scorecard: Scorecard, fixtureId: Int) -> Match? {
        Match(
            id: fixtureId,
            fixtureId: fixtureId,
            title: scorecard.matchSummary,
            competition: "Cricket",
            competitionImageURL: nil,
            venue: "Venue unavailable offline",
            startDate: nil,
            fixtureDate: nil,
            state: .completed,
            homeTeam: Team(name: scorecard.battingTeamName ?? "Home", shortName: "HOM"),
            awayTeam: Team(name: scorecard.bowlingTeamName ?? "Away", shortName: "AWY"),
            toss: nil,
            status: scorecard.matchSummary,
            gameStatus: "Offline",
            isCompleted: true,
            isLive: false,
            target: nil,
            currentRunRate: scorecard.currentRunRate,
            requiredRunRate: scorecard.requiredRunRate,
            winningProbability: nil,
            partnership: scorecard.currentPartnership.map { "\($0.batters): \($0.runs)" },
            lastWicket: scorecard.lastWicket.map { "\($0.score) \($0.playerName)" },
            battingTeamName: scorecard.battingTeamName,
            bowlingTeamName: scorecard.bowlingTeamName,
            currentInningNumber: 1,
            recentBalls: []
        )
    }
}
