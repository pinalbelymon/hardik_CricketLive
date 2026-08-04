import SwiftUI

// MARK: - Match Destination View

/// Routes fixtures to live or match-detail screens based on API state.
struct MatchDestinationView: View {
    @EnvironmentObject private var adsManager: AdsManager
    @State private var didRecordMatchCardTap = false

    let match: Match
    let container: DependencyContainer

    var body: some View {
        Group {
            if match.shouldPollLiveUpdates {
                LiveMatchView(match: match, container: container)
            } else {
                MatchDetailsView(match: match, container: container)
            }
        }
        .hidesBottomTabBar()
        .task {
            guard didRecordMatchCardTap == false else { return }
            didRecordMatchCardTap = true
            await adsManager.recordInterstitialTap(.matchCard)
        }
    }
}

// MARK: - Last Updated Banner

/// Offline cache timestamp shown when network data is unavailable.
struct LastUpdatedBanner: View {
    @Environment(\.colorScheme) private var colorScheme

    let date: Date

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        HStack(spacing: Spacing.small) {
            Image(systemName: "clock.arrow.circlepath")
            Text("Last updated \(DateFormatters.relativeTime(for: date))")
                .font(Typography.caption)
        }
        .foregroundStyle(palette.secondaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.medium)
        .background(palette.elevatedBackground, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}
