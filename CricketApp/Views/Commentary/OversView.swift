import SwiftUI

// MARK: - Overs View

/// A quick over-by-over score view built from the same delivery feed as commentary.
struct OversView: View {
    private enum ScrollAnchor {
        static let top = "overs-top"
    }

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var adsManager: AdsManager
    @ObservedObject private var lifecycleManager = AppLifecycleManager.shared
    @StateObject private var viewModel: CommentaryViewModel
    @State private var didRecordInterstitialTap = false

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
        let nativeInterval = adsManager.configuration.oversNativeAdEveryCards
        let maxNativeAds = adsManager.configuration.oversNativeAdMax

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.medium) {
                    Color.clear
                        .frame(height: 1)
                        .id(ScrollAnchor.top)

                    if viewModel.isLoading {
                        LoadingView()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.overGroups.isEmpty {
                        ErrorView(title: "Could not load overs", message: errorMessage) {
                            Task { await viewModel.load(force: true) }
                        }
                    } else if viewModel.overGroups.isEmpty {
                        EmptyState(title: "No overs yet", message: "Over summaries will appear once play begins.", systemImage: "circle.grid.3x3")
                    } else {
                        SectionHeader("Over-by-Over", subtitle: "Quick delivery scores", systemImage: "circle.grid.3x3.fill")

                        ForEach(Array(viewModel.overGroups.enumerated()), id: \.element.id) { index, group in
                            OverSummaryCard(group: group)

                            let cardNumber = index + 1
                            if nativeInterval > 0,
                               cardNumber.isMultiple(of: nativeInterval),
                               cardNumber / nativeInterval <= maxNativeAds {
                                NativeAdFeedCard(
                                    placement: .matchDetailsNative,
                                    slotKey: "overs-\(viewModel.fixtureId)-after-\(group.overNumber)"
                                )
                            }
                        }
                    }
                }
                .padding(Spacing.large)
                .padding(.bottom, Spacing.medium + 80)
            }
            .background(palette.background)
            .navigationTitle("Overs")
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
                StickyBottomBannerAdView(placement: .oversBanner)
            }
            .task {
                guard didRecordInterstitialTap == false else { return }
                didRecordInterstitialTap = true
                await adsManager.recordInterstitialTap(.overs)
            }
        }
    }
}

// MARK: - Over Summary Card

private struct OverSummaryCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let group: CommentaryOverGroup

    private var deliveries: [BallEvent] {
        group.events.sorted(by: BallEvent.chronologicalAscending)
    }

    private var overRuns: Int {
        deliveries.reduce(0) { $0 + $1.runs }
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("Over \(group.overNumber)")
                    .font(Typography.headline)
                    .foregroundStyle(palette.text)

                Spacer(minLength: Spacing.medium)

                Text("\(overRuns) \(overRuns == 1 ? "run" : "runs")")
                    .font(Typography.caption)
                    .foregroundStyle(palette.primary)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.xSmall)
                    .background(palette.primary.opacity(0.14), in: Capsule())
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 38), spacing: Spacing.small)], alignment: .leading, spacing: Spacing.small) {
                ForEach(deliveries) { delivery in
                    OverDeliveryPill(event: delivery)
                }
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.elevatedBackground, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(palette.divider.opacity(0.7), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Over \(group.overNumber), \(overRuns) runs")
    }
}

private struct OverDeliveryPill: View {
    @Environment(\.colorScheme) private var colorScheme

    let event: BallEvent

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
    
    private var color: Color {
        let palette = Theme.palette(for: colorScheme)

        return switch event.type {
        case .four, .six: palette.secondary
        case .wicket: palette.error
        case .dot: palette.secondaryText
        case .wide: palette.warning
        case .noBall: palette.accent
        case .run: palette.primary
        case .note: palette.secondaryText
        }
    }

//    private var color: Color {
//        let palette = Theme.palette(for: colorScheme)
//        switch event.type {
//        case .four, .six:
//            palette.secondary
//        case .wicket:
//            palette.error
//        case .dot:
//            palette.secondaryText
//        case .wide:
//            palette.warning
//        case .noBall:
//            palette.accent
//        case .run:
//            palette.primary
//        case .note:
//            palette.secondaryText
//        }
//    }

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.16), in: Circle())

            Text(event.ballLabel)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.palette(for: colorScheme).secondaryText)
        }
        .accessibilityLabel("\(event.ballLabel), \(label)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OversView(
            fixtureId: PreviewData.liveMatch.fixtureId,
            inningNumber: 2,
            isLive: true,
            repository: DependencyContainer.preview().commentaryRepository
        )
    }
    .environmentObject(DependencyContainer.preview().adsManager)
}
