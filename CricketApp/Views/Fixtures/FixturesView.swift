import SwiftUI

// MARK: - Fixtures View

/// Calendar-led fixtures screen for today, upcoming, and previous matches.
struct FixturesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: FixturesViewModel

    private let container: DependencyContainer

    init(container: DependencyContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: FixturesViewModel(repository: container.fixturesRepository))
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.large) {
                    SearchBar(text: $viewModel.searchText)
                    controls

                    if viewModel.isLoading {
                        LoadingView()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.groupedMatches.isEmpty {
                        ErrorView(title: "Could not load fixtures", message: errorMessage) {
                            Task { await viewModel.load() }
                        }
                    } else if viewModel.filteredGroupedMatches.isEmpty {
                        EmptyState(
                            title: viewModel.searchText.isEmpty ? "No matches" : "No matching fixtures",
                            message: viewModel.searchText.isEmpty ? "Try another date or category." : "No fixtures matched \"\(viewModel.searchText)\".",
                            systemImage: viewModel.searchText.isEmpty ? "calendar.badge.exclamationmark" : "magnifyingglass"
                        )
                    } else {
                        if viewModel.isOffline, let updated = viewModel.lastUpdated {
                            LastUpdatedBanner(date: updated)
                        }

                        ForEach(viewModel.filteredGroupedMatches) { group in
                            VStack(alignment: .leading, spacing: Spacing.medium) {
                                SectionHeader(group.title, systemImage: "calendar")

                                ForEach(group.matches) { match in
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
            .background(palette.background)
            .navigationTitle("Fixtures")
            .refreshable {
                await viewModel.load(isRefreshing: true)
            }
            .task {
                if viewModel.groupedMatches.isEmpty {
                    await viewModel.load()
                }
            }
            .onChange(of: viewModel.selectedFilter) {
                Task { await viewModel.load() }
            }
            .onChange(of: viewModel.selectedDate) {
                Task { await viewModel.load() }
            }
            .navigationDestination(for: Match.self) { match in
                MatchDestinationView(match: match, container: container)
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Picker("Fixture filter", selection: $viewModel.selectedFilter) {
                ForEach(FixtureFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

//            DatePicker("Match date", selection: $viewModel.selectedDate, displayedComponents: .date)
//                .datePickerStyle(.compact)
        }
    }
}

// MARK: - Preview

#Preview {
    FixturesView(container: .preview())
}
