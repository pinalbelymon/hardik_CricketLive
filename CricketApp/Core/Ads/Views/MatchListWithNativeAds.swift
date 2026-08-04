import SwiftUI

// MARK: - Match List With Native Ads

/// Renders match cards with lazy native-ad slots.
/// Frequencies come from `AdConfiguration` (Firestore / AppConstants fallback).
struct MatchListWithNativeAds: View {
    @EnvironmentObject private var adsManager: AdsManager

    let matches: [Match]
    let placement: AdPlacement
    let sectionKey: String
    /// Show a native ad after every N match cards (e.g. 4 → after 4th, 8th…).
    var everyMatchCards: Int
    var maxAds: Int

    init(
        matches: [Match],
        placement: AdPlacement,
        sectionKey: String,
        everyMatchCards: Int = AppConstants.Ads.homeNativeAdEveryMatchCards,
        maxAds: Int = AppConstants.Ads.homeNativeAdMaxPerSection
    ) {
        self.matches = matches
        self.placement = placement
        self.sectionKey = sectionKey
        self.everyMatchCards = everyMatchCards
        self.maxAds = maxAds
    }

    private var items: [MatchFeedItem] {
        // Wait until ads bootstrap finishes so slots do not appear mid-scroll.
        guard case .ready = adsManager.bootstrapState else {
            return matches.map { .match($0) }
        }
        let adsAllowed = adsManager.isPlacementEnabled(placement) ? maxAds : 0
        return MatchFeedItem.make(
            from: matches,
            interval: everyMatchCards,
            maxAds: adsAllowed,
            sectionKey: sectionKey
        )
    }

    var body: some View {
        ForEach(items) { item in
            switch item {
            case .match(let match):
                NavigationLink(value: match) {
                    MatchCard(match: match)
                }
                .buttonStyle(.plain)

            case .nativeAd(let slot):
                NativeAdFeedCard(
                    placement: placement,
                    slotKey: "\(sectionKey)-\(slot)"
                )
                // Keep identity stable across adsManager republishes.
                .id("\(sectionKey)-native-\(slot)")
            }
        }
    }
}
