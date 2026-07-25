import SwiftUI

// MARK: - App Animation

/// Motion tokens that respect Reduce Motion at call sites.
enum AppAnimation {
    static let spring = Animation.spring(response: 0.42, dampingFraction: 0.86)
    static let quick = Animation.easeOut(duration: 0.18)
    static let shimmer = Animation.linear(duration: 1.2).repeatForever(autoreverses: false)
    static let playful = Animation.spring(response: 0.55, dampingFraction: 0.68)
    static let bounce = Animation.spring(response: 0.45, dampingFraction: 0.55)
    static let gentlePulse = Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true)
    static let launchFade = Animation.easeInOut(duration: 0.65)
}
