import SwiftUI

// MARK: - Scorecard View

/// Elegant scorecard screen with batting, bowling, extras, wickets, and partnerships.
struct ScorecardView: View {
    private enum ScrollAnchor {
        static let top = "scorecard-top"
    }

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var adsManager: AdsManager
    @ObservedObject private var lifecycleManager = AppLifecycleManager.shared
    @StateObject private var viewModel: ScorecardViewModel
    @State private var selectedInningsID: Int?
    @State private var didRecordInterstitialTap = false

    init(fixtureId: Int, isLive: Bool, repository: ScorecardRepositoryProtocol) {
        _viewModel = StateObject(
            wrappedValue: ScorecardViewModel(
                fixtureId: fixtureId,
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
                    Color.clear.frame(height: 1).id(ScrollAnchor.top)

//                    NativeAdFeedCard(
//                        placement: .matchDetailsNative,
//                        slotKey: "scorecard-top-\(viewModel.fixtureId)"
//                    )

                    if viewModel.isLoading {
                        LoadingView()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.scorecard == nil {
                        ErrorView(title: "Could not load scorecard", message: errorMessage) {
                            Task { await viewModel.load(force: true) }
                        }
                    } else if let scorecard = viewModel.scorecard {
                        if viewModel.isOffline, let updated = viewModel.lastUpdated {
                            LastUpdatedBanner(date: updated)
                        }

                        scorecardContent(scorecard)
                            .animation(AppAnimation.spring, value: viewModel.scoreSignature)

//                        NativeAdFeedCard(
//                            placement: .matchDetailsNative,
//                            slotKey: "scorecard-bottom-\(viewModel.fixtureId)"
//                        )
                    } else {
                        EmptyState(title: "No scorecard", message: "Scorecard data will appear when available.", systemImage: "tablecells")
                    }
                }
                .padding(Spacing.large)
                .padding(.bottom, Spacing.medium)
            }
            .background(palette.background)
            .navigationTitle("Scorecard")
            .navigationBarTitleDisplayMode(.inline)
            .hidesBottomTabBar()
            .toolbar {
                Button {
                    withAnimation(AppAnimation.spring) {
                        proxy.scrollTo(ScrollAnchor.top, anchor: .top)
                    }
                } label: {
                    Image(systemName: "arrow.up.to.line")
                }
                .accessibilityLabel("Scroll to top")
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                StickyBottomBannerAdView(placement: .scorecardBanner)
            }
            .task {
                guard didRecordInterstitialTap == false else { return }
                didRecordInterstitialTap = true
                await adsManager.recordInterstitialTap(.scorecard)
            }
        }
    }

    private func scorecardContent(_ scorecard: Scorecard) -> some View {
        let innings = selectedInnings(from: scorecard)

        return VStack(alignment: .leading, spacing: Spacing.xLarge) {
            GlassCard(padding: Spacing.large) {
                Text(scorecard.matchSummary)
                    .font(Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if scorecard.innings.count > 1 {
                InningsSelector(innings: scorecard.innings, selection: $selectedInningsID)
            }

            battingSection(innings)
            bowlingSection(innings)
            extrasSection(innings)
            wicketsSection(innings)
            partnershipsSection(innings)
        }
    }

    private func selectedInnings(from scorecard: Scorecard) -> ScorecardInnings {
        if let selectedInningsID,
           let selected = scorecard.innings.first(where: { $0.id == selectedInningsID }) {
            return selected
        }

        if let latest = scorecard.innings.last {
            return latest
        }

        return ScorecardInnings(
            inningNumber: 1,
            batting: scorecard.batting,
            bowling: scorecard.bowling,
            extras: scorecard.extras,
            fallOfWickets: scorecard.fallOfWickets,
            partnerships: scorecard.partnerships,
            battingTeamName: scorecard.battingTeamName,
            bowlingTeamName: scorecard.bowlingTeamName
        )
    }

    private func battingSection(_ innings: ScorecardInnings) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Batting", subtitle: innings.battingTeamName, systemImage: "figure.cricket")

            if innings.batting.isEmpty {
                EmptyState(title: "No batting", message: "This innings table is not available yet.", systemImage: "figure.cricket")
            } else {
                BattingTable(rows: innings.batting)
            }
        }
    }

