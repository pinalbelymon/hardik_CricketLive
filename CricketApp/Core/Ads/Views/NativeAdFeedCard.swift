import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - Native Ad Feed Card

/// Lazy list native ad with a **fixed** card height while loading / loaded.
/// Failed fills collapse once (no animation) so scroll stays stable.
struct NativeAdFeedCard: View {
    @EnvironmentObject private var adsManager: AdsManager
    @StateObject private var controller = NativeAdController()

    let placement: AdPlacement
    let slotKey: String

    /// Stable height — do not measure dynamically (causes blink + scroll jump).
    private static let cardHeight: CGFloat = 320

    private var slotHeight: CGFloat {
        switch controller.loadState {
        case .idle, .loading, .loaded:
            Self.cardHeight
        case .failed:
            0
        }
    }

    var body: some View {
        Group {
            if let unitId = adsManager.nativeAdUnitId(for: placement) {
                content(unitId: unitId)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: slotHeight)
        .clipped()
        .transaction { $0.animation = nil }
    }

    @ViewBuilder
    private func content(unitId: String) -> some View {
        switch controller.loadState {
        case .idle, .loading:
            NativeAdStaticPlaceholder(height: Self.cardHeight)
                .task(id: "\(slotKey)-\(unitId)") {
                    await loadIfNeeded(unitId: unitId)
                }
        case .loaded:
            #if canImport(GoogleMobileAds) && canImport(UIKit)
            NativeAdFeedRepresentable(
                nativeAd: controller.nativeAd,
                onClick: { adsManager.markAdClicked() }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("Advertisement")
            #else
            Color.clear
            #endif
        case .failed:
            Color.clear
                .accessibilityHidden(true)
        }
    }

    private func loadIfNeeded(unitId: String) async {
        if case .failed(let message) = controller.loadState, message == "Cancelled" {
            controller.resetForRetryIfCancelled()
        }

        switch controller.loadState {
        case .loaded, .failed:
            return
        case .idle, .loading:
            break
        }

        guard Task.isCancelled == false else { return }

        let acquired = await NativeAdLoadGate.shared.acquire()
        guard acquired else { return }
        defer { NativeAdLoadGate.shared.release() }

        guard Task.isCancelled == false else { return }

        controller.configure(adUnitId: unitId)
        await controller.load()
    }
}

// MARK: - Static placeholder (no shimmer — avoids blink / GPU thrash while scrolling)

private struct NativeAdStaticPlaceholder: View {
    @Environment(\.colorScheme) private var colorScheme
    let height: CGFloat

    var body: some View {
        let palette = Theme.palette(for: colorScheme)

        GlassCard(padding: Spacing.large, surface: .solid) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Ad")
                    .font(Typography.caption)
                    .foregroundStyle(palette.secondaryText)

                HStack(alignment: .top, spacing: Spacing.medium) {
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(palette.elevatedBackground)
                        .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .fill(palette.elevatedBackground)
                            .frame(height: 18)
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .fill(palette.elevatedBackground)
                            .frame(height: 14)
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .fill(palette.elevatedBackground)
                            .frame(width: 120, height: 14)
                    }
                }

                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(palette.elevatedBackground)
                    .frame(height: 140)

                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(palette.elevatedBackground)
                    .frame(height: 44)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: height)
        .accessibilityLabel("Loading advertisement")
        .allowsHitTesting(false)
    }
}

#if canImport(GoogleMobileAds) && canImport(UIKit)
private struct NativeAdFeedRepresentable: UIViewRepresentable {
    let nativeAd: NativeAd?
    let onClick: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onClick: onClick)
    }

    func makeUIView(context: Context) -> FeedNativeAdView {
        FeedNativeAdView()
    }

    func updateUIView(_ uiView: FeedNativeAdView, context: Context) {
        guard let nativeAd else { return }
        // Apply once per ad instance — re-applying every update causes layout thrash.
        guard context.coordinator.appliedAd !== nativeAd else { return }
        nativeAd.delegate = context.coordinator
        uiView.apply(nativeAd)
        context.coordinator.appliedAd = nativeAd
    }

    static func dismantleUIView(_ uiView: FeedNativeAdView, coordinator: Coordinator) {
        coordinator.appliedAd = nil
        uiView.prepareForReuse()
    }

    final class Coordinator: NSObject, NativeAdDelegate {
        let onClick: () -> Void
        weak var appliedAd: NativeAd?

        init(onClick: @escaping () -> Void) {
            self.onClick = onClick
        }

        func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
            onClick()
        }
    }
}

