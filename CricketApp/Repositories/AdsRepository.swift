import Foundation

// MARK: - Ads Repository Protocol

/// Provides ad configuration and SDK bootstrapping.
protocol AdsRepositoryProtocol: Sendable {
    func loadConfiguration() async -> AdConfiguration
    func startAds() async
}

// MARK: - Ads Repository

final class AdsRepository: AdsRepositoryProtocol {
    private let configService: AdConfigServiceProtocol
    private let mobileAdsService: MobileAdsServiceProtocol

    init(configService: AdConfigServiceProtocol, mobileAdsService: MobileAdsServiceProtocol) {
        self.configService = configService
        self.mobileAdsService = mobileAdsService
    }

    func loadConfiguration() async -> AdConfiguration {
        do {
            return try await configService.loadConfiguration()
        } catch {
            // Prefer any prior-day cache, then DEBUG/Release fallback.
            if let cached = await AdConfigurationDailyCache.shared.latestConfiguration() {
                return cached
            }
            if let firestoreService = configService as? FirestoreAdConfigService {
                return firestoreService.fallbackConfiguration()
            }
            return .disabled
        }
    }

    func startAds() async {
        await mobileAdsService.start()
    }
}