    private func bowlingSection(_ innings: ScorecardInnings) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Bowling", subtitle: innings.bowlingTeamName, systemImage: "target")

            if innings.bowling.isEmpty {
                EmptyState(title: "No bowling", message: "This innings table is not available yet.", systemImage: "target")
            } else {
                BowlingTable(rows: innings.bowling)
            }
        }
    }

    private func extrasSection(_ innings: ScorecardInnings) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Extras", systemImage: "plus.circle")
            GlassCard(padding: Spacing.medium) {
                HStack(spacing: Spacing.medium) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.palette(for: colorScheme).primary)

                    Text(innings.extras)
                        .font(Typography.body)
                        .foregroundStyle(Theme.palette(for: colorScheme).text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func wicketsSection(_ innings: ScorecardInnings) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Fall of Wickets", systemImage: "xmark.octagon")
            if innings.fallOfWickets.isEmpty {
                EmptyState(title: "No wickets", message: "Wickets will appear here as they fall.", systemImage: "xmark.octagon")
            } else {
                WicketsCard(rows: innings.fallOfWickets)
            }
        }
    }

    private func partnershipsSection(_ innings: ScorecardInnings) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Partnerships", systemImage: "person.2")
            if innings.partnerships.isEmpty {
                EmptyState(title: "No partnerships", message: "Partnerships will appear as the innings develops.", systemImage: "person.2")
            } else {
                PartnershipsCard(rows: innings.partnerships)
            }
        }
    }
}

// MARK: - Scorecard Tables

private struct InningsSelector: View {
    @Environment(\.colorScheme) private var colorScheme

    let innings: [ScorecardInnings]
    @Binding var selection: Int?

    var body: some View {
        let palette = Theme.palette(for: colorScheme)
        let selectedID = selection ?? innings.last?.id

        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("INNINGS")
                .font(Typography.caption)
                .foregroundStyle(palette.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    ForEach(innings) { innings in
                        let isSelected = innings.id == selectedID

                        Button {
                            withAnimation(AppAnimation.quick) {
                                selection = innings.id
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                                Text(innings.title)
                                    .font(Typography.caption)
                                    .lineLimit(1)
                                Text("\(innings.batting.count) batters")
                                    .font(.system(size: 10, weight: .medium))
                                    .opacity(0.8)
                            }
                            .foregroundStyle(isSelected ? palette.background : palette.text)
                            .padding(.horizontal, Spacing.medium)
                            .padding(.vertical, Spacing.small)
                            .background(
                                isSelected ? palette.primary : palette.elevatedBackground,
                                in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                                    .stroke(isSelected ? palette.primary : palette.divider, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(innings.title)
                    }
                }
            }
        }
    }
}

private struct BattingTable: View {
    @Environment(\.colorScheme) private var colorScheme
    let rows: [BattingRow]

    var body: some View {
        ScorecardTableCard {
            BattingHeader()
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                BattingScoreRow(row: row)
                if index < rows.count - 1 { Divider() }
            }
        }
    }
}

private struct BattingHeader: View {
    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            Text("BATTER")
                .frame(maxWidth: .infinity, alignment: .leading)
            ScorecardColumnHeader("R", width: 27)
            ScorecardColumnHeader("B", width: 27)
            ScorecardColumnHeader("4s", width: 30)
            ScorecardColumnHeader("6s", width: 30)
            ScorecardColumnHeader("SR", width: 42)
        }
        .padding(.bottom, Spacing.xSmall)
    }
}

private struct BattingScoreRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let row: BattingRow

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
                Text(row.playerName)
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScorecardValue("\(row.runs)", width: 27, emphasized: true)
                ScorecardValue("\(row.balls)", width: 27)
                ScorecardValue("\(row.fours)", width: 30)
                ScorecardValue("\(row.sixes)", width: 30)
                ScorecardValue(String(format: "%.0f", row.strikeRate), width: 42)
            }

            Text(row.dismissal)
                .font(Typography.caption)
                .foregroundStyle(palette.secondaryText)
                .lineLimit(1)
        }
        .padding(.vertical, Spacing.xSmall)
        .accessibilityElement(children: .combine)
    }
}

