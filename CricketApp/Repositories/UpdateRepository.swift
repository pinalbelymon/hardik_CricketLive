import Foundation

// MARK: - Update Repository Protocol

/// Provides app update checks to Settings.
protocol UpdateRepositoryProtocol: Sendable {
    func checkForUpdate() async throws -> AppUpdate?
}

// MARK: - Update Repository

final class UpdateRepository: UpdateRepositoryProtocol {
    private let service: AppUpdateServiceProtocol
    private let settingsRepository: SettingsRepositoryProtocol

    init(service: AppUpdateServiceProtocol, settingsRepository: SettingsRepositoryProtocol) {
        self.service = service
        self.settingsRepository = settingsRepository
    }

    func checkForUpdate() async throws -> AppUpdate? {
        try await service.checkForUpdate(
            bundleIdentifier: Bundle.main.bundleIdentifier ?? AppConstants.bundleIdentifier,
            currentVersion: settingsRepository.appVersion
        )
    }
}
