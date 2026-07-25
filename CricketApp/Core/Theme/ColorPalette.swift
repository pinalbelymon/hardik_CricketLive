import SwiftUI

// MARK: - Color Palette

/// App color tokens tuned independently for light and dark appearances.
struct ColorPalette {
    let background: Color
    let elevatedBackground: Color
    let card: Color
    let primary: Color
    let secondary: Color
    let accent: Color
    let success: Color
    let warning: Color
    let error: Color
    let text: Color
    let secondaryText: Color
    let divider: Color
    let glass: Color
    let shadow: Color

    static let light = ColorPalette(
        background: Color(.systemGroupedBackground),
        elevatedBackground: Color(.secondarySystemGroupedBackground),
        card: .white,
        primary: Color(hex: 0x1E5BE8),
        secondary: Color(hex: 0xF57C1F),
        accent: Color(hex: 0x1294FF),
        success: Color(hex: 0x1F9D55),
        warning: Color(hex: 0xF59E0B),
        error: Color(hex: 0xE53935),
        text: Color(hex: 0x101828),
        secondaryText: Color(hex: 0x667085),
        divider: Color(hex: 0xE4E7EC),
        glass: Color.white.opacity(0.72),
        shadow: Color.black.opacity(0.10)
    )

    static let dark = ColorPalette(
        background: Color(hex: 0x070B12),
        elevatedBackground: Color(hex: 0x101722),
        card: Color(hex: 0x151D2A),
        primary: Color(hex: 0x5A9DFF),
        secondary: Color(hex: 0xFF9F43),
        accent: Color(hex: 0x58C4FF),
        success: Color(hex: 0x35D07F),
        warning: Color(hex: 0xFFC857),
        error: Color(hex: 0xFF6B6B),
        text: Color(hex: 0xF8FAFC),
        secondaryText: Color(hex: 0xA8B3C7),
        divider: Color(hex: 0x283447),
        glass: Color(hex: 0x111827).opacity(0.72),
        shadow: Color.black.opacity(0.42)
    )
}
