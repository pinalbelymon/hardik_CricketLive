import Foundation

// MARK: - Home View Model

/// Coordinates dashboard data and search state.
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var featuredMatch: Match?
    @Published var upcomingMatches: [Match] = []
    @Published var recentResults: [Match] = []
    @Published var rankingsPreview: [RankingEntry] = []
    @Published var commentaryPreview: [BallEvent] = []
    @Published var searchText = ""
    @Published private(set) var state: ViewState<Void> = .idle
    @Published private(set) var lastUpdated: Date?

    private let fixturesRepository: FixturesRepositoryProtocol
    private let rankingsRepository: RankingsRepositoryProtocol

    init(fixturesRepository: FixturesRepositoryProtocol, rankingsRepository: RankingsRepositoryProtocol) {
        self.fixturesRepository = fixturesRepository
        self.rankingsRepository = rankingsRepository
    }

    var isLoading: Bool { state.isLoading }
    var errorMessage: String? { state.errorMessage }
    var isOffline: Bool { state.isOffline }

    /// Whether a non-empty search query is entered.
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Global search results matching title, competition, team name/shortName, venue, or status across all matches.
    var searchResults: [Match] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }

        var combined: [Match] = []
        if let featuredMatch {
            combined.append(featuredMatch)
        }
        combined.append(contentsOf: upcomingMatches)
        combined.append(contentsOf: recentResults)

        var seen = Set<Int>()
        let uniqueMatches = combined.filter { seen.insert($0.id).inserted }

        return uniqueMatches.filter { match in
            match.title.lowercased().contains(query)
                || match.competition.lowercased().contains(query)
                || match.homeTeam.name.lowercased().contains(query)
                || match.homeTeam.shortName.lowercased().contains(query)
                || match.awayTeam.name.lowercased().contains(query)
                || match.awayTeam.shortName.lowercased().contains(query)
                || match.venue.lowercased().contains(query)
                || match.status.lowercased().contains(query)
                || match.gameStatus.lowercased().contains(query)
        }
    }

    /// Upcoming fixtures shown on home (no live or featured duplicate).
    var homeUpcomingMatches: [Match] {
        upcomingMatches.filter { match in
            guard match.isLiveMatch == false else { return false }
            if let featuredMatch, match.id == featuredMatch.id {
                return false
            }
            return true
        }
    }

    var filteredUpcomingMatches: [Match] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return homeUpcomingMatches
        }

        return homeUpcomingMatches.filter { match in
            match.title.lowercased().contains(query)
                || match.competition.lowercased().contains(query)
                || match.homeTeam.name.lowercased().contains(query)
                || match.homeTeam.shortName.lowercased().contains(query)
                || match.awayTeam.name.lowercased().contains(query)
                || match.awayTeam.shortName.lowercased().contains(query)
                || match.venue.lowercased().contains(query)
        }
    }

    var filteredRecentResults: [Match] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return recentResults
        }

        return recentResults.filter { match in
            match.title.lowercased().contains(query)
                || match.competition.lowercased().contains(query)
                || match.homeTeam.name.lowercased().contains(query)
                || match.homeTeam.shortName.lowercased().contains(query)
                || match.awayTeam.name.lowercased().contains(query)
                || match.awayTeam.shortName.lowercased().contains(query)
                || match.venue.lowercased().contains(query)
        }
    }

    func load(isRefreshing: Bool = false) async {
        if isRefreshing {
            state = .refreshing(())
        } else if featuredMatch == nil {
            state = .loading
        }

        do {
            let upcoming = try await fixturesRepository.upcomingMatches(from: .now)
            let previous = try await fixturesRepository.previousMatches(from: .now)

            upcomingMatches = upcoming.value
            recentResults = previous.value
            featuredMatch = upcoming.value.first(where: { $0.shouldPollLiveUpdates || $0.state == .live })
                ?? upcoming.value.first
            commentaryPreview = featuredMatch?.recentBalls ?? []
            lastUpdated = [upcoming.lastUpdated, previous.lastUpdated].compactMap { $0 }.max()

            if upcoming.isFromCache || previous.isFromCache, let updated = lastUpdated {
                state = .offline((), lastUpdated: updated)
            } else {
                state = .loaded(())
            }

            loadRankingsPreview()
        } catch is CancellationError {
            if case .loading = state {
                state = .idle
            }
        } catch {
            if let updated = lastUpdated {
                state = .offline((), lastUpdated: updated)
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func loadRankingsPreview() {
        Task {
            guard let rankings = try? await rankingsRepository.rankings(format: .odi, category: .batting) else {
                return
            }

            rankingsPreview = Array(rankings.value.prefix(3))
            if let rankingsUpdated = rankings.lastUpdated {
                lastUpdated = [lastUpdated, rankingsUpdated].compactMap { $0 }.max()
            }
        }
    }
}
