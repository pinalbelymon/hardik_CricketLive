import Foundation

// MARK: - Live Matches View Model

/// Loads currently live matches for the home quick-navigation screen.
@MainActor
final class LiveMatchesViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var state: ViewState<[Match]> = .idle
    @Published private(set) var lastUpdated: Date?

    private let repository: FixturesRepositoryProtocol

    init(repository: FixturesRepositoryProtocol) {
        self.repository = repository
    }

    var matches: [Match] {
        state.data ?? []
    }

    var filteredMatches: [Match] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return matches }

        return matches.filter { match in
            match.title.lowercased().contains(query)
                || match.competition.lowercased().contains(query)
                || match.homeTeam.name.lowercased().contains(query)
                || match.homeTeam.shortName.lowercased().contains(query)
                || match.awayTeam.name.lowercased().contains(query)
                || match.awayTeam.shortName.lowercased().contains(query)
                || match.venue.lowercased().contains(query)
        }
    }

    var isLoading: Bool { state.isLoading }
    var errorMessage: String? { state.errorMessage }
    var isOffline: Bool { state.isOffline }

    func load(isRefreshing: Bool = false) async {
        if isRefreshing, let current = state.data {
            state = .refreshing(current)
        } else if state.data == nil {
            state = .loading
        }

        do {
            let result = try await repository.liveMatches()
            lastUpdated = result.lastUpdated

            if result.value.isEmpty {
                state = .empty
            } else if result.isFromCache, let updated = result.lastUpdated {
                state = .offline(result.value, lastUpdated: updated)
            } else {
                state = .loaded(result.value)
            }
        } catch is CancellationError {
            if case .loading = state {
                state = .idle
            }
        } catch {
            if let current = state.data, let updated = lastUpdated {
                state = .offline(current, lastUpdated: updated)
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }
}
