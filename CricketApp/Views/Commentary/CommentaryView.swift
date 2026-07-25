import SwiftUI

// MARK: - Commentary View

/// Ball-by-ball commentary grouped by over with event colors.
struct CommentaryView: View {
    private enum ScrollAnchor {
        static let latest = "commentary-latest"
    }

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var lifecycleManager = AppLifecycleManager.shared
    @StateObject private var viewModel: CommentaryViewModel

    init(fixtureId: Int, inningNumber: Int, isLive: Bool, repository: CommentaryRepositoryProtocol) {
        _viewModel = StateObject(
            wrappedValue: CommentaryViewModel(
                fixtureId: fixtureId,
                inningNumber: inningNumber,
                isLive: isLive,
                repository: repository
            )
        )
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                    // Keep a stable target so the toolbar action works even when the
                    // newest card has not yet been created by LazyVStack.
                    Color.clear
                        .frame(height: 1)
                        .id(ScrollAnchor.latest)

                    if viewModel.isLoading {
                        LoadingView()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.overGroups.isEmpty {
                        ErrorView(title: "Could not load commentary", message: errorMessage) {
                            Task { await viewModel.load(force: true) }
                        }
                    } else if viewModel.overGroups.isEmpty {
                        EmptyState(title: "No commentary", message: "Ball-by-ball updates will appear during live play.", systemImage: "text.bubble")
                    } else {
                        ForEach(viewModel.overGroups) { group in
                            overGroup(group)
                        }
                    }
                }
                .padding(Spacing.large)
            }
            .background(palette.background)
            .navigationTitle("Commentary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    viewModel.isPinnedToLatest = true
                    withAnimation(AppAnimation.spring) {
                        proxy.scrollTo(ScrollAnchor.latest, anchor: .top)
                    }
                } label: {
                    Image(systemName: "arrow.up.to.line")
                }
                .accessibilityLabel("Scroll to latest")
            }
            .refreshable {
                await viewModel.load(force: true)
            }
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
            .onChange(of: lifecycleManager.isActive) { _, isActive in
                viewModel.handleAppLifecycle(isActive: isActive)
            }
            .onChange(of: viewModel.latestEventID) { _, latestEventID in
                guard viewModel.isPinnedToLatest, latestEventID != nil else { return }
                withAnimation(AppAnimation.quick) {
                    proxy.scrollTo(ScrollAnchor.latest, anchor: .top)
                }
            }
        }
    }

    private func overGroup(_ group: CommentaryOverGroup) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Over \(group.overNumber)", systemImage: "circle.grid.cross")

            VStack(spacing: Spacing.small) {
                ForEach(group.events) { event in
                    CommentaryCard(event: event)
                        .id(event.id)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CommentaryView(
            fixtureId: PreviewData.liveMatch.fixtureId,
            inningNumber: 2,
            isLive: true,
            repository: DependencyContainer.preview().commentaryRepository
        )
    }
}
