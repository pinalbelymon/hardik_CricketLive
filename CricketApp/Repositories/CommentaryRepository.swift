import Foundation

// MARK: - Commentary Repository Protocol

/// Provides ball-by-ball commentary for a match.
protocol CommentaryRepositoryProtocol: Sendable {
    func comments(fixtureId: Int, inningNumber: Int, lastOverNumber: Int?) async throws -> RepositoryResult<[BallEvent]>
}

// MARK: - Commentary Repository

final class CommentaryRepository: CommentaryRepositoryProtocol, @unchecked Sendable {
    private let cricketService: CricketAUServiceProtocol
    private let inFlightStore = InFlightRequestStore<String, [BallEvent]>()

    init(cricketService: CricketAUServiceProtocol) {
        self.cricketService = cricketService
    }

    func comments(fixtureId: Int, inningNumber: Int = 1, lastOverNumber: Int? = nil) async throws -> RepositoryResult<[BallEvent]> {
        let key = "\(fixtureId)-\(inningNumber)-\(lastOverNumber ?? -1)"
        let events = try await fetchComments(key: key, fixtureId: fixtureId, inningNumber: inningNumber, lastOverNumber: lastOverNumber)
        return RepositoryResult(value: events, lastUpdated: .now, isFromCache: false)
    }

    private func fetchComments(key: String, fixtureId: Int, inningNumber: Int, lastOverNumber: Int?) async throws -> [BallEvent] {
        try await inFlightStore.run(for: key) { [cricketService] in
            try await cricketService.comments(
                fixtureId: fixtureId,
                inningNumber: inningNumber,
                overLimit: 50,
                lastOverNumber: lastOverNumber
            )
        }
    }
}
