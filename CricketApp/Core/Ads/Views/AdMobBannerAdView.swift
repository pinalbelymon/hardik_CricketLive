import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - Adaptive Banner Ad View

/// Inline banner with locked 50pt height (no adaptive resize → no scroll jump).
struct AdMobBannerAdView: View {
    @EnvironmentObject private var adsManager: AdsManager
    @State private var didFail = false

    let placement: AdPlacement

    static let fixedHeight: CGFloat = 50

    var body: some View {
        Group {
            if didFail == false, let unitId = adsManager.bannerAdUnitId(for: placement) {
                FixedBannerRepresentable(
                    adUnitId: unitId,
                    onClick: { adsManager.markAdClicked() },
                    onFailed: { didFail = true }
                )
                .frame(maxWidth: .infinity)
                .frame(height: Self.fixedHeight)
                .clipped()
                .accessibilityLabel("Advertisement")
            }
        }
        .transaction { $0.animation = nil }
    }
}

// MARK: - Sticky Bottom Banner

/// Bottom overlay for Scorecard / Overs.
///
/// Always reserves a fixed 50pt while ads are enabled/preparing so `safeAreaInset`
/// does not appear mid-scroll and jerk content downward.
struct StickyBottomBannerAdView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var adsManager: AdsManager
    @State private var didFail = false

    let placement: AdPlacement

    private let height = AdMobBannerAdView.fixedHeight

    /// Keep inset reserved before the unit id is ready / while loading.
    private var shouldReserveSpace: Bool {
        guard didFail == false else { return false }
        if adsManager.bannerAdUnitId(for: placement) != nil { return true }
        switch adsManager.bootstrapState {
        case .preparing:
            return true
        case .ready(let enabled):
            return enabled
        case .idle, .failed:
            return false
        }
    }

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        Group {
            if shouldReserveSpace {
                ZStack {
                    if let unitId = adsManager.bannerAdUnitId(for: placement) {
                        FixedBannerRepresentable(
                            adUnitId: unitId,
                            onClick: { adsManager.markAdClicked() },
                            onFailed: { didFail = true }
                        )
                        .accessibilityLabel("Advertisement")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()
                .background {
                    Rectangle()
                        .fill(palette.background.opacity(0.96))
                        .shadow(color: .black.opacity(0.18), radius: 8, y: -2)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
        }
        .transaction { $0.animation = nil }
    }
}

// MARK: - Representable

#if canImport(GoogleMobileAds) && canImport(UIKit)
private struct FixedBannerRepresentable: UIViewRepresentable {
    let adUnitId: String
    let onClick: () -> Void
    let onFailed: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onClick: onClick, onFailed: onFailed)
    }

    func makeUIView(context: Context) -> GoogleMobileAds.BannerView {
        let banner = GoogleMobileAds.BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitId
        banner.rootViewController = Self.keyRootViewController()
        banner.delegate = context.coordinator
        banner.backgroundColor = .clear
        if context.coordinator.didRequestLoad == false {
            context.coordinator.didRequestLoad = true
            banner.load(Request())
        }
        return banner
    }

    func updateUIView(_ uiView: GoogleMobileAds.BannerView, context: Context) {
        uiView.rootViewController = Self.keyRootViewController()
    }

    private static func keyRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        let onClick: () -> Void
        let onFailed: () -> Void
        var didRequestLoad = false
        private var hasFailed = false

        init(onClick: @escaping () -> Void, onFailed: @escaping () -> Void) {
            self.onClick = onClick
            self.onFailed = onFailed
        }

        func bannerView(
            _ bannerView: GoogleMobileAds.BannerView,
            didFailToReceiveAdWithError error: Error
        ) {
            guard hasFailed == false else { return }
            hasFailed = true
            onFailed()
        }

        func bannerViewDidRecordClick(_ bannerView: GoogleMobileAds.BannerView) {
            onClick()
        }
    }
}
#else
private struct FixedBannerRepresentable: View {
    let adUnitId: String
    let onClick: () -> Void
    let onFailed: () -> Void

    var body: some View {
        EmptyView()
            .onAppear { onFailed() }
    }
}
#endif
