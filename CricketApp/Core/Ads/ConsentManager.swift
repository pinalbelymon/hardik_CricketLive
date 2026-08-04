import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

// MARK: - Consent Status

enum AdsConsentStatus: Equatable, Sendable {
    case unknown
    case notRequired
    case obtained
    case required
    case unavailable
}

// MARK: - Consent Manager Protocol

@MainActor
protocol ConsentManaging: AnyObject {
    func gatherConsentIfNeeded() async -> AdsConsentStatus
    var canRequestAds: Bool { get }
    var isPrivacyOptionsRequired: Bool { get }
    func presentPrivacyOptions() async
}

// MARK: - Consent Manager

/// Google UMP consent + ATT orchestration.
///
/// Must run **before** `MobileAds.shared.start()` and any ad requests
/// (Google Ads / Play & App Store privacy requirements).
@MainActor
final class ConsentManager: ConsentManaging {
    static let shared = ConsentManager()

    private(set) var status: AdsConsentStatus = .unknown

    var canRequestAds: Bool {
        #if canImport(UserMessagingPlatform)
        ConsentInformation.shared.canRequestAds
        #else
        // Without UMP linked, allow requests only in DEBUG so release stays safe.
        #if DEBUG
        true
        #else
        false
        #endif
        #endif
    }

    var isPrivacyOptionsRequired: Bool {
        #if canImport(UserMessagingPlatform)
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        #else
        false
        #endif
    }

    func gatherConsentIfNeeded() async -> AdsConsentStatus {
        #if canImport(UserMessagingPlatform)
        do {
            let parameters = RequestParameters()
            // Tag for under-age / child-directed only if product requires it.
            // Cricket scores app is general audience; leave default.

            #if DEBUG
            // Uncomment geography debug when testing EEA consent forms:
            // let debugSettings = DebugSettings()
            // debugSettings.geography = .EEA
            // parameters.debugSettings = debugSettings
            #endif

            try await requestConsentInfoUpdate(parameters: parameters)
            try await loadAndPresentConsentFormIfRequired()
            status = mapConsentStatus(ConsentInformation.shared.consentStatus)
        } catch {
            // On failure, still respect prior-session canRequestAds.
            status = canRequestAds ? .obtained : .required
        }
        #else
        status = .unavailable
        #endif

        // ATT after UMP (Apple + Google recommended order). Safe if user already chose.
        _ = await AppTrackingManager.shared.requestAuthorizationIfNeeded()

        return status
    }

    func presentPrivacyOptions() async {
        #if canImport(UserMessagingPlatform)
        guard let root = Self.topViewController() else { return }
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: root)
        } catch {
            // Non-fatal — Settings can retry.
        }
        #endif
    }

    #if canImport(UserMessagingPlatform)
    private func requestConsentInfoUpdate(parameters: RequestParameters) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func loadAndPresentConsentFormIfRequired() async throws {
        guard let root = Self.topViewController() else { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ConsentForm.loadAndPresentIfRequired(from: root) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func mapConsentStatus(_ value: ConsentStatus) -> AdsConsentStatus {
        switch value {
        case .notRequired:
            return .notRequired
        case .obtained:
            return .obtained
        case .required:
            return .required
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
    #endif

    #if canImport(UIKit)
    private static func topViewController(
        base: UIViewController? = {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first { $0.isKeyWindow }?
                .rootViewController
        }()
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
    #endif
}
