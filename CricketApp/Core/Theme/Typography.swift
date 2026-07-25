import SwiftUI

// MARK: - Typography

/// Font tokens matching modern Apple hierarchy and Dynamic Type.
enum Typography {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title2.weight(.semibold)
    static let headline = Font.headline.weight(.semibold)
    static let body = Font.body
    static let caption = Font.caption.weight(.medium)
    static let monoScore = Font.system(.title3, design: .monospaced).weight(.bold)
    static let monoCaption = Font.system(.caption, design: .monospaced).weight(.medium)
}
