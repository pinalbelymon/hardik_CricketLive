import SwiftUI

// MARK: - Match Fact Row

struct MatchFactRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(palette.primary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(title.uppercased())
                    .font(Typography.caption)
                    .foregroundStyle(palette.secondaryText)

                Text(value)
                    .font(Typography.body)
                    .foregroundStyle(palette.text)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Summary Team Row

struct SummaryTeamRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let teamName: String

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        HStack {
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(palette.secondaryText)

            Spacer(minLength: Spacing.medium)

            Text(teamName)
                .font(Typography.body)
                .foregroundStyle(palette.text)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Match Centre Tile

struct MatchCentreTile: View {
    @Environment(\.colorScheme) private var colorScheme

    enum Tint {
        case primary
        case accent
        case secondary
    }

    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Tint

    private var color: Color {
        let palette = Theme.palette(for: colorScheme)

        return switch tint {
        case .primary: palette.primary
        case .accent: palette.accent
        case .secondary: palette.secondary
        }
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        VStack(alignment: .center, spacing: Spacing.small) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))

            Spacer(minLength: 0)

            Text(title)
                .font(Typography.headline)
                .foregroundStyle(palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(subtitle)
                .font(Typography.caption)
                .foregroundStyle(palette.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .center)
        .padding(Spacing.medium)
        .background(palette.elevatedBackground, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .stroke(color.opacity(0.28), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Match Centre Links

struct MatchCentreLinks: View {
    let match: Match
    let scorecardRepository: ScorecardRepositoryProtocol
    let commentaryRepository: CommentaryRepositoryProtocol

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Match Centre", subtitle: "Scores, commentary and overs", systemImage: "bolt.fill")

            HStack(spacing: Spacing.small) {
                NavigationLink {
                    ScorecardView(
                        fixtureId: match.fixtureId,
                        isLive: match.shouldPollLiveUpdates,
                        repository: scorecardRepository
                    )
                } label: {
                    MatchCentreTile(
                        title: "Scorecard",
                        subtitle: "Full score",
                        systemImage: "tablecells",
                        tint: .primary
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    CommentaryView(
                        fixtureId: match.fixtureId,
                        inningNumber: match.currentInningNumber,
                        isLive: match.shouldPollLiveUpdates,
                        repository: commentaryRepository
                    )
                } label: {
                    MatchCentreTile(
                        title: "Commentary",
                        subtitle: "Ball by ball",
                        systemImage: "text.bubble.fill",
                        tint: .accent
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    OversView(
                        fixtureId: match.fixtureId,
                        inningNumber: match.currentInningNumber,
                        isLive: match.shouldPollLiveUpdates,
                        repository: commentaryRepository
                    )
                } label: {
                    MatchCentreTile(
                        title: "Overs",
                        subtitle: "Quick view",
                        systemImage: "circle.grid.3x3.fill",
                        tint: .secondary
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Live Stat Card

struct LiveStatCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(palette.secondaryText)

            Text(value)
                .font(Typography.monoScore)
                .foregroundStyle(palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.medium)
        .background(palette.elevatedBackground, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .stroke(palette.divider.opacity(0.45), lineWidth: 1)
        }
    }
}

// MARK: - Recent Ball Chip

struct RecentBallChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let event: BallEvent

    var body: some View {
        let palette = Theme.palette(for: colorScheme)
        let accent = eventAccent(palette)

        VStack(spacing: Spacing.xSmall) {
            Text(event.ballLabel)
                .font(Typography.monoCaption)
                .foregroundStyle(palette.secondaryText)

            Text(displayValue)
                .font(Typography.monoScore)
                .foregroundStyle(accent)
        }
        .frame(width: 52, height: 56)
        .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(accent.opacity(0.35), lineWidth: 1)
        }
        .accessibilityLabel("\(event.ballLabel), \(event.type.label)")
    }

    private var displayValue: String {
        switch event.type {
        case .wicket: "W"
        case .dot: "•"
        default: "\(event.runs)"
        }
    }

    private func eventAccent(_ palette: ColorPalette) -> Color {
        switch event.type {
        case .four: palette.success
        case .six: palette.secondary
        case .wicket: palette.error
        case .wide, .noBall: palette.warning
        default: palette.primary
        }
    }
}
