import SwiftUI

// MARK: - Home View

/// Premium dashboard combining live, fixtures, results, commentary, and rankings.
struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: HomeViewModel

    private let container: DependencyContainer

    init(container: DependencyContainer) {
        self.container = container
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                fixturesRepository: container.fixturesRepository,
                rankingsRepository: container.rankingsRepository
            )
        )
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                    SearchBar(text: $viewModel.searchText)

                    if viewModel.isLoading {
                        LoadingView()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.featuredMatch == nil {
                        ErrorView(title: "Could not refresh cricket", message: errorMessage) {
                            Task { await viewModel.load() }
                        }
                    } else {
                        if viewModel.isOffline, let updated = viewModel.lastUpdated {
                            LastUpdatedBanner(date: updated)
                        }

                        if viewModel.isSearching {
                            SectionHeader(
                                "Search Results",
                                subtitle: "\(viewModel.searchResults.count) match\(viewModel.searchResults.count == 1 ? "" : "es") found for \"\(viewModel.searchText)\"",
                                systemImage: "magnifyingglass"
                            )

                            if viewModel.searchResults.isEmpty {
                                EmptyState(
                                    title: "No matches found",
                                    message: "No fixtures or results matched \"\(viewModel.searchText)\". Try searching for a team (e.g. Brave, Fire, IND), tournament, or venue.",
                                    systemImage: "magnifyingglass"
                                )
                            } else {
                                ForEach(viewModel.searchResults) { match in
                                    NavigationLink(value: match) {
                                        MatchCard(match: match)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            SectionHeader("Featured Match", subtitle: "Live and high-interest fixtures", systemImage: "bolt.fill")

                            if let match = viewModel.featuredMatch {
                                NavigationLink(value: match) {
                                    MatchCard(match: match, isProminent: true)
                                }
                                .buttonStyle(.plain)
                            } else {
                                EmptyState(title: "No featured match", message: "Live and upcoming matches will appear here.", systemImage: "sportscourt")
                            }

                            if !viewModel.commentaryPreview.isEmpty {
                                SectionHeader("Live Commentary Preview", subtitle: "Latest ball-by-ball events", systemImage: "text.bubble.fill")

                                ForEach(viewModel.commentaryPreview.prefix(4)) { event in
                                    CommentaryCard(event: event)
                                }
                            }

                            quickNavigationSection

                            SectionHeader("Upcoming Fixtures", subtitle: "Calendar-aware schedule", systemImage: "calendar.badge.clock")

                            if viewModel.filteredUpcomingMatches.isEmpty {
                                EmptyState(title: "No upcoming fixtures", message: "Upcoming matches will appear as soon as the API returns data.", systemImage: "calendar")
                            } else {
                                ForEach(viewModel.filteredUpcomingMatches.prefix(4)) { match in
                                    NavigationLink(value: match) {
                                        MatchCard(match: match)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            SectionHeader("Recent Results", subtitle: "Completed matches", systemImage: "checkmark.seal.fill")

                            if viewModel.recentResults.isEmpty {
                                EmptyState(title: "No recent results", message: "Completed matches will appear here.", systemImage: "clock.badge.checkmark")
                            } else {
                                ForEach(viewModel.recentResults.prefix(3)) { match in
                                    NavigationLink(value: match) {
                                        MatchCard(match: match)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(Spacing.large)
            }
            .scrollIndicators(.hidden)
            .background(palette.background)
            .navigationTitle(AppConstants.appName)
            .refreshable {
                await viewModel.load(isRefreshing: true)
            }
            .task {
                if viewModel.featuredMatch == nil {
                    await viewModel.load()
                }
            }
            .navigationDestination(for: Match.self) { match in
                MatchDestinationView(match: match, container: container)
            }
        }
    }

    private var quickNavigationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Quick Navigation", systemImage: "square.grid.2x2.fill")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Spacing.medium)], spacing: Spacing.medium) {
                NavigationLink {
                    FixturesView(container: container)
                } label: {
                    QuickNavigationTile(title: "Fixtures", systemImage: "calendar")
                }

                NavigationLink {
                    LiveMatchesView(container: container)
                } label: {
                    QuickNavigationTile(title: "Live", systemImage: "dot.radiowaves.left.and.right")
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Quick Navigation Tile

private struct QuickNavigationTile: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let systemImage: String

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        VStack(spacing: Spacing.medium) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(palette.primary)

            Text(title)
                .font(Typography.headline)
                .foregroundStyle(palette.text)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .background(palette.elevatedBackground, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    HomeView(container: .preview())
        .environmentObject(ThemeManager())
}
