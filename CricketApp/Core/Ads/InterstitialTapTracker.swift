import Foundation

// MARK: - Interstitial Tap Action

/// Navigation actions that can trigger an interstitial after N taps.
enum InterstitialTapAction: String, CaseIterable, Sendable {
    case matchCard
    case scorecard
    case commentary
    case overs
}

// MARK: - Interstitial Tap Tracker

/// Counts navigation taps per action and requests an interstitial at each threshold.
@MainActor
final class InterstitialTapTracker {
    private var counts: [InterstitialTapAction: Int] = [:]

    func count(for action: InterstitialTapAction) -> Int {
        counts[action] ?? 0
    }

    /// Increments the counter. Returns `true` when an interstitial should be shown now.
    @discardableResult
    func record(_ action: InterstitialTapAction, everyTaps: Int) -> Bool {
        guard everyTaps > 0 else { return false }

        let next = count(for: action) + 1
        counts[action] = next
        return next.isMultiple(of: everyTaps)
    }

    /// `true` when the next tap will hit the threshold (useful for preload).
    func willTriggerOnNextTap(_ action: InterstitialTapAction, everyTaps: Int) -> Bool {
        guard everyTaps > 0 else { return false }
        return (count(for: action) + 1).isMultiple(of: everyTaps)
    }

    func reset(_ action: InterstitialTapAction? = nil) {
        if let action {
            counts[action] = 0
        } else {
            counts.removeAll()
        }
    }
}
