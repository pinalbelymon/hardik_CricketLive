import SwiftUI

// MARK: - Live Matches View

/// Lists all in-progress matches, or an empty state when none are live.
struct LiveMatchesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: LiveMatchesViewModel

    private let container: DependencyContainer

    init(container: DependencyContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: LiveMatchesViewModel(repository: container.fixturesRepository))
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.large) {
                if !viewModel.matches.isEmpty {
                    SearchBar(text: $viewModel.searchText)
                }

                if viewModel.isLoading {
                    LoadingView()
                } else if let errorMessage = viewModel.errorMessage, viewModel.matches.isEmpty {
                    ErrorView(title: "Could not load live matches", message: errorMessage) {
                        Task { await viewModel.load() }
                    }
                } else if viewModel.matches.isEmpty {
                    EmptyState(
                        title: "No live matches",
                        message: "There are no matches in progress right now. Check back when a game is underway.",
                        systemImage: "dot.radiowaves.left.and.right"
                    )
                } else if viewModel.filteredMatches.isEmpty {
                    EmptyState(
                        title: "No matching live matches",
                        message: "No live matches matched \"\(viewModel.searchText)\".",
                        systemImage: "magnifyingglass"
                    )
                } else {
                    if viewModel.isOffline, let updated = viewModel.lastUpdated {
                        LastUpdatedBanner(date: updated)
                    }

                    SectionHeader(
                        "Live Now",
                        subtitle: "\(viewModel.filteredMatches.count) match\(viewModel.filteredMatches.count == 1 ? "" : "es") in progress",
                        systemImage: "dot.radiowaves.left.and.right"
                    )

                    ForEach(viewModel.filteredMatches) { match in
                        NavigationLink {
                            MatchDestinationView(match: match, container: container)
                        } label: {
                            MatchCard(match: match)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Spacing.large)
        }
        .background(palette.background)
        .navigationTitle("Live Matches")
        .refreshable {
            await viewModel.load(isRefreshing: true)
        }
        .task {
            if case .idle = viewModel.state {
                await viewModel.load()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LiveMatchesView(container: .preview())
    }
}
