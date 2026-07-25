import SwiftUI

// MARK: - Theme Manager

/// Persists and broadcasts the app appearance setting.
@MainActor
final class ThemeManager: ObservableObject {
    @Published var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Self.storageKey)
        }
    }

    private static let storageKey = "cricket.appearance"

    init() {
        let storedValue = UserDefaults.standard.string(forKey: Self.storageKey)
        appearance = storedValue.flatMap(AppAppearance.init(rawValue:)) ?? .system
    }
}
