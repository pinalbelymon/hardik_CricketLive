import Foundation

// MARK: - Fixtures View Model

/// Loads fixtures by selected calendar direction and groups them by date.
@MainActor
final class FixturesViewModel: ObservableObject {
    @Published var selectedFilter: FixtureFilter = .today
    @Published var selectedDate = Date()
    @Published var searchText = ""
    @Published private(set) var state: ViewState<[FixtureDateGroup]> = .idle
    @Published private(set) var lastUpdated: Date?

    private let repository: FixturesRepositoryProtocol

    init(repository: FixturesRepositoryProtocol) {
        self.repository = repository
    }

    var groupedMatches: [FixtureDateGroup] {
        state.data ?? []
    }

    var filteredGroupedMatches: [FixtureDateGroup] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return groupedMatches }

        return groupedMatches.compactMap { group in
            let filteredMatches = group.matches.filter { match in
                match.title.lowercased().contains(query)
                    || match.competition.lowercased().contains(query)
                    || match.homeTeam.name.lowercased().contains(query)
                    || match.homeTeam.shortName.lowercased().contains(query)
                    || match.awayTeam.name.lowercased().contains(query)
                    || match.awayTeam.shortName.lowercased().contains(query)
                    || match.venue.lowercased().contains(query)
            }
            if filteredMatches.isEmpty {
                return nil
            }
            return FixtureDateGroup(date: group.date, title: group.title, matches: filteredMatches)
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
            let loaded: RepositoryResult<[Match]>
            switch selectedFilter {
            case .today:
                let today = Calendar.current.startOfDay(for: Date())
                selectedDate = today
                let result = try await repository.upcomingMatches(from: today)
                let filtered = result.value.filter { match in
                    match.shouldPollLiveUpdates
                        || match.state == .live
                        || match.isScheduled(on: today)
                }
                loaded = RepositoryResult(value: filtered, lastUpdated: result.lastUpdated, isFromCache: result.isFromCache)
            case .upcoming:
                loaded = try await repository.upcomingMatches(from: selectedDate)
            case .previous:
                loaded = try await repository.previousMatches(from: selectedDate)
            }

            let groups = Self.groupMatches(loaded.value)
            lastUpdated = loaded.lastUpdated

            if groups.isEmpty {
                state = .empty
            } else if loaded.isFromCache, let updated = loaded.lastUpdated {
                state = .offline(groups, lastUpdated: updated)
            } else {
                state = .loaded(groups)
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

    private static func groupMatches(_ matches: [Match]) -> [FixtureDateGroup] {
        let grouped = Dictionary(grouping: matches) { match -> Date in
            match.scheduleDay ?? .distantPast
        }

        return grouped
            .map { date, matches in
                FixtureDateGroup(
                    date: date,
                    title: DateFormatters.dayTitle(for: date),
                    matches: matches.sorted { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }
                )
            }
            .sorted { selectedFilterSort($0.date, $1.date) }
    }

    private static func selectedFilterSort(_ lhs: Date, _ rhs: Date) -> Bool {
        lhs < rhs
    }
}
