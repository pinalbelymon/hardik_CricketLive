import Foundation
import StoreKit

// MARK: - Purchase Manager

/// StoreKit 2 lifetime “Remove Ads” entitlement.
@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var isPremium = false
    @Published private(set) var lifetimeProduct: Product?
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?

    private let productIds: [String] = [AppConstants.IAP.lifetimeRemoveAdsProductId]
    private let cacheKey = "iap.lifetime.removeads.unlocked"
    private var updatesTask: Task<Void, Never>?

    var displayPrice: String {
        lifetimeProduct?.displayPrice ?? "—"
    }

    var isBusy: Bool {
        isPurchasing || isRestoring || isLoadingProducts
    }

    init() {
        isPremium = UserDefaults.standard.bool(forKey: cacheKey)
    }

    deinit {
        updatesTask?.cancel()
    }

    /// Call once at launch — loads products, syncs entitlements, listens for updates.
    func start() async {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }

        await refreshEntitlements()
        await loadProducts()
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: productIds)
            lifetimeProduct = products.first { $0.id == AppConstants.IAP.lifetimeRemoveAdsProductId }
            if lifetimeProduct == nil {
                errorMessage = "Premium product is unavailable right now. Please try again later."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func purchaseLifetime() async -> Bool {
        guard isPurchasing == false else { return false }

        if lifetimeProduct == nil {
            await loadProducts()
        }

        guard let product = lifetimeProduct else {
            errorMessage = "Unable to load the premium product."
            return false
        }

        isPurchasing = true
        errorMessage = nil
        statusMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await applyPremium(true)
                await transaction.finish()
                statusMessage = "Welcome to Premium — ads are removed."
                return true
            case .userCancelled:
                return false
            case .pending:
                statusMessage = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        guard isRestoring == false else { return }
        isRestoring = true
        errorMessage = nil
        statusMessage = nil
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if isPremium {
                statusMessage = "Purchases restored. Ads are removed."
            } else {
                statusMessage = "No previous premium purchase was found for this Apple ID."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var unlocked = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == AppConstants.IAP.lifetimeRemoveAdsProductId,
               transaction.revocationDate == nil {
                unlocked = true
                break
            }
        }

        await applyPremium(unlocked)
    }

    // MARK: - Private

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard let transaction = try? checkVerified(transactionResult) else { return }
        if transaction.productID == AppConstants.IAP.lifetimeRemoveAdsProductId {
            await applyPremium(transaction.revocationDate == nil)
        }
        await transaction.finish()
    }

    private func applyPremium(_ unlocked: Bool) async {
        isPremium = unlocked
        UserDefaults.standard.set(unlocked, forKey: cacheKey)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
