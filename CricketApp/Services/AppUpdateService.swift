import Foundation

// MARK: - App Update Service Protocol

/// Checks App Store metadata using Apple's iTunes Lookup API.
protocol AppUpdateServiceProtocol: Sendable {
    func checkForUpdate(bundleIdentifier: String, currentVersion: String) async throws -> AppUpdate?
}

// MARK: - App Update Service

final class AppUpdateService: AppUpdateServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func checkForUpdate(bundleIdentifier: String, currentVersion: String) async throws -> AppUpdate? {
        let endpoint = Endpoint(
            baseURL: AppConstants.API.iTunesLookupURL,
            queryItems: [
                URLQueryItem(name: "bundleId", value: bundleIdentifier),
                URLQueryItem(name: "country", value: AppConstants.appStoreCountryCode)
            ]
        )

        let response: ITunesLookupResponse = try await apiClient.send(endpoint, decoder: JSONDecoder())
        guard let storeResult = response.results.first else {
            return nil
        }

        let update = AppUpdate(
            currentVersion: currentVersion,
            storeVersion: storeResult.version,
            appStoreURL: storeResult.trackViewUrl
        )

        return update.isAvailable ? update : nil
    }
}
