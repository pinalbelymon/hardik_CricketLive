import SwiftUI

// MARK: - Hide Tab Bar

extension View {
    /// Hides the parent `TabView` tab bar on pushed detail screens (iOS 17+).
    func hidesBottomTabBar() -> some View {
        toolbar(.hidden, for: .tabBar)
    }
}
