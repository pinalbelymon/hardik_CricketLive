import Foundation
import Combine
import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - Ads Manager Protocol

@MainActor
protocol AdsManaging: AnyObject {
    var bootstrapState: AdsBootstrapState { get }
    var configuration: AdConfiguration { get }
    var placementConfiguration: AdPlacementConfiguration { get }
    var consentStatus: AdsConsentStatus { get }

    func prepare() async
    func isPlacementEnabled(_ placement: AdPlacement) -> Bool
    func bannerAdUnitId(for placement: AdPlacement) -> String?
    func nativeAdUnitId(for placement: AdPlacement) -> String?
    func preloadInterstitial(for placement: AdPlacement) async
    @discardableResult
    func showInterstitial(for placement: AdPlacement) async -> Bool
    func presentPrivacyOptionsIfNeeded() async
    func markAdClicked()
    func recordInterstitialTap(_ action: InterstitialTapAction) async
    func handleAppDidEnterBackground()
    @discardableResult
    func handleAppOpenOpportunity(isColdStart: Bool) async -> Bool
}

// MARK: - Ads Manager

/// Production ads façade: consent → config → SDK start → format APIs.
///
/// - Async and non-blocking for launch UI.
/// - Idempotent `prepare()`.
/// - Does not place ads in screens; call sites opt in via placements later.
@MainActor
final class AdsManager: ObservableObject, AdsManaging {
    @Published private(set) var bootstrapState: AdsBootstrapState = .idle
    @Published private(set) var configuration: AdConfiguration = .disabled
    @Published private(set) var placementConfiguration: AdPlacementConfiguration = .allDisabled
    @Published private(set) var consentStatus: AdsConsentStatus = .unknown

    private let adsRepository: AdsRepositoryProtocol
    private let consentManager: ConsentManaging
    private let policyGate: AdPolicyGate
    private let purchaseManager: PurchaseManager
    let interstitialController: InterstitialAdController
    let appOpenController: AppOpenAdController
    private let tapTracker = InterstitialTapTracker()

    private var prepareTask: Task<Void, Never>?
    private var didStartMobileAds = false
    private var cancellables = Set<AnyCancellable>()
    private var didShowColdStartAppOpen = false