private struct BowlingTable: View {
    let rows: [BowlingRow]

    var body: some View {
        ScorecardTableCard {
            HStack(spacing: Spacing.xSmall) {
                Text("BOWLER")
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScorecardColumnHeader("O", width: 29)
                ScorecardColumnHeader("M", width: 27)
                ScorecardColumnHeader("R", width: 27)
                ScorecardColumnHeader("W", width: 27)
                ScorecardColumnHeader("ECO", width: 40)
            }
            .padding(.bottom, Spacing.xSmall)

            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                BowlingScoreRow(row: row)
                if index < rows.count - 1 { Divider() }
            }
        }
    }
}

private struct BowlingScoreRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let row: BowlingRow

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
            Text(row.playerName)
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(palette.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScorecardValue(String(format: "%.1f", row.overs), width: 29)
            ScorecardValue("\(row.maidens)", width: 27)
            ScorecardValue("\(row.runs)", width: 27)
            ScorecardValue("\(row.wickets)", width: 27, emphasized: true)
            ScorecardValue(String(format: "%.1f", row.economy), width: 40)
        }
        .padding(.vertical, Spacing.medium)
        .accessibilityElement(children: .combine)
    }
}

private struct ScorecardTableCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.elevatedBackground, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .stroke(palette.divider.opacity(0.75), lineWidth: 1)
        }
    }
}

private struct ScorecardColumnHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String
    let width: CGFloat

    init(_ text: String, width: CGFloat) {
        self.text = text
        self.width = width
    }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.palette(for: colorScheme).secondaryText)
            .frame(width: width, alignment: .trailing)
    }
}

private struct ScorecardValue: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String
    let width: CGFloat
    let emphasized: Bool

    init(_ text: String, width: CGFloat, emphasized: Bool = false) {
        self.text = text
        self.width = width
        self.emphasized = emphasized
    }

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced).weight(emphasized ? .bold : .medium))
            .foregroundStyle(emphasized ? Theme.palette(for: colorScheme).text : Theme.palette(for: colorScheme).secondaryText)
            .frame(width: width, alignment: .trailing)
    }
}

private struct WicketsCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let rows: [FallOfWicket]

    var body: some View {
        ScorecardTableCard {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, wicket in
                HStack(alignment: .center, spacing: Spacing.medium) {
                    Text(wicket.score)
                        .font(Typography.monoCaption)
                        .foregroundStyle(Theme.palette(for: colorScheme).error)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.xSmall)
                        .background(Theme.palette(for: colorScheme).error.opacity(0.14), in: Capsule())

                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text(wicket.playerName)
                            .font(Typography.body.weight(.semibold))
                            .lineLimit(1)
                        Text("\(String(format: "%.1f", wicket.over)) overs")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.palette(for: colorScheme).secondaryText)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, Spacing.small)
                if index < rows.count - 1 { Divider() }
            }
        }
    }
}

private struct PartnershipsCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let rows: [Partnership]

    var body: some View {
        ScorecardTableCard {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, partnership in
                HStack(spacing: Spacing.medium) {
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text(partnership.batters)
                            .font(Typography.body.weight(.semibold))
                            .lineLimit(1)
                        Text("\(partnership.balls) balls")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.palette(for: colorScheme).secondaryText)
                    }

                    Spacer(minLength: Spacing.small)

                    Text("\(partnership.runs)")
                        .font(Typography.monoScore)
                        .foregroundStyle(Theme.palette(for: colorScheme).primary)
                }
                .padding(.vertical, Spacing.small)
                if index < rows.count - 1 { Divider() }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScorecardView(
            fixtureId: PreviewData.liveMatch.fixtureId,
            isLive: true,
            repository: DependencyContainer.preview().scorecardRepository
        )
    }
    .environmentObject(DependencyContainer.preview().adsManager)
}
