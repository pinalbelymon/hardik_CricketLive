import Foundation

// MARK: - Ad Configuration

/// Remote ad settings loaded from Firestore when available.
struct AdConfiguration: Codable, Hashable, Sendable {
    let isShowAds: Bool
    let adaptiveBannerAdUnitId: String
    let interstitialAdUnitId: String
    let nativeAdUnitId: String
    let openAdUnitId: String

    static let disabled = AdConfiguration(
        isShowAds: false,
        adaptiveBannerAdUnitId: "",
        interstitialAdUnitId: "",
        nativeAdUnitId: "",
        openAdUnitId: ""
    )
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
