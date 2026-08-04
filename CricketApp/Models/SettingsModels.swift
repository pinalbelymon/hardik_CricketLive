import Foundation

// MARK: - Ad Configuration

/// Remote ad settings loaded from Firestore when available.
/// Frequency fields fall back to `AppConstants.Ads` when missing remotely.
struct AdConfiguration: Codable, Hashable, Sendable {
    let isShowAds: Bool
    let adaptiveBannerAdUnitId: String
    let interstitialAdUnitId: String
    let nativeAdUnitId: String
    let openAdUnitId: String

    // Native frequency
    let homeNativeAdEveryMatchCards: Int
    let homeNativeAdMaxPerSection: Int
    let fixturesNativeAdEveryMatchCards: Int
    let fixturesNativeAdMaxPerSection: Int
    let oversNativeAdEveryCards: Int
    let oversNativeAdMax: Int

    // Interstitial tap frequency (`0` = disabled for that action)
    let interstitialEveryMatchCardTaps: Int
    let interstitialEveryScorecardTaps: Int
    let interstitialEveryCommentaryTaps: Int
    let interstitialEveryOversTaps: Int

    static let disabled = AdConfiguration(
        isShowAds: false,
        adaptiveBannerAdUnitId: "",
        interstitialAdUnitId: "",
        nativeAdUnitId: "",
        openAdUnitId: "",
        homeNativeAdEveryMatchCards: AppConstants.Ads.homeNativeAdEveryMatchCards,
        homeNativeAdMaxPerSection: AppConstants.Ads.homeNativeAdMaxPerSection,
        fixturesNativeAdEveryMatchCards: AppConstants.Ads.fixturesNativeAdEveryMatchCards,
        fixturesNativeAdMaxPerSection: AppConstants.Ads.fixturesNativeAdMaxPerSection,
        oversNativeAdEveryCards: AppConstants.Ads.oversNativeAdEveryCards,
        oversNativeAdMax: AppConstants.Ads.oversNativeAdMax,
        interstitialEveryMatchCardTaps: AppConstants.Ads.interstitialEveryMatchCardTaps,
        interstitialEveryScorecardTaps: AppConstants.Ads.interstitialEveryScorecardTaps,
        interstitialEveryCommentaryTaps: AppConstants.Ads.interstitialEveryCommentaryTaps,
        interstitialEveryOversTaps: AppConstants.Ads.interstitialEveryOversTaps
    )

    /// Builds config from Firestore fields, filling gaps from `AppConstants.Ads`.
    static func fromFirestoreData(_ data: [String: Any]) -> AdConfiguration {
        AdConfiguration(
            isShowAds: data.boolValue(for: "isShowAds") ?? false,
            adaptiveBannerAdUnitId: data.stringValue(for: "adaptiveBannerAdUnitId") ?? "",
            interstitialAdUnitId: data.stringValue(for: "interstitialAdUnitId") ?? "",
            nativeAdUnitId: data.stringValue(for: "nativeAdUnitId") ?? "",
            openAdUnitId: data.stringValue(for: "openAdUnitId") ?? "",
            homeNativeAdEveryMatchCards: data.intValue(for: "homeNativeAdEveryMatchCards")
                ?? AppConstants.Ads.homeNativeAdEveryMatchCards,
            homeNativeAdMaxPerSection: data.intValue(for: "homeNativeAdMaxPerSection")
                ?? AppConstants.Ads.homeNativeAdMaxPerSection,
            fixturesNativeAdEveryMatchCards: data.intValue(for: "fixturesNativeAdEveryMatchCards")
                ?? AppConstants.Ads.fixturesNativeAdEveryMatchCards,
            fixturesNativeAdMaxPerSection: data.intValue(for: "fixturesNativeAdMaxPerSection")
                ?? AppConstants.Ads.fixturesNativeAdMaxPerSection,
            oversNativeAdEveryCards: data.intValue(for: "oversNativeAdEveryCards")
                ?? AppConstants.Ads.oversNativeAdEveryCards,
            oversNativeAdMax: data.intValue(for: "oversNativeAdMax")
                ?? AppConstants.Ads.oversNativeAdMax,
            interstitialEveryMatchCardTaps: data.intValue(for: "interstitialEveryMatchCardTaps")
                ?? AppConstants.Ads.interstitialEveryMatchCardTaps,
            interstitialEveryScorecardTaps: data.intValue(for: "interstitialEveryScorecardTaps")
                ?? AppConstants.Ads.interstitialEveryScorecardTaps,
            interstitialEveryCommentaryTaps: data.intValue(for: "interstitialEveryCommentaryTaps")
                ?? AppConstants.Ads.interstitialEveryCommentaryTaps,
            interstitialEveryOversTaps: data.intValue(for: "interstitialEveryOversTaps")
                ?? AppConstants.Ads.interstitialEveryOversTaps
        )
    }