/// Fixed-layout native ad sized for list feeds (no dynamic height callbacks).
private final class FeedNativeAdView: GoogleMobileAds.NativeAdView {
    private let card = UIView()
    private let rootStack = UIStackView()
    private let headerStack = UIStackView()
    private let textStack = UIStackView()

    private let badgeLabel = UILabel()
    private let advertiserLabel = UILabel()
    private let iconImageView = UIImageView()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let media = MediaView()
    private let ctaButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        nativeAd = nil
        media.mediaContent = nil
        iconImageView.image = nil
        headlineLabel.text = nil
        bodyLabel.text = nil
        advertiserLabel.text = nil
        ctaButton.setTitle(nil, for: .normal)
    }

    func apply(_ ad: NativeAd) {
        headlineLabel.text = ad.headline
        bodyLabel.text = ad.body

        let advertiser = ad.advertiser?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        advertiserLabel.text = advertiser
        advertiserLabel.isHidden = advertiser.isEmpty

        iconImageView.image = ad.icon?.image
        iconImageView.isHidden = ad.icon?.image == nil

        let cta = ad.callToAction?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        ctaButton.setTitle(cta, for: .normal)
        ctaButton.isHidden = cta.isEmpty

        media.mediaContent = ad.mediaContent
        media.isHidden = ad.mediaContent == nil

        headlineView = headlineLabel
        bodyView = bodyLabel
        iconView = iconImageView
        callToActionView = ctaButton
        mediaView = media
        advertiserView = advertiserLabel
        nativeAd = ad
    }

    private func buildLayout() {
        backgroundColor = .clear
        clipsToBounds = true

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor.secondarySystemBackground
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        addSubview(card)

        rootStack.axis = .vertical
        rootStack.spacing = 10
        rootStack.alignment = .fill
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rootStack)

        let metaStack = UIStackView(arrangedSubviews: [badgeLabel, advertiserLabel, UIView()])
        metaStack.axis = .horizontal
        metaStack.spacing = 8
        metaStack.alignment = .center

        badgeLabel.text = "Ad"
        badgeLabel.font = .preferredFont(forTextStyle: .caption1)
        badgeLabel.textColor = .secondaryLabel
        badgeLabel.setContentHuggingPriority(.required, for: .horizontal)

        advertiserLabel.font = .preferredFont(forTextStyle: .caption1)
        advertiserLabel.textColor = .tertiaryLabel
        advertiserLabel.numberOfLines = 1
        advertiserLabel.lineBreakMode = .byTruncatingTail

        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .top

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 10
        iconImageView.backgroundColor = UIColor.tertiarySystemFill
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48)
        ])

        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .fill

        headlineLabel.font = .preferredFont(forTextStyle: .headline)
        headlineLabel.numberOfLines = 2
        headlineLabel.lineBreakMode = .byTruncatingTail

        bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        bodyLabel.lineBreakMode = .byTruncatingTail

        textStack.addArrangedSubview(headlineLabel)
        textStack.addArrangedSubview(bodyLabel)
        headerStack.addArrangedSubview(iconImageView)
        headerStack.addArrangedSubview(textStack)

        media.contentMode = .scaleAspectFill
        media.clipsToBounds = true
        media.layer.cornerRadius = 12
        media.backgroundColor = UIColor.tertiarySystemFill
        media.heightAnchor.constraint(equalToConstant: 140).isActive = true

        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        config.baseBackgroundColor = UIColor.systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        ctaButton.configuration = config
        ctaButton.isUserInteractionEnabled = false
        ctaButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        rootStack.addArrangedSubview(metaStack)
        rootStack.addArrangedSubview(headerStack)
        rootStack.addArrangedSubview(media)
        rootStack.addArrangedSubview(ctaButton)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),

            rootStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            rootStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            rootStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            rootStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }
}
#endif
