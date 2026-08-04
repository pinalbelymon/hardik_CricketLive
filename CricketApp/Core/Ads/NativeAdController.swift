import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - Native Ad Controller

/// Loads a single native ad for SwiftUI bridging.
/// Call `cancelInFlightLoad()` when a list cell scrolls away so waiters/gates never leak.
@MainActor
final class NativeAdController: NSObject, ObservableObject {
    @Published private(set) var loadState: AdLoadState = .idle

    private var adUnitId: String = ""
    private var isLoading = false

    #if canImport(GoogleMobileAds)
    @Published private(set) var nativeAd: NativeAd?
    private var adLoader: AdLoader?
    private var loadContinuation: CheckedContinuation<Void, Never>?
    #endif

    func configure(adUnitId: String) {
        self.adUnitId = adUnitId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func load() async {
        guard adUnitId.isEmpty == false else {
            loadState = .failed(message: "Missing native ad unit id")
            return
        }

        switch loadState {
        case .loaded, .failed:
            return
        case .idle, .loading:
            break
        }

        guard isLoading == false else { return }

        #if canImport(GoogleMobileAds)
        isLoading = true
        loadState = .loading
        defer { isLoading = false }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            loadContinuation = continuation

            let imageOptions = NativeAdImageAdLoaderOptions()
            imageOptions.shouldRequestMultipleImages = false

            let root = Self.topViewController()
            let loader = AdLoader(
                adUnitID: adUnitId,
                rootViewController: root,
                adTypes: [.native],
                options: [imageOptions]
            )
            loader.delegate = self
            adLoader = loader
            loader.load(Request())
        }
        #else
        loadState = .failed(message: "Google Mobile Ads SDK not linked")
        #endif
    }

    /// Cancels an in-flight request (list cell scrolled away). Resumes any waiter.
    func cancelInFlightLoad() {
        #if canImport(GoogleMobileAds)
        guard loadContinuation != nil || isLoading else { return }
        adLoader?.delegate = nil
        adLoader = nil
        nativeAd = nil
        loadState = .failed(message: "Cancelled")
        finishLoad()
        isLoading = false
        #endif
    }

    /// Resets only after a scroll-away cancel so a recycled cell can retry.
    /// Permanent no-fills stay failed (avoids infinite reload blink).
    func resetForRetryIfCancelled() {
        guard case .failed(let message) = loadState, message == "Cancelled" else { return }
        loadState = .idle
        #if canImport(GoogleMobileAds)
        nativeAd = nil
        adLoader = nil
        #endif
        isLoading = false
    }

    #if canImport(GoogleMobileAds)
    private func finishLoad() {
        loadContinuation?.resume()
        loadContinuation = nil
    }
    #endif

    #if canImport(UIKit)
    private static func topViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
    #endif
}

#if canImport(GoogleMobileAds)
extension NativeAdController: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.nativeAd = nativeAd
        loadState = .loaded
        self.adLoader = nil
        finishLoad()
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        nativeAd = nil
        loadState = .failed(message: error.localizedDescription)
        self.adLoader = nil
        finishLoad()
    }
}
#endif
