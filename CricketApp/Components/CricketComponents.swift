import SwiftUI
#if canImport(GoogleMobileAds) && canImport(UIKit)
import GoogleMobileAds
import UIKit
#endif

// MARK: - Glass Card

/// Card surface style — solid is much cheaper while scrolling than material blur.
enum GlassCardSurface {
    case material
    case solid
}

/// Lightweight material container used for individual repeated content.
struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    private let padding: CGFloat
    private let surface: GlassCardSurface
    private let content: Content

    init(
        padding: CGFloat = Spacing.large,
        surface: GlassCardSurface = .material,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.surface = surface
        self.content = content()
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .fill(surface == .material ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(palette.card))
            }
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .stroke(palette.divider.opacity(0.55), lineWidth: 1)
            }
            .shadow(
                color: palette.shadow.opacity(surface == .material ? 1 : 0.35),
                radius: surface == .material ? 16 : 6,
                x: 0,
                y: surface == .material ? 8 : 3
            )
    }
}

// MARK: - Section Header

/// Screen section title with an optional symbol and subtitle.
struct SectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String?
    let systemImage: String?

    init(_ title: String, subtitle: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(palette.primary)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(title)
                    .font(Typography.title)
                    .foregroundStyle(palette.text)

                if let subtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(palette.secondaryText)
                }
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Live Badge

/// Blinking red live indicator with SF Symbol animation prefix.
struct LiveBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var animated: Bool = true

    var body: some View {
        if animated == false || reduceMotion {
            badgeContent(isBright: true)
        } else {
            TimelineView(.periodic(from: .now, by: 0.7)) { context in
                let phase = context.date.timeIntervalSinceReferenceDate / 0.7
                let isBright = phase.truncatingRemainder(dividingBy: 2) < 1
                badgeContent(isBright: isBright)
            }
        }
    }

    private func badgeContent(isBright: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 11, weight: .bold))

            Text("LIVE")
                .font(Typography.monoCaption.weight(.bold))
                .tracking(0.5)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.12, blue: 0.15).opacity(isBright ? 1.0 : 0.72),
                            Color(red: 0.80, green: 0.05, blue: 0.10).opacity(isBright ? 0.95 : 0.62)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(isBright ? 0.45 : 0.15), lineWidth: 1)
        }
        .shadow(color: Color.red.opacity(isBright && animated ? 0.65 : 0.25), radius: isBright && animated ? 8 : 3, x: 0, y: 0)
        .scaleEffect(isBright && animated ? 1.0 : 0.98)
        .opacity(isBright || animated == false ? 1.0 : 0.82)
        .accessibilityLabel("Live match in progress")
    }
}

// MARK: - Match Status Badge

/// Display badge for match state (Live, Upcoming, Result).
struct MatchStatusBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    let match: Match
    var animateLiveBadge: Bool = false

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        if match.isLiveMatch {
            LiveBadge(animated: animateLiveBadge)
        } else {
            let labelText: String = {
                switch match.state {
                case .upcoming:
                    return "Upcoming"
                case .completed:
                    return "Result"
                case .live:
                    return "Live"
                }
            }()

            HStack(spacing: 4) {
                if match.state == .upcoming {
                    Image(systemName: "clock")
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(labelText)
                    .font(Typography.caption.weight(.medium))
            }
            .foregroundStyle(palette.primary)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(palette.primary.opacity(0.12), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(palette.primary.opacity(0.2), lineWidth: 1)
            }
        }
    }
}

// MARK: - Team Logo

/// Team logo with a native fallback monogram.
struct TeamLogoView: View {
    @Environment(\.colorScheme) private var colorScheme

    let team: Team
    let size: CGFloat

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        ZStack {
            Circle()
                .fill(palette.elevatedBackground)

            if let logoURL = team.logoURL {
                CachedAsyncImage(url: logoURL) {
                    monogram(palette)
                }
                .scaledToFit()
                .clipShape(Circle())
                .padding(Spacing.xSmall)
            } else {
                monogram(palette)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func monogram(_ palette: ColorPalette) -> some View {
        Text(team.shortName.prefix(2))
            .font(.system(size: max(12, size * 0.32), weight: .bold, design: .rounded))
            .foregroundStyle(palette.primary)
    }
}

// MARK: - Score Header

/// Hero scoreboard header for live and scorecard screens.
struct ScoreHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let match: Match
    var animatesScoreChanges: Bool = true

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        VStack(spacing: Spacing.large) {
            HStack {
                teamColumn(match.homeTeam, alignment: .leading)

                Text("vs")
                    .font(Typography.caption)
                    .foregroundStyle(palette.secondaryText)
                    .padding(.horizontal, Spacing.small)

                teamColumn(match.awayTeam, alignment: .trailing)
            }

            Group {
                Text(match.status)
                    .font(Typography.headline)
                    .foregroundStyle(palette.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .modifier(ScoreTextTransitionModifier(enabled: animatesScoreChanges))
        }
        .accessibilityElement(children: .combine)
    }

    private func teamColumn(_ team: Team, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: Spacing.small) {
            TeamLogoView(team: team, size: 52)

            Text(team.shortName)
                .font(Typography.headline)

            if let score = team.score {
                Text(score.displayText)
                    .font(Typography.monoScore)

                Text(score.overText)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(team.name)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}

private struct ScoreTextTransitionModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.contentTransition(.numericText())
        } else {
            content
        }
    }
}

// MARK: - Match Card

/// Fixture, result, or live-match card.
struct MatchCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let match: Match
    let isProminent: Bool

