import SwiftData
import SwiftUI

// MARK: - App Entry

@main
struct CricketAppApp: App {
    @StateObject private var themeManager = ThemeManager()

    private let container = DependencyContainer.live()

    init() {
        ImageCache.configureSharedCache()
    }

    var body: some Scene {
        WindowGroup {
            AppLaunchView(container: container)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.appearance.colorScheme)
        }
        .modelContainer(for: RecentSearch.self)
    }
}
