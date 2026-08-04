import Foundation

// MARK: - Ad Format

/// Supported Google Mobile Ads formats for this app.
enum AdFormat: String, CaseIterable, Sendable, Codable {
    case banner
    case interstitial
    case native
    case appOpen
}

// MARK: - Ad Placement

/// Logical ad slots. Enable placements later without rewriting loaders.
///
/// All placements are **off** by default so live App Store behavior is unchanged
/// until product decides where ads appear.
enum AdPlacement: String, CaseIterable, Identifiable, Sendable, Codable {
    // Banner
    case homeBanner
    case fixturesBanner
    case liveMatchBanner
    case matchDetailsBanner
    case scorecardBanner
    case commentaryBanner
    case oversBanner
    case rankingsBanner
    case settingsBanner

    // Native
    case homeFeedNative
    case fixturesFeedNative
    case liveListNative
    case matchDetailsNative

    // Interstitial (natural breaks only — never mid-action)
    case leavingLiveMatchInterstitial
    case leavingMatchDetailsInterstitial
    case fixturesTabSwitchInterstitial
    case afterSplashInterstitial
    /// Shown after configurable navigation taps (match card / scorecard / commentary / overs).
    case engagementInterstitial

    // App Open
    /// Cold start after splash / warm return from background.
    case appOpen

    var id: String { rawValue }

    var format: AdFormat {
        switch self {
        case .homeBanner, .fixturesBanner, .liveMatchBanner, .matchDetailsBanner,
             .scorecardBanner, .commentaryBanner, .oversBanner, .rankingsBanner, .settingsBanner:
            return .banner
        case .homeFeedNative, .fixturesFeedNative, .liveListNative, .matchDetailsNative:
            return .native
        case .leavingLiveMatchInterstitial, .leavingMatchDetailsInterstitial,
             .fixturesTabSwitchInterstitial, .afterSplashInterstitial, .engagementInterstitial:
            return .interstitial
        case .appOpen:
            return .appOpen
        }
    }

    /// Human-readable label for debugging / future remote config keys.
    var debugLabel: String {
        rawValue
    }
}

// MARK: - Placement Configuration

/// Per-placement enable map. Starts fully disabled to preserve live behavior.
struct AdPlacementConfiguration: Hashable, Sendable, Codable {
    /// Placement rawValue → enabled.
    var enabledPlacements: Set<String>

    static let allDisabled = AdPlacementConfiguration(enabledPlacements: [])

    func isEnabled(_ placement: AdPlacement) -> Bool {
        enabledPlacements.contains(placement.rawValue)
    }

    mutating func setEnabled(_ placement: AdPlacement, enabled: Bool) {
        if enabled {
            enabledPlacements.insert(placement.rawValue)
        } else {
            enabledPlacements.remove(placement.rawValue)
        }
    }
}

// MARK: - Bootstrap State

enum AdsBootstrapState: Equatable, Sendable {
    case idle
    case preparing
    case ready(adsEnabled: Bool)
    case failed(message: String)
}

// MARK: - Ad Load State

enum AdLoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(message: String)
}
