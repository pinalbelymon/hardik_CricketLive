import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - Interstitial Controller

/// Loads and presents interstitial ads at caller-chosen natural breaks.
@MainActor
final class InterstitialAdController: NSObject {
    private(set) var loadState: AdLoadState = .idle
    private var adUnitId: String = ""
    private var isLoading = false

    #if canImport(GoogleMobileAds)
    private var interstitial: InterstitialAd?
    #endif

    func configure(adUnitId: String) {
        self.adUnitId = adUnitId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Prefetch an interstitial. Safe to call repeatedly; coalesces in-flight loads.
    func preload() async {
        guard adUnitId.isEmpty == false else {
            loadState = .failed(message: "Missing interstitial ad unit id")
            return
        }
        guard isLoading == false else { return }

        #if canImport(GoogleMobileAds)
        isLoading = true
        loadState = .loading
        defer { isLoading = false }

        do {
            let ad = try await InterstitialAd.load(with: adUnitId, request: Request())
            ad.fullScreenContentDelegate = self
            interstitial = ad
            loadState = .loaded
        } catch {
            interstitial = nil
            loadState = .failed(message: error.localizedDescription)
        }
        #else
        loadState = .failed(message: "Google Mobile Ads SDK not linked")
        #endif
    }

    var isReady: Bool {
        #if canImport(GoogleMobileAds)
        interstitial != nil && loadState == .loaded
        #else
        false
        #endif
    }

    /// Presents if loaded. Returns `true` when presentation started.
    @discardableResult
    func presentIfReady(from viewController: UIViewController? = nil) -> Bool {
        #if canImport(GoogleMobileAds)
        guard let interstitial else { return false }
        let host = viewController ?? Self.topViewController()
        guard let host else { return false }
        interstitial.present(from: host)
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
extension InterstitialAdController: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitial = nil
        loadState = .idle
        // Warm the next ad asynchronously without blocking UI.
        Task { await preload() }
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        interstitial = nil
        loadState = .failed(message: error.localizedDescription)
        Task { await preload() }
    }
}
#endif