    init(
        adsRepository: AdsRepositoryProtocol,
        purchaseManager: PurchaseManager,
        consentManager: ConsentManaging = ConsentManager.shared,
        policy: AdPolicy = .production
    ) {
        self.adsRepository = adsRepository
        self.purchaseManager = purchaseManager
        self.consentManager = consentManager
        self.policyGate = AdPolicyGate(policy: policy)
        self.interstitialController = InterstitialAdController()
        self.appOpenController = AppOpenAdController()

        purchaseManager.$isPremium
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isPremium in
                guard let self else { return }
                self.objectWillChange.send()
                if isPremium {
                    self.placementConfiguration = .allDisabled
                }
            }
            .store(in: &cancellables)
    }

    /// Async bootstrap. Safe to call from splash / root `.task` and Settings.
    func prepare() async {
        if case .ready = bootstrapState { return }
        if case .preparing = bootstrapState {
            await prepareTask?.value
            return
        }

        bootstrapState = .preparing
        let task = Task { @MainActor in
            await self.runPrepare()
        }
        prepareTask = task
        await task.value
    }

    private func runPrepare() async {
        policyGate.markSessionStarted()

        let config = await adsRepository.loadConfiguration()
        configuration = config

        // Soft placement map — all disabled until product enables slots.
        // Future: merge remote placement flags into `placementConfiguration`.
        placementConfiguration = .allDisabled

        // Premium users never see ads.
        guard purchaseManager.isPremium == false else {
            bootstrapState = .ready(adsEnabled: false)
            return
        }

        guard config.isShowAds else {
            bootstrapState = .ready(adsEnabled: false)
            return
        }

        consentStatus = await consentManager.gatherConsentIfNeeded()

        #if DEBUG
        // Outside EEA, UMP usually sets canRequestAds == true. If the form cannot
        // present yet, still continue so DEBUG sample ads can be verified.
        let mayRequestAds = consentManager.canRequestAds || consentStatus != .required
        #else
        let mayRequestAds = consentManager.canRequestAds
        #endif

        guard mayRequestAds else {
            bootstrapState = .ready(adsEnabled: false)
            return
        }

        if didStartMobileAds == false {
            await adsRepository.startAds()
            didStartMobileAds = true
        }

        interstitialController.configure(
            adUnitId: AdUnitCatalog.interstitialUnitId(from: config)
        )
        appOpenController.configure(
            adUnitId: AdUnitCatalog.appOpenUnitId(from: config)
        )

        // Product-enabled list placements (banner/interstitial stay off until decided).
        var placements = AdPlacementConfiguration.allDisabled
        placements.setEnabled(.homeFeedNative, enabled: true)
        placements.setEnabled(.fixturesFeedNative, enabled: true)
        placements.setEnabled(.matchDetailsNative, enabled: true)
        placements.setEnabled(.scorecardBanner, enabled: true)
        placements.setEnabled(.oversBanner, enabled: true)
        placements.setEnabled(.engagementInterstitial, enabled: true)
        placements.setEnabled(.appOpen, enabled: true)
        placementConfiguration = placements

        bootstrapState = .ready(adsEnabled: true)

        // Warm ads so first opportunities can present quickly.
        Task {
            await self.preloadInterstitial(for: .engagementInterstitial)
            await self.preloadAppOpen()
        }
    }

    /// Enable or disable a placement at runtime (remote config / QA later).
    func setPlacement(_ placement: AdPlacement, enabled: Bool) {
        var updated = placementConfiguration
        updated.setEnabled(placement, enabled: enabled)
        placementConfiguration = updated
    }

    func isPlacementEnabled(_ placement: AdPlacement) -> Bool {
        if purchaseManager.isPremium { return false }
        guard case .ready(let adsEnabled) = bootstrapState, adsEnabled else {
            return false
        }
        guard configuration.isShowAds else { return false }
        return placementConfiguration.isEnabled(placement)
    }

    func bannerAdUnitId(for placement: AdPlacement) -> String? {
        guard placement.format == .banner, isPlacementEnabled(placement) else { return nil }
        let unit = AdUnitCatalog.bannerUnitId(from: configuration)
        return unit.isEmpty ? nil : unit
    }

    func nativeAdUnitId(for placement: AdPlacement) -> String? {
        guard placement.format == .native, isPlacementEnabled(placement) else { return nil }
        let unit = AdUnitCatalog.nativeUnitId(from: configuration)
        return unit.isEmpty ? nil : unit
    }

    func preloadInterstitial(for placement: AdPlacement) async {
        guard placement.format == .interstitial, isPlacementEnabled(placement) else { return }
        await interstitialController.preload()
    }

    @discardableResult
    func showInterstitial(for placement: AdPlacement) async -> Bool {
        guard placement.format == .interstitial else { return false }
        guard isPlacementEnabled(placement) else { return false }
        guard policyGate.canPresentInterstitial() else { return false }

        if interstitialController.isReady == false {
            await interstitialController.preload()
        }

        let presented = interstitialController.presentIfReady()
        if presented {
            policyGate.markInterstitialShown()
        }
        return presented
    }

    func presentPrivacyOptionsIfNeeded() async {
        guard consentManager.isPrivacyOptionsRequired else { return }
        await consentManager.presentPrivacyOptions()
    }

    func markAdClicked() {
        policyGate.markAdClicked()
    }

    /// Call after opening match card / scorecard / commentary / overs.
    /// Thresholds come from Firestore (`AdConfiguration`) with `AppConstants.Ads` fallback.
    func recordInterstitialTap(_ action: InterstitialTapAction) async {
        guard purchaseManager.isPremium == false else { return }
        guard isPlacementEnabled(.engagementInterstitial) else { return }

        let everyTaps = configuration.interstitialEveryTaps(for: action)
        guard everyTaps > 0 else { return }

        if tapTracker.willTriggerOnNextTap(action, everyTaps: everyTaps) {
            await preloadInterstitial(for: .engagementInterstitial)
        }

        let shouldShow = tapTracker.record(action, everyTaps: everyTaps)
        guard shouldShow else { return }

        // Let navigation finish before presenting (natural break, no mid-gesture interrupt).
        try? await Task.sleep(for: .milliseconds(550))
        _ = await showInterstitial(for: .engagementInterstitial)
    }

    func handleAppDidEnterBackground() {
        policyGate.markEnteredBackground()
    }

    /// Cold start (after main UI) or warm resume from background.
    @discardableResult
    func handleAppOpenOpportunity(isColdStart: Bool) async -> Bool {
        guard purchaseManager.isPremium == false else { return false }
        guard isPlacementEnabled(.appOpen) else { return false }

        if isColdStart {
            guard didShowColdStartAppOpen == false else { return false }
        }

        guard policyGate.canPresentAppOpen(isColdStart: isColdStart) else {
            // Keep a fresh ad ready for the next opportunity.
            await preloadAppOpen()
            return false
        }

        if appOpenController.isReady == false {
            await preloadAppOpen()
        }

        // Let the first frame of main UI settle before covering it.
        try? await Task.sleep(for: .milliseconds(isColdStart ? 700 : 350))

        guard isPlacementEnabled(.appOpen) else { return false }
        guard policyGate.canPresentAppOpen(isColdStart: isColdStart) else { return false }

        let presented = appOpenController.presentIfReady()
        if presented {
            policyGate.markAppOpenShown()
            if isColdStart {
                didShowColdStartAppOpen = true
            }
        } else {
            await preloadAppOpen()
        }
        return presented
    }

    private func preloadAppOpen() async {
        guard isPlacementEnabled(.appOpen) else { return }
        await appOpenController.preload()
    }
}

// MARK: - Preview / Disabled Manager

@MainActor
final class DisabledAdsManager: ObservableObject, AdsManaging {
    @Published private(set) var bootstrapState: AdsBootstrapState = .ready(adsEnabled: false)
    var configuration: AdConfiguration { .disabled }
    var placementConfiguration: AdPlacementConfiguration { .allDisabled }
    var consentStatus: AdsConsentStatus { .notRequired }

    func prepare() async {}
    func isPlacementEnabled(_ placement: AdPlacement) -> Bool { false }
    func bannerAdUnitId(for placement: AdPlacement) -> String? { nil }
    func nativeAdUnitId(for placement: AdPlacement) -> String? { nil }
    func preloadInterstitial(for placement: AdPlacement) async {}
    func showInterstitial(for placement: AdPlacement) async -> Bool { false }
    func presentPrivacyOptionsIfNeeded() async {}
    func markAdClicked() {}
    func recordInterstitialTap(_ action: InterstitialTapAction) async {}
    func handleAppDidEnterBackground() {}
    func handleAppOpenOpportunity(isColdStart: Bool) async -> Bool { false }
}
