import Foundation

// MARK: - Ad Unit Catalog

/// Resolves production vs Google sample (test) ad unit IDs.
///
/// DEBUG / simulator builds always use Google sample units to avoid
/// accidental invalid traffic (Google Ads policy violation).
enum AdUnitCatalog {
    /// Google-provided sample units for development and QA.
    enum Sample {
        static let banner = "ca-app-pub-3940256099942544/2934735716"
        static let interstitial = "ca-app-pub-3940256099942544/4411468910"
        static let native = "ca-app-pub-3940256099942544/3986624511"
        static let appOpen = "ca-app-pub-3940256099942544/5575463023"
    }

    static var prefersSampleUnits: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    static func bannerUnitId(from configuration: AdConfiguration) -> String {
        resolved(
            production: configuration.adaptiveBannerAdUnitId,
            sample: Sample.banner
        )
    }

    static func interstitialUnitId(from configuration: AdConfiguration) -> String {
        resolved(
            production: configuration.interstitialAdUnitId,
            sample: Sample.interstitial
        )
    }

    static func nativeUnitId(from configuration: AdConfiguration) -> String {
        resolved(
            production: configuration.nativeAdUnitId,
            sample: Sample.native
        )
    }

    static func appOpenUnitId(from configuration: AdConfiguration) -> String {
        resolved(
            production: configuration.openAdUnitId,
            sample: Sample.appOpen
        )
    }

    private static func resolved(production: String, sample: String) -> String {
        if prefersSampleUnits {
            return sample
        }
        let trimmed = production.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? sample : trimmed
    }
}
