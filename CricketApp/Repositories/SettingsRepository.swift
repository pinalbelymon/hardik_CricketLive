import Foundation

// MARK: - Settings Repository Protocol

/// Provides user-facing app metadata.
protocol SettingsRepositoryProtocol: Sendable {
    var appVersion: String { get }
    var buildNumber: String { get }
    var developerInfo: DeveloperInfo { get }
}

// MARK: - Settings Repository

final class SettingsRepository: SettingsRepositoryProtocol {
    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var developerInfo: DeveloperInfo {
        .current
    }
}
