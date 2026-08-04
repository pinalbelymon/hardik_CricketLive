import SwiftUI

// MARK: - Interstitial Trigger Helper

/// Call from natural navigation breaks only (leaving a screen, finishing a flow).
/// Does nothing while placements remain disabled.
enum InterstitialAdPresenter {
    @MainActor
    static func show(
        _ placement: AdPlacement,
        using adsManager: AdsManager
    ) async {
        guard placement.format == .interstitial else { return }
        _ = await adsManager.showInterstitial(for: placement)
    }
}
