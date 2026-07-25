import Foundation

// MARK: - Rankings View Model

/// Loads Cricnet rankings for the selected format and category.
@MainActor
final class RankingsViewModel: ObservableObject {
    @Published var selectedFormat: CricketFormat = .odi
    @Published var selectedCategory: RankingCategory = .batting
    @Published private(set) var state: ViewState<[RankingEntry]> = .idle
    @Published private(set) var lastUpdated: Date?

    private let repository: RankingsRepositoryProtocol

    init(repository: RankingsRepositoryProtocol) {
        self.repository = repository
    }

    var rankings: [RankingEntry] { state.data ?? [] }
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
            let result = try await repository.rankings(format: selectedFormat, category: selectedCategory)
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
