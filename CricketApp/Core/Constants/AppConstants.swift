import Foundation

// MARK: - App Constants

/// Centralized constants for API hosts, product metadata, and remote config defaults.
enum AppConstants {
    static let appName = "CricPlus"
    static let appId = "id6793374045"
    static let bundleIdentifier = "com.cricpluse"
    static let appStoreCountryCode = "us"
    static let adMobApplicationIdentifier = "ca-app-pub-2967653914154128~8505999335"

    enum API {
        static let cricketAustraliaBaseURL = makeURL("https://apiv2.cricket.com.au/mobile/views/")
        static let cricnetRankingsURL = makeURL("http://dabbatoken.cricnet.co.in/api/values/Ranking")
        static let iTunesLookupURL = makeURL("https://itunes.apple.com/lookup")
    }

    enum Firestore {
        /// Collection holding the single iOS ads document.
        static let adConfigurationCollection = "ad_configuration"
        /// Preferred document ID (create this in Firebase Console).
        static let adConfigurationDocument = "ios"
    }

    enum IAP {
        /// Non-consumable lifetime unlock — create this product in App Store Connect.
        static let lifetimeRemoveAdsProductId = "com.cricpluse.lifetime.removeads"

        static let privacyPolicyURL = URL(string: "https://belymoninfotech.com/app/cricplus/privacypolicy.html")!
        static let termsOfUseURL = URL(string: "https://belymoninfotech.com/app/cricplus/termsofuse.html")!
        /// Apple Standard EULA (required when you don't host a custom paid-apps EULA).
        static let appleEULAURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    }

    enum Ads {
        /// When Firestore is not linked, DEBUG builds enable ads with Google sample units
        /// so you can verify integration immediately.
        static let enableAdsInDebugWithoutRemoteConfig = false

        /// Release fallback when Firestore is unavailable. Keep `false` until real
        /// AdMob unit IDs below are filled in (sample units must not ship to production).
        static let enableAdsInReleaseWithoutRemoteConfig = false

        /// Production AdMob unit IDs (replace empties with your AdMob console units).
        static let bannerAdUnitId = ""
        static let interstitialAdUnitId = ""
        static let nativeAdUnitId = ""
        static let openAdUnitId = ""

        // MARK: Native frequency (edit these to tune placements)

        /// Home lists: show 1 native ad after every N match cards (change `4` → `2` for denser ads).
        static let homeNativeAdEveryMatchCards = 4
        /// Max native ads per Home section (upcoming / results / search).
        static let homeNativeAdMaxPerSection = 3

        /// Fixtures tab: show 1 native ad after every N match cards.
        static let fixturesNativeAdEveryMatchCards = 4
        /// Max native ads per Fixtures date group.
        static let fixturesNativeAdMaxPerSection = 5

        /// Overs screen: show 1 native ad after every N over cards (change `10` → `5` for denser ads).
        static let oversNativeAdEveryCards = 10
        /// Max native ads on the Overs screen.
        static let oversNativeAdMax = 3

        // MARK: Interstitial tap frequency (edit these — set `0` to disable)

        /// After every N match-card opens (Home / Fixtures / Live list), show an interstitial.
        static let interstitialEveryMatchCardTaps = 6
        /// After every N Scorecard opens, show an interstitial.
        static let interstitialEveryScorecardTaps = 6
        /// After every N Commentary opens, show an interstitial.
        static let interstitialEveryCommentaryTaps = 6
        /// After every N Overs opens, show an interstitial.
        static let interstitialEveryOversTaps = 6
    }

    private static func makeURL(_ value: String) -> URL {
        guard let url = URL(string: value) else {
            preconditionFailure("Invalid static URL: \(value)")
        }
        return url
    }
}
