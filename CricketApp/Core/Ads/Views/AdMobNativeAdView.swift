import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - Native Ad View

/// Production native ad surface. Loads only when the placement is enabled.
///
/// Usage (later):
/// ```swift
/// AdMobNativeAdView(placement: .homeFeedNative)
/// ```
struct AdMobNativeAdView: View {
    @EnvironmentObject private var adsManager: AdsManager
    @StateObject private var controller = NativeAdController()

    let placement: AdPlacement

    var body: some View {
        Group {
            if let unitId = adsManager.nativeAdUnitId(for: placement) {
                content(unitId: unitId)
            }
        }
    }

    @ViewBuilder
    private func content(unitId: String) -> some View {
        #if canImport(GoogleMobileAds) && canImport(UIKit)
        NativeAdRepresentable(
            controller: controller,
            adUnitId: unitId,
            onClick: { adsManager.markAdClicked() }
        )
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120)
        .task(id: unitId) {
            controller.configure(adUnitId: unitId)
            await controller.load()
        }
        .accessibilityLabel("Advertisement")
        #else
        EmptyView()
        #endif
    }
}

#if canImport(GoogleMobileAds) && canImport(UIKit)
private struct NativeAdRepresentable: UIViewRepresentable {
    @ObservedObject var controller: NativeAdController
    let adUnitId: String
    let onClick: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onClick: onClick)
    }

    func makeUIView(context: Context) -> GoogleMobileAds.NativeAdView {
        let nibView = buildNativeAdView()
        return nibView
    }

    func updateUIView(_ uiView: GoogleMobileAds.NativeAdView, context: Context) {
        guard let nativeAd = controller.nativeAd else { return }
        nativeAd.delegate = context.coordinator
        populate(uiView, with: nativeAd)
    }

    private func buildNativeAdView() -> GoogleMobileAds.NativeAdView {
        let adView = GoogleMobileAds.NativeAdView(frame: .zero)
        adView.backgroundColor = .secondarySystemBackground
        adView.layer.cornerRadius = 12
        adView.clipsToBounds = true

        let headline = UILabel()
        headline.font = .preferredFont(forTextStyle: .headline)
        headline.numberOfLines = 2
        headline.translatesAutoresizingMaskIntoConstraints = false

        let body = UILabel()
        body.font = .preferredFont(forTextStyle: .subheadline)
        body.textColor = .secondaryLabel
        body.numberOfLines = 2
        body.translatesAutoresizingMaskIntoConstraints = false

        let cta = UIButton(type: .system)
        cta.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        cta.translatesAutoresizingMaskIntoConstraints = false

        let adBadge = UILabel()
        adBadge.text = "Ad"
        adBadge.font = .preferredFont(forTextStyle: .caption2)
        adBadge.textColor = .secondaryLabel
        adBadge.translatesAutoresizingMaskIntoConstraints = false

        let media = MediaView()
        media.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        adView.addSubview(adBadge)
        adView.addSubview(icon)
        adView.addSubview(headline)
        adView.addSubview(body)
        adView.addSubview(media)
        adView.addSubview(cta)

        adView.headlineView = headline
        adView.bodyView = body
        adView.callToActionView = cta
        adView.mediaView = media
        adView.iconView = icon

        NSLayoutConstraint.activate([
            adBadge.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
            adBadge.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),

            icon.topAnchor.constraint(equalTo: adBadge.bottomAnchor, constant: 8),
            icon.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            icon.widthAnchor.constraint(equalToConstant: 40),
            icon.heightAnchor.constraint(equalToConstant: 40),

            headline.topAnchor.constraint(equalTo: icon.topAnchor),
            headline.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            headline.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),

            body.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 4),
            body.leadingAnchor.constraint(equalTo: headline.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: headline.trailingAnchor),

            media.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 8),
            media.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            media.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            media.heightAnchor.constraint(equalToConstant: 120),

            cta.topAnchor.constraint(equalTo: media.bottomAnchor, constant: 8),
            cta.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            cta.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            cta.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -10)
        ])

        return adView
    }

    private func populate(_ adView: GoogleMobileAds.NativeAdView, with nativeAd: NativeAd) {
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        (adView.bodyView as? UILabel)?.text = nativeAd.body
        (adView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        (adView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        adView.mediaView?.mediaContent = nativeAd.mediaContent
        adView.nativeAd = nativeAd
    }

    final class Coordinator: NSObject, NativeAdDelegate {
        let onClick: () -> Void

        init(onClick: @escaping () -> Void) {
            self.onClick = onClick
        }

        func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
            onClick()
        }
    }
}
#endif
