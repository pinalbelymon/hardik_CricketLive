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
    private let documentId: String
    private let dailyCache: AdConfigurationDailyCache

    init(
        collectionName: String = AppConstants.Firestore.adConfigurationCollection,
        documentId: String = AppConstants.Firestore.adConfigurationDocument,
        dailyCache: AdConfigurationDailyCache = .shared
    ) {
        self.collectionName = collectionName
        self.documentId = documentId
        self.dailyCache = dailyCache
    }

    func loadConfiguration() async throws -> AdConfiguration {
        // Same calendar day → reuse cache (no Firebase call).
        if let todays = await dailyCache.todaysConfiguration() {
            return todays
        }

        #if canImport(FirebaseFirestore)
        do {
            let remote = try await fetchRemoteConfiguration()
            await dailyCache.save(remote)
            return remote
        } catch {
            // Network / Firebase failure: prefer any prior-day cache over hard fallback.
            if let stale = await dailyCache.latestConfiguration() {
                return stale
            }
            throw error
        }
        #else
        if let stale = await dailyCache.latestConfiguration() {
            return stale
        }
        return fallbackConfiguration()
        #endif
    }

    #if canImport(FirebaseFirestore)
    private func fetchRemoteConfiguration() async throws -> AdConfiguration {
        let document = try await Firestore.firestore()
            .collection(collectionName)
            .document(documentId)
            .getDocument()

        if document.exists, let data = document.data() {
            return AdConfiguration.fromFirestoreData(data)
        }

        // Backward compatible: first document in the collection if `ios` is missing.
        let snapshot = try await Firestore.firestore().collection(collectionName).getDocuments()
        if let data = snapshot.documents.first?.data() {
            return AdConfiguration.fromFirestoreData(data)
        }

        return fallbackConfiguration()
    }
    #endif

    /// Used when Firebase is missing, document is empty, or fetch fails upstream.
    func fallbackConfiguration() -> AdConfiguration {
        #if DEBUG
        guard AppConstants.Ads.enableAdsInDebugWithoutRemoteConfig else {
            return .disabled
        }
        return AdConfiguration.localFallback(
            isShowAds: true,
            adaptiveBannerAdUnitId: AdUnitCatalog.Sample.banner,
            interstitialAdUnitId: AdUnitCatalog.Sample.interstitial,
            nativeAdUnitId: AdUnitCatalog.Sample.native,
            openAdUnitId: AdUnitCatalog.Sample.appOpen
        )
        #else
        guard AppConstants.Ads.enableAdsInReleaseWithoutRemoteConfig else {
            return .disabled
        }
        // Never fall back to Google sample unit IDs in Release (policy / invalid traffic).
        let native = AppConstants.Ads.nativeAdUnitId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard native.isEmpty == false else {
            return .disabled
        }
        return AdConfiguration.localFallback(
            isShowAds: true,
            adaptiveBannerAdUnitId: AppConstants.Ads.bannerAdUnitId,
            interstitialAdUnitId: AppConstants.Ads.interstitialAdUnitId,
            nativeAdUnitId: native,
            openAdUnitId: AppConstants.Ads.openAdUnitId
        )
        #endif
    }
}

// MARK: - Mobile Ads Service Protocol

/// Starts and coordinates Google Mobile Ads when the SDK is linked.
protocol MobileAdsServiceProtocol: Sendable {
    func start() async
}

// MARK: - Mobile Ads Service

final class MobileAdsService: MobileAdsServiceProtocol {
    func start() async {
        #if canImport(GoogleMobileAds)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            MobileAds.shared.start { _ in
                continuation.resume()
            }
        }
        #endif
    }
}