    init(match: Match, isProminent: Bool = false) {
        self.match = match
        self.isProminent = isProminent
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        GlassCard(
            padding: isProminent ? Spacing.xLarge : Spacing.large,
            surface: isProminent ? .material : .solid
        ) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text(match.competition)
                            .font(Typography.caption)
                            .foregroundStyle(palette.secondaryText)

                        Text(match.title)
                            .font(isProminent ? Typography.title : Typography.headline)
                            .foregroundStyle(palette.text)
                            .lineLimit(2)
                    }

                    Spacer(minLength: Spacing.medium)

                    MatchStatusBadge(match: match, animateLiveBadge: isProminent)
                }

                ScoreHeader(match: match, animatesScoreChanges: isProminent)

                HStack(spacing: Spacing.small) {
                    Label(match.venue, systemImage: "mappin.and.ellipse")

                    Spacer(minLength: Spacing.small)

                    if let scheduleLabel = match.displayScheduleLabel {
                        Text(scheduleLabel)
                            .font(Typography.caption)
                            .foregroundStyle(palette.secondaryText)
                    }
                }
                .font(Typography.caption)
                .foregroundStyle(palette.secondaryText)
            }
        }
    }
}

// MARK: - Ranking Card

/// Ranking row optimized for scanning.
struct RankingCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let entry: RankingEntry

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        GlassCard(padding: Spacing.medium) {
            HStack(spacing: Spacing.medium) {
                Text("#\(entry.rank)")
                    .font(Typography.monoScore)
                    .foregroundStyle(palette.primary)
                    .frame(width: 54, alignment: .leading)

                PlayerCard(entry: entry)

                Spacer(minLength: Spacing.small)

                Text("\(entry.rating)")
                    .font(Typography.monoScore)
                    .foregroundStyle(palette.text)
            }
        }
    }
}

// MARK: - Player Card

/// Compact player identity block used inside rankings.
struct PlayerCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let entry: RankingEntry

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        HStack(spacing: Spacing.medium) {
            Circle()
                .fill(palette.primary.opacity(0.13))
                .overlay {
                    Text(entry.name.prefix(1))
                        .font(Typography.headline)
                        .foregroundStyle(palette.primary)
                }
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(entry.name)
                    .font(Typography.headline)
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(entry.country.isEmpty ? "International" : entry.country)
                    .font(Typography.caption)
                    .foregroundStyle(palette.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Commentary Card

/// Ball-by-ball commentary row with event-specific coloring.
struct CommentaryCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let event: BallEvent

    var body: some View {
        let palette = Theme.palette(for: colorScheme)
        let color = eventColor(event.type, palette: palette)

        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(spacing: Spacing.xSmall) {
                Text(event.ballLabel)
                    .font(Typography.monoCaption)

                BallOutcomeBadge(event: event, color: color)
            }
            .foregroundStyle(color)
            .frame(width: 46)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(event.type.label)
                    .font(Typography.caption)
                    .foregroundStyle(color)

                Text(event.text)
                    .font(Typography.body)
                    .foregroundStyle(palette.text)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.medium)
        .background(color.opacity(colorScheme == .dark ? 0.14 : 0.10), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func eventColor(_ type: CommentaryEventType, palette: ColorPalette) -> Color {
        switch type {
        case .four:
            palette.success
        case .six:
            palette.secondary
        case .wicket:
            palette.error
        case .dot:
            palette.secondaryText
        case .wide:
            palette.warning
        case .noBall:
            palette.accent
        case .run:
            palette.primary
        case .note:
            palette.secondaryText
        }
    }
}

/// A compact result marker that makes each delivery scannable without reading its commentary.
private struct BallOutcomeBadge: View {
    let event: BallEvent
    let color: Color

    private var label: String {
        switch event.type {
        case .four:
            "4"
        case .six:
            "6"
        case .wicket:
            "W"
        case .dot:
            "0"
        case .wide:
            event.runs > 1 ? "\(event.runs)WD" : "WD"
        case .noBall:
            event.runs > 1 ? "\(event.runs)NB" : "NB"
        case .run, .note:
            "\(event.runs)"
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .background(color.opacity(0.18), in: Circle())
            .overlay {
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 1)
            }
            .accessibilityLabel("Ball result: \(label)")
    }
}

// MARK: - Gradient Button

/// Premium primary action button.
struct GradientButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Typography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.medium)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(
            LinearGradient(colors: [Color(hex: 0x1E5BE8), Color(hex: 0xF57C1F)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
        )
        .accessibilityLabel(title)
    }
}

// MARK: - Loading View

/// Polished loading state used by feature screens.
struct LoadingView: View {
    var body: some View {
        VStack(spacing: Spacing.large) {
            SkeletonView(height: 180)
            SkeletonView(height: 86)
            SkeletonView(height: 86)
        }
        .accessibilityLabel("Loading")
    }
}

// MARK: - Skeleton View

/// Shimmer placeholder for pending content.
struct SkeletonView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var shimmerOffset = -0.8

    let height: CGFloat

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
            .fill(palette.elevatedBackground)
            .overlay {
                LinearGradient(
                    colors: [.clear, palette.card.opacity(0.45), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .offset(x: shimmerOffset * 320)
                .blendMode(.plusLighter)
            }
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .frame(height: height)
            .onAppear {
                withAnimation(AppAnimation.shimmer) {
                    shimmerOffset = 0.9
                }
            }
    }
}

// MARK: - Error View

/// User-friendly error surface with retry support.
struct ErrorView: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let message: String
    let retry: (() -> Void)?

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        VStack(spacing: Spacing.large) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(palette.error)

            VStack(spacing: Spacing.small) {
                Text(title)
                    .font(Typography.title)
                    .foregroundStyle(palette.text)

                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let retry {
                GradientButton(title: "Retry", systemImage: "arrow.clockwise", action: retry)
            }
        }
        .padding(Spacing.xLarge)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Empty State

/// Empty state for no-data surfaces.
struct EmptyState: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        VStack(spacing: Spacing.medium) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(palette.primary)

            Text(title)
                .font(Typography.title)
                .foregroundStyle(palette.text)

            Text(message)
                .font(Typography.body)
                .foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xLarge)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Search Bar

