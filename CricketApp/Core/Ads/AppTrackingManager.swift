import Foundation
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif
#if canImport(AdSupport)
import AdSupport
#endif

// MARK: - Tracking Authorization Status

enum AppTrackingStatus: Equatable, Sendable {
    case notDetermined
    case restricted
    case denied
    case authorized
    case unavailable
}

// MARK: - ATT Manager

/// Requests App Tracking Transparency permission (iOS 14.5+).
///
/// Call **after** UMP consent and **before** personalized ad requests.
/// Declining ATT still allows non-personalized ads.
@MainActor
final class AppTrackingManager {
    static let shared = AppTrackingManager()

    private(set) var status: AppTrackingStatus = .notDetermined

    var currentStatus: AppTrackingStatus {
        #if canImport(AppTrackingTransparency)
        map(ATTrackingManager.trackingAuthorizationStatus)
        #else
        .unavailable
        #endif
    }

    /// Presents the system ATT dialog when status is `.notDetermined`.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> AppTrackingStatus {
        #if canImport(AppTrackingTransparency)
        let existing = ATTrackingManager.trackingAuthorizationStatus
        if existing != .notDetermined {
            status = map(existing)
            return status
        }

        // Brief delay so the dialog is not stacked on top of UMP / launch transitions.
        try? await Task.sleep(for: .milliseconds(400))

        let result = await ATTrackingManager.requestTrackingAuthorization()
        status = map(result)
        return status
        #else
        status = .unavailable
        return status
        #endif
    }

    #if canImport(AppTrackingTransparency)
    private func map(_ value: ATTrackingManager.AuthorizationStatus) -> AppTrackingStatus {
        switch value {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    #endif
}
