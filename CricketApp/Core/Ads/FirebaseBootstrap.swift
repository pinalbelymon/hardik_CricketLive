import Foundation
#if canImport(FirebaseCore)
import FirebaseCore
#endif

// MARK: - Firebase Bootstrap

/// Configures Firebase once at launch when the SDK + `GoogleService-Info.plist` are present.
enum FirebaseBootstrap {
    static func configureIfNeeded() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif
    }
}
