import Foundation

// MARK: - Match Details View Model

/// Loads static match details and scorecard for non-live fixtures.
@MainActor
final class MatchDetailsViewModel: ObservableObject {
    @Published private(set) var match: Match
    @Published private(set) var scorecard: Scorecard?
    @Published private(set) var state: ViewState<Match> = .loading
    @Published private(set) var lastUpdated: Date?

    private let scorecardRepository: ScorecardRepositoryProtocol

    init(match: Match, scorecardRepository: ScorecardRepositoryProtocol) {
        self.match = match
        self.scorecardRepository = scorecardRepository
        self.state = .loaded(match)
    }

    var errorMessage: String? { state.errorMessage }
    var isOffline: Bool { state.isOffline }

    func load(force: Bool = false) async {
        if force {
            state = .refreshing(match)
        } else if scorecard == nil {
            state = .loading
        }

        do {
            async let scorecardResult = scorecardRepository.scorecard(fixtureId: match.fixtureId, isLive: false)
            async let summaryResult = scorecardRepository.matchSummary(fixtureId: match.fixtureId)

            let loadedScorecard = try await scorecardResult
            let loadedSummary = try await summaryResult

            scorecard = loadedScorecard.value
            if let updatedMatch = loadedSummary.value {
                match = updatedMatch
            }
            lastUpdated = loadedScorecard.lastUpdated ?? loadedSummary.lastUpdated

            if loadedScorecard.isFromCache || loadedSummary.isFromCache, let updated = lastUpdated {
                state = .offline(match, lastUpdated: updated)
            } else {
                state = .loaded(match)
            }
        } catch {
            if let updated = lastUpdated {
                state = .offline(match, lastUpdated: updated)
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }
}
