import SwiftUI

// MARK: - App Lifecycle Manager

/// Broadcasts foreground and background transitions for polling control.
@MainActor
final class AppLifecycleManager: ObservableObject {
    static let shared = AppLifecycleManager()

    @Published private(set) var isActive = true

    private init() {}

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            isActive = true
        case .inactive, .background:
            isActive = false
        @unknown default:
            isActive = false
        }
    }
}
