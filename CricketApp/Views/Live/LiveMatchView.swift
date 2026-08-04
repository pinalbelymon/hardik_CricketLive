import SwiftUI

// MARK: - Live Match View

/// Live match detail aligned with match details layout, plus live metrics and recent balls.
struct LiveMatchView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var lifecycleManager = AppLifecycleManager.shared
    @StateObject private var viewModel: LiveMatchViewModel

    private let container: DependencyContainer

    init(match: Match, container: DependencyContainer) {
        self.container = container
        _viewModel = StateObject(
            wrappedValue: LiveMatchViewModel(
                match: match,
                scorecardRepository: container.scorecardRepository,
                commentaryRepository: container.commentaryRepository
            )
        )
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                NativeAdFeedCard(
                    placement: .matchDetailsNative,
                    slotKey: "live-match-top-\(viewModel.match.id)"
                )

                if viewModel.state.isLoading, viewModel.scorecard == nil {
                    LoadingView()
                } else {
                    scoreHeaderCard

                    if viewModel.isOffline, let updated = viewModel.lastUpdated {
                        LastUpdatedBanner(date: updated)
                    }

                    if let errorMessage = viewModel.errorMessage, viewModel.scorecard == nil, viewModel.commentary.isEmpty {
                        ErrorView(title: "Live update failed", message: errorMessage) {
                            Task { await viewModel.refresh() }
                        }
                    }
                    
                    recentBalls
                    MatchCentreLinks(
                        match: viewModel.match,
                        scorecardRepository: container.scorecardRepository,
                        commentaryRepository: container.commentaryRepository
                    )

                    matchFacts
                    liveMetrics
                   

                    if let scorecard = viewModel.scorecard, hasScorecardSummary(scorecard) {
                        scorecardSummary(scorecard)
                    }
                }
            }
            .padding(Spacing.large)
        }
        .background(palette.background)
        .navigationTitle(viewModel.match.teamsText)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.refresh()
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
    }

    private var scoreHeaderCard: some View {
        GlassCard(padding: Spacing.large, surface: .solid) {
            VStack(spacing: Spacing.medium) {
                HStack {
                    Spacer(minLength: 0)
                    LiveBadge(animated: true)
                }

                ScoreHeader(match: viewModel.match, animatesScoreChanges: true)
            }
        }
        .animation(AppAnimation.spring, value: viewModel.scoreSignature)
    }

    private var matchFacts: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Match Details", subtitle: viewModel.match.venue, systemImage: "sportscourt")

            GlassCard(padding: Spacing.large, surface: .solid) {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    MatchFactRow(
                        title: "Toss",
                        value: tossStatus,
                        systemImage: "arrow.triangle.2.circlepath"
                    )

                    if let scheduleDay = viewModel.match.scheduleDay {
                        Divider()

                        MatchFactRow(
                            title: "Match date",
                            value: DateFormatters.dayTitle(for: scheduleDay),
                            systemImage: "calendar"
                        )
                    }

                    if let scheduleLabel = viewModel.match.displayScheduleLabel {
                        Divider()

                        MatchFactRow(
                            title: "Start time",
                            value: scheduleLabel,
                            systemImage: "clock"
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var liveMetrics: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Live Metrics", systemImage: "gauge.with.dots.needle.67percent")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.medium) {
                LiveStatCard(
                    title: "Current RR",
                    value: viewModel.match.currentRunRate.map { String(format: "%.2f", $0) } ?? "—"
                )
                LiveStatCard(
                    title: "Required RR",
                    value: viewModel.match.requiredRunRate.map { String(format: "%.2f", $0) } ?? "—"
                )
                LiveStatCard(
                    title: "Win Prob.",
                    value: viewModel.match.winningProbability.map { "\(Int($0))%" } ?? "—"
                )
                LiveStatCard(
                    title: "Status",
                    value: viewModel.match.gameStatus.isEmpty ? viewModel.match.state.title : viewModel.match.gameStatus
                )
            }
        }
    }

    @ViewBuilder
    private var recentBalls: some View {
        let events = viewModel.commentary.isEmpty ? viewModel.match.recentBalls : viewModel.commentary

        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Recent Balls", systemImage: "circle.grid.cross")

            if events.isEmpty {
                GlassCard(padding: Spacing.large, surface: .solid) {
                    EmptyState(
                        title: "No recent balls",
                        message: "Ball-by-ball updates arrive during live play.",
                        systemImage: "smallcircle.filled.circle"
                    )
                }
            } else {
                GlassCard(padding: Spacing.medium, surface: .solid) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.small) {
                            ForEach(events.prefix(12)) { event in
                                RecentBallChip(event: event)
                            }
                        }
                        .padding(.vertical, Spacing.xSmall)
                    }
                }
            }
        }
    }

    private func scorecardSummary(_ scorecard: Scorecard) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Scorecard Summary", systemImage: "doc.text")

            GlassCard(padding: Spacing.large, surface: .solid) {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    if let battingTeam = scorecard.battingTeamName {
                        SummaryTeamRow(title: "Batting", teamName: battingTeam)
                    }

                    if let bowlingTeam = scorecard.bowlingTeamName {
                        SummaryTeamRow(title: "Bowling", teamName: bowlingTeam)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var tossStatus: String {
        guard let toss = viewModel.match.toss?.trimmingCharacters(in: .whitespacesAndNewlines), toss.isEmpty == false else {
            return "Toss not announced yet"
        }
        return toss
    }

    private func hasScorecardSummary(_ scorecard: Scorecard) -> Bool {
        let battingAvailable = scorecard.battingTeamName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let bowlingAvailable = scorecard.bowlingTeamName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        return battingAvailable || bowlingAvailable
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LiveMatchView(match: PreviewData.liveMatch, container: .preview())
    }
}
