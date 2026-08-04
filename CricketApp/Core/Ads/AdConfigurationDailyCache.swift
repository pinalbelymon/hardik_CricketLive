import Foundation

// MARK: - Ad Configuration Daily Cache

/// Persists Firestore ad config and serves it for the rest of the local calendar day.
actor AdConfigurationDailyCache {
    static let shared = AdConfigurationDailyCache()

    private let cacheKey = "ad_configuration_daily"
    private let store: DiskCacheStore

    init(store: DiskCacheStore = .shared) {
        self.store = store
    }

    /// Returns cached config only when it was saved earlier today.
    func todaysConfiguration() async -> AdConfiguration? {
        guard let cached = await store.load(AdConfiguration.self, key: cacheKey) else {
            return nil
        }
        guard Calendar.current.isDateInToday(cached.updatedAt) else {
            return nil
        }
        return cached.value
    }

    /// Any previously saved config (may be from a prior day). Useful offline fallback.
    func latestConfiguration() async -> AdConfiguration? {
        await store.load(AdConfiguration.self, key: cacheKey)?.value
    }

    func save(_ configuration: AdConfiguration) async {
        try? await store.save(configuration, key: cacheKey, updatedAt: .now)
    }
}