/// Native-feeling search field reusable outside toolbar search.
struct SearchBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var text: String

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        HStack(spacing: Spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(palette.secondaryText)

            TextField("Search matches, teams, venues...", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if text.isEmpty == false {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(palette.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(Spacing.medium)
        .background(palette.elevatedBackground, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }
}

// MARK: - Filter Chip

/// Selectable chip for compact filters.
struct FilterChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        Button(action: action) {
            Text(title)
                .font(Typography.caption)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .frame(minHeight: 34)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .white : palette.text)
        .background(
            isSelected ? palette.primary : palette.elevatedBackground,
            in: Capsule()
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Settings Row

/// Legacy settings row. Prefer dedicated settings components for new screens.
struct SettingsRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String?
    let systemImage: String
    let action: (() -> Void)?

    init(title: String, value: String? = nil, systemImage: String, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        if let action {
            Button(action: action) {
                rowContent(showsChevron: true)
            }
            .buttonStyle(.plain)
        } else {
            rowContent(showsChevron: false)
        }
    }

    private func rowContent(showsChevron: Bool) -> some View {
        let palette = Theme.palette(for: colorScheme)

        return HStack(spacing: Spacing.medium) {
            Image(systemName: systemImage)
                .foregroundStyle(palette.primary)
                .frame(width: 28)

            Text(title)
                .font(Typography.body)
                .foregroundStyle(palette.text)

            Spacer(minLength: Spacing.medium)

            if let value {
                Text(value)
                    .font(Typography.caption)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.trailing)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryText)
            }
        }
        .padding(.vertical, Spacing.small)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Update Sheet

/// Native update prompt shown when the App Store has a newer version.
struct UpdateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let update: AppUpdate

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        VStack(spacing: Spacing.xLarge) {
            Image(systemName: "arrow.down.app.fill")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(palette.primary)

            VStack(spacing: Spacing.small) {
                Text("Update Available")
                    .font(Typography.largeTitle)
                    .foregroundStyle(palette.text)

                Text("Version \(update.storeVersion) is available. You are using \(update.currentVersion).")
                    .font(Typography.body)
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let appStoreURL = update.appStoreURL {
                Link(destination: appStoreURL) {
                    Label("Open App Store", systemImage: "arrow.up.forward.app")
                        .font(Typography.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Not Now") {
                dismiss()
            }
            .buttonStyle(.borderless)
        }
        .padding(Spacing.xLarge)
        .presentationDetents([.medium])
    }
}

// MARK: - Banner View

#if canImport(GoogleMobileAds) && canImport(UIKit)
/// Google Mobile Ads banner bridge.
struct BannerView: UIViewRepresentable {
    let adUnitId: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitId
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
    }
}
#else
/// No-op banner placeholder when Google Mobile Ads is not linked.
struct BannerView: View {
    let adUnitId: String

    var body: some View {
        EmptyView()
    }
}
#endif

// MARK: - Native Ad View

/// Native ad surface placeholder. It renders only when a real SDK-backed implementation is supplied.
struct NativeAdView: View {
    let adUnitId: String

    var body: some View {
        EmptyView()
    }
}
