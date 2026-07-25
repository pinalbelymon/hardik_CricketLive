import SwiftUI

// MARK: - Appearance

/// User-selectable appearance mode for the whole app.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    var symbolName: String {
        switch self {
        case .system:
            "circle.lefthalf.filled"
        case .light:
            "sun.max.fill"
        case .dark:
            "moon.stars.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

// MARK: - Theme

/// Resolves the active design tokens from the current color scheme.
enum Theme {
    static func palette(for colorScheme: ColorScheme) -> ColorPalette {
        colorScheme == .dark ? .dark : .light
    }
}
