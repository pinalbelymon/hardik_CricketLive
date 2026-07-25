import SwiftUI

// MARK: - Rankings View

/// Cricnet ranking browser for format and category.
struct RankingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: RankingsViewModel

    init(repository: RankingsRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: RankingsViewModel(repository: repository))
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.large) {
                    controls

                    if viewModel.isLoading {
                        LoadingView()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.rankings.isEmpty {
                        ErrorView(title: "Could not load rankings", message: errorMessage) {
                            Task { await viewModel.load() }
                        }
                    } else if viewModel.rankings.isEmpty {
                        EmptyState(title: "No rankings", message: "Cricnet did not return ranking data for this selection.", systemImage: "chart.bar")
                    } else {
                        if viewModel.isOffline, let updated = viewModel.lastUpdated {
                            LastUpdatedBanner(date: updated)
                        }

                        ForEach(viewModel.rankings) { entry in
                            RankingCard(entry: entry)
                        }
                    }
                }
                .padding(Spacing.large)
            }
            .background(palette.background)
            .navigationTitle("Rankings")
            .refreshable {
                await viewModel.load(isRefreshing: true)
            }
            .task {
                if viewModel.rankings.isEmpty {
                    await viewModel.load()
                }
            }
            .onChange(of: viewModel.selectedFormat) {
                Task { await viewModel.load() }
            }
            .onChange(of: viewModel.selectedCategory) {
                Task { await viewModel.load() }
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Picker("Format", selection: $viewModel.selectedFormat) {
                ForEach(CricketFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    ForEach(RankingCategory.allCases) { category in
                        FilterChip(title: category.title, isSelected: category == viewModel.selectedCategory) {
                            viewModel.selectedCategory = category
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RankingsView(repository: DependencyContainer.preview().rankingsRepository)
}
