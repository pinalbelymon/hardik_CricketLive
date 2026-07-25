import SwiftUI

// MARK: - Shadow

/// Shadow tokens for subtle visual depth.
enum AppShadow {
    static func card(_ palette: ColorPalette) -> some ViewModifier {
        ShadowModifier(color: palette.shadow, radius: 16, y: 8)
    }

    static func subtle(_ palette: ColorPalette) -> some ViewModifier {
        ShadowModifier(color: palette.shadow.opacity(0.35), radius: 6, y: 3)
    }

    static func floating(_ palette: ColorPalette) -> some ViewModifier {
        ShadowModifier(color: palette.shadow, radius: 24, y: 14)
    }
}

// MARK: - Shadow Modifier

private struct ShadowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(color: color, radius: radius, x: 0, y: y)
    }
}
