import Foundation

// MARK: - Onboarding Store

/// Persists whether the user has completed first-launch onboarding.
enum OnboardingStore {
    static let storageKey = "cricket.hasCompletedOnboarding"

    static var hasCompleted: Bool {
        UserDefaults.standard.bool(forKey: storageKey)
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: storageKey)
    }

    #if DEBUG
    static func reset() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    #endif
}
