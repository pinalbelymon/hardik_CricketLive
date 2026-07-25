import Foundation

// MARK: - Ads Repository Protocol

/// Provides ad configuration and SDK bootstrapping.
protocol AdsRepositoryProtocol: Sendable {
    func loadConfiguration() async -> AdConfiguration
    func startAds()
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
            return .disabled
        }
    }

    func startAds() {
        mobileAdsService.start()
    }
}
