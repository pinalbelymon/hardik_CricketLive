import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - Ad Config Service Protocol

/// Loads ad configuration from Firestore when Firebase is linked.
protocol AdConfigServiceProtocol: Sendable {
    func loadConfiguration() async throws -> AdConfiguration
}

// MARK: - Firestore Ad Config Service

final class FirestoreAdConfigService: AdConfigServiceProtocol {
    private let collectionName: String

    init(collectionName: String = AppConstants.Firestore.adConfigurationCollection) {
        self.collectionName = collectionName
    }

    func loadConfiguration() async throws -> AdConfiguration {
        #if canImport(FirebaseFirestore)
        let snapshot = try await Firestore.firestore().collection(collectionName).getDocuments()
        guard let data = snapshot.documents.first?.data() else {
            return .disabled
        }

        return AdConfiguration(
            isShowAds: data["isShowAds"] as? Bool ?? false,
            adaptiveBannerAdUnitId: data["adaptiveBannerAdUnitId"] as? String ?? "",
            interstitialAdUnitId: data["interstitialAdUnitId"] as? String ?? "",
            nativeAdUnitId: data["nativeAdUnitId"] as? String ?? "",
            openAdUnitId: data["openAdUnitId"] as? String ?? ""
        )
        #else
        return .disabled
        #endif
    }
}

// MARK: - Mobile Ads Service Protocol

/// Starts and coordinates Google Mobile Ads when the SDK is linked.
protocol MobileAdsServiceProtocol: Sendable {
    func start()
}

// MARK: - Mobile Ads Service

final class MobileAdsService: MobileAdsServiceProtocol {
    func start() {
        #if canImport(GoogleMobileAds)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #endif
    }
}