    /// Local production/DEBUG fallback when Firebase is unavailable or fetch fails.
    static func localFallback(
        isShowAds: Bool,
        adaptiveBannerAdUnitId: String,
        interstitialAdUnitId: String,
        nativeAdUnitId: String,
        openAdUnitId: String
    ) -> AdConfiguration {
        AdConfiguration(
            isShowAds: isShowAds,
            adaptiveBannerAdUnitId: adaptiveBannerAdUnitId,
            interstitialAdUnitId: interstitialAdUnitId,
            nativeAdUnitId: nativeAdUnitId,
            openAdUnitId: openAdUnitId,
            homeNativeAdEveryMatchCards: AppConstants.Ads.homeNativeAdEveryMatchCards,
            homeNativeAdMaxPerSection: AppConstants.Ads.homeNativeAdMaxPerSection,
            fixturesNativeAdEveryMatchCards: AppConstants.Ads.fixturesNativeAdEveryMatchCards,
            fixturesNativeAdMaxPerSection: AppConstants.Ads.fixturesNativeAdMaxPerSection,
            oversNativeAdEveryCards: AppConstants.Ads.oversNativeAdEveryCards,
            oversNativeAdMax: AppConstants.Ads.oversNativeAdMax,
            interstitialEveryMatchCardTaps: AppConstants.Ads.interstitialEveryMatchCardTaps,
            interstitialEveryScorecardTaps: AppConstants.Ads.interstitialEveryScorecardTaps,
            interstitialEveryCommentaryTaps: AppConstants.Ads.interstitialEveryCommentaryTaps,
            interstitialEveryOversTaps: AppConstants.Ads.interstitialEveryOversTaps
        )
    }

    func interstitialEveryTaps(for action: InterstitialTapAction) -> Int {
        switch action {
        case .matchCard:
            interstitialEveryMatchCardTaps
        case .scorecard:
            interstitialEveryScorecardTaps
        case .commentary:
            interstitialEveryCommentaryTaps
        case .overs:
            interstitialEveryOversTaps
        }
    }
}

// MARK: - Firestore value helpers

private extension Dictionary where Key == String, Value == Any {
    func stringValue(for key: String) -> String? {
        if let value = self[key] as? String { return value }
        if let value = self[key] as? NSNumber { return value.stringValue }
        return nil
    }

    func boolValue(for key: String) -> Bool? {
        if let value = self[key] as? Bool { return value }
        if let value = self[key] as? NSNumber { return value.boolValue }
        return nil
    }

    func intValue(for key: String) -> Int? {
        if let value = self[key] as? Int { return value }
        if let value = self[key] as? NSNumber { return value.intValue }
        if let value = self[key] as? String, let int = Int(value) { return int }
        return nil
    }
}

// MARK: - App Update

/// App Store update check result.
struct AppUpdate: Identifiable, Hashable, Sendable {
    let id = UUID()
    let currentVersion: String
    let storeVersion: String
    let appStoreURL: URL?

    var isAvailable: Bool {
        storeVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }
}

// MARK: - Developer Info

/// Static app metadata surfaced in Settings.
struct DeveloperInfo: Hashable, Sendable {
    let name: String
    let email: String
    let website: URL?

    static let current = DeveloperInfo(
        name: "Vivek Malani",
        email: "support@example.com",
        website: URL(string: "https://example.com")
    )
}
