import Foundation

// MARK: - Ad Policy

/// App Store / Google Ads safe-use rules for when ads may be requested or shown.
///
/// - Interstitials only at natural breaks (caller must use a placement that represents one).
/// - Frequency caps and cool-downs reduce accidental clicks and policy risk.
/// - No ad requests when the master kill switch or consent blocks them.
struct AdPolicy: Sendable {
    /// Minimum time after app foreground before an interstitial may show.
    var minimumSessionDurationBeforeInterstitial: TimeInterval
    /// Minimum gap between two interstitial presentations.
    var interstitialCooldown: TimeInterval
    /// Skip interstitial if the user recently interacted with a banner/native.
    var postClickCooldown: TimeInterval
    /// Minimum gap between app-open presentations.
    var appOpenCooldown: TimeInterval
    /// Warm-start app-open only if the app was backgrounded at least this long.
    var minimumBackgroundDurationForAppOpen: TimeInterval

    static let production = AdPolicy(
        minimumSessionDurationBeforeInterstitial: 15,
        interstitialCooldown: 90,
        postClickCooldown: 30,
        appOpenCooldown: 180,
        minimumBackgroundDurationForAppOpen: 30
    )

    static let relaxedForTesting = AdPolicy(
        minimumSessionDurationBeforeInterstitial: 0,
        interstitialCooldown: 10,
        postClickCooldown: 5,
        appOpenCooldown: 20,
        minimumBackgroundDurationForAppOpen: 5
    )
}

// MARK: - Ad Policy Gate

/// Mutable gate that enforces `AdPolicy` at runtime (main-actor).
@MainActor
final class AdPolicyGate {
    private let policy: AdPolicy
    private var sessionStartedAt: Date
    private var lastInterstitialShownAt: Date?
    private var lastAppOpenShownAt: Date?
    private var lastAdClickAt: Date?
    private var lastBackgroundedAt: Date?

    init(policy: AdPolicy = .production) {
        self.policy = policy
        self.sessionStartedAt = Date()
    }

    func markSessionStarted() {
        sessionStartedAt = Date()
    }

    func markInterstitialShown() {
        lastInterstitialShownAt = Date()
    }

    func markAppOpenShown() {
        lastAppOpenShownAt = Date()
    }

    func markAdClicked() {
        lastAdClickAt = Date()
    }

    func markEnteredBackground(at date: Date = Date()) {
        lastBackgroundedAt = date
    }

    /// Whether an interstitial may be presented for a natural-break placement.
    func canPresentInterstitial(now: Date = Date()) -> Bool {
        let sessionAge = now.timeIntervalSince(sessionStartedAt)
        guard sessionAge >= policy.minimumSessionDurationBeforeInterstitial else {
            return false
        }

        if let last = lastInterstitialShownAt,
           now.timeIntervalSince(last) < policy.interstitialCooldown {
            return false
        }

        if let click = lastAdClickAt,
           now.timeIntervalSince(click) < policy.postClickCooldown {
            return false
        }

        return true
    }

    /// Cold start always eligible (after cooldown). Warm start needs enough background time.
    func canPresentAppOpen(isColdStart: Bool, now: Date = Date()) -> Bool {
        if let last = lastAppOpenShownAt,
           now.timeIntervalSince(last) < policy.appOpenCooldown {
            return false
        }

        if let last = lastInterstitialShownAt,
           now.timeIntervalSince(last) < policy.interstitialCooldown {
            return false
        }

        if isColdStart == false {
            guard let backgrounded = lastBackgroundedAt,
                  now.timeIntervalSince(backgrounded) >= policy.minimumBackgroundDurationForAppOpen else {
                return false
            }
        }

        return true
    }
}
