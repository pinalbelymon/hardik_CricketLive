import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - App Open Ad Controller

/// Loads and presents App Open ads (cold start + return-to-foreground).
/// Follows Google guidance: 4-hour load expiry, fullscreen delegate, no mid-flow force.
@MainActor
final class AppOpenAdController: NSObject {
    private(set) var loadState: AdLoadState = .idle
    private var adUnitId: String = ""
    private var isLoading = false
    private var loadedAt: Date?

    /// Google recommends discarding app-open ads older than ~4 hours.
    private let maxAdAge: TimeInterval = 4 * 60 * 60

    #if canImport(GoogleMobileAds)
    private var appOpenAd: AppOpenAd?
    #endif

    func configure(adUnitId: String) {
        self.adUnitId = adUnitId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isReady: Bool {
        #if canImport(GoogleMobileAds)
        guard appOpenAd != nil, loadState == .loaded else { return false }
        guard let loadedAt else { return false }
        return Date().timeIntervalSince(loadedAt) < maxAdAge
        #else
        false
        #endif
    }

    func preload() async {
        guard adUnitId.isEmpty == false else {
            loadState = .failed(message: "Missing app-open ad unit id")
            return
        }
        guard isLoading == false else { return }
        if isReady { return }

        #if canImport(GoogleMobileAds)
        isLoading = true
        loadState = .loading
        defer { isLoading = false }

        do {
            let ad = try await AppOpenAd.load(with: adUnitId, request: Request())
            ad.fullScreenContentDelegate = self
            appOpenAd = ad
            loadedAt = Date()
            loadState = .loaded
        } catch {
            appOpenAd = nil
            loadedAt = nil
            loadState = .failed(message: error.localizedDescription)
        }
        #else
        loadState = .failed(message: "Google Mobile Ads SDK not linked")
        #endif
    }

    /// Presents if a fresh ad is ready. Returns `true` when presentation started.
    @discardableResult
    func presentIfReady(from viewController: UIViewController? = nil) -> Bool {
        #if canImport(GoogleMobileAds)
        guard isReady, let appOpenAd else { return false }
        let host = viewController ?? Self.topViewController()
        guard let host else { return false }

        // Avoid stacking over another modal (paywall, consent, etc.).
        if host.presentedViewController != nil {
            return false
        }

        appOpenAd.present(from: host)
        return true
        #else
        return false
        #endif
    }

    #if canImport(UIKit)
    private static func topViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
            .flatMap { root in
                var current: UIViewController? = root
                while let presented = current?.presentedViewController {
                    current = presented
                }
                return current
            }
    }
    #endif
}

#if canImport(GoogleMobileAds)
extension AppOpenAdController: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        appOpenAd = nil
        loadedAt = nil
        loadState = .idle
        Task { await preload() }
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        appOpenAd = nil
        loadedAt = nil
        loadState = .failed(message: error.localizedDescription)
        Task { await preload() }
    }
}
#endif
