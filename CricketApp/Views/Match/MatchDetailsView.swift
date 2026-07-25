import SwiftUI

// MARK: - Match Details View

/// Match centre for upcoming and completed fixtures.
struct MatchDetailsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: MatchDetailsViewModel

    private let container: DependencyContainer

    init(match: Match, container: DependencyContainer) {
        self.container = container
        _viewModel = StateObject(
            wrappedValue: MatchDetailsViewModel(
                match: match,
                scorecardRepository: container.scorecardRepository
            )
        )
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                if viewModel.state.isLoading {
                    LoadingView()
                } else {
                    GlassCard(padding: Spacing.large, surface: .solid) {
                        ScoreHeader(match: viewModel.match)
                    }
                    .animation(AppAnimation.spring, value: viewModel.match.status)

                    if viewModel.isOffline, let updated = viewModel.lastUpdated {
                        LastUpdatedBanner(date: updated)
                    }

                    if let errorMessage = viewModel.errorMessage, viewModel.scorecard == nil {
                        ErrorView(title: "Could not load match", message: errorMessage) {
                            Task { await viewModel.load(force: true) }
                        }
                    }

                    matchFacts
                    MatchCentreLinks(
                        match: viewModel.match,
                        scorecardRepository: container.scorecardRepository,
                        commentaryRepository: container.commentaryRepository
                    )

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
            await viewModel.load(force: true)
        }
        .task {
            if viewModel.scorecard == nil {
                await viewModel.load()
            }
        }
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
        MatchDetailsView(match: PreviewData.upcomingMatches[0], container: .preview())
    }
}
