import Foundation
import StoreKit
import SwiftUI

/// Manages TinyWins Plus subscriptions using StoreKit 2
@MainActor
final class SubscriptionManager: ObservableObject {
    /// Shared singleton instance for backward compatibility.
    /// New code should use dependency injection via DependencyContainer.
    static let shared = SubscriptionManager()

    // MARK: - Product IDs (nonisolated for Swift 6 compatibility)

    nonisolated static let monthlyProductId = "com.tinywins.plus.monthly"
    nonisolated static let yearlyProductId = "com.tinywins.plus.yearly"

    // MARK: - UserDefaults Keys for Cached State

    private nonisolated static let cachedSubscriptionStatusKey = "com.tinywins.cachedSubscriptionStatus"
    private nonisolated static let cachedSubscriptionExpiryKey = "com.tinywins.cachedSubscriptionExpiry"
    private nonisolated static let lastVerificationDateKey = "com.tinywins.lastVerificationDate"

    // MARK: - Dependencies

    private let featureFlags: FeatureFlags
    private let userDefaults: UserDefaults

    // MARK: - Published State

    @Published private(set) var isPlusSubscriber: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIds: Set<String> = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasPendingTransaction: Bool = false
    @Published private(set) var isInBillingRetry: Bool = false
    @Published private(set) var isInGracePeriod: Bool = false

    // MARK: - Computed Properties

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductId }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyProductId }
    }

    /// The effective subscription status, considering debug overrides.
    /// Use this everywhere in UI and logic to check premium access.
    var effectiveIsPlusSubscriber: Bool {
        #if DEBUG
        if featureFlags.debugUnlockPlus { return true }
        #endif
        return isPlusSubscriber
    }

    // MARK: - Initialization

    private var updateListenerTask: Task<Void, Error>?

    /// Creates a new SubscriptionManager with injected dependencies.
    /// - Parameter featureFlags: The feature flags instance. Defaults to shared singleton for backward compatibility.
    /// - Parameter userDefaults: UserDefaults instance for caching. Defaults to standard.
    init(featureFlags: FeatureFlags = .shared, userDefaults: UserDefaults = .standard) {
        self.featureFlags = featureFlags
        self.userDefaults = userDefaults

        // Restore cached subscription status immediately for offline support
        self.isPlusSubscriber = loadCachedSubscriptionStatus()

        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load products and verify subscription status with StoreKit
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Cached State Management

    /// Load cached subscription status for offline support
    private func loadCachedSubscriptionStatus() -> Bool {
        let cachedStatus = userDefaults.bool(forKey: Self.cachedSubscriptionStatusKey)
        let cachedExpiry = userDefaults.object(forKey: Self.cachedSubscriptionExpiryKey) as? Date

        // If we have a cached expiry date and it's in the future, trust the cached status
        if let expiry = cachedExpiry, expiry > Date() {
            return cachedStatus
        }

        // If expired or no expiry, return cached status but verification will update it
        return cachedStatus
    }

    /// Save subscription status to cache
    private func cacheSubscriptionStatus(_ isSubscribed: Bool, expiryDate: Date?) {
        userDefaults.set(isSubscribed, forKey: Self.cachedSubscriptionStatusKey)
        if let expiry = expiryDate {
            userDefaults.set(expiry, forKey: Self.cachedSubscriptionExpiryKey)
        } else {
            userDefaults.removeObject(forKey: Self.cachedSubscriptionExpiryKey)
        }
        userDefaults.set(Date(), forKey: Self.lastVerificationDateKey)
    }
    
    // MARK: - Feature Access
    
    func canUsePremiumFeature(_ feature: PremiumFeature) -> Bool {
        return effectiveIsPlusSubscriber
    }
    
    func canAddChild(currentCount: Int) -> Bool {
        if effectiveIsPlusSubscriber {
            return currentCount < TierLimits.plusMaxChildren
        } else {
            return currentCount < TierLimits.freeMaxChildren
        }
    }
    
    func canAddActiveGoal(currentActiveCount: Int) -> Bool {
        if effectiveIsPlusSubscriber {
            return currentActiveCount < TierLimits.plusMaxActiveGoalsPerChild
        } else {
            return currentActiveCount < TierLimits.freeMaxActiveGoalsPerChild
        }
    }
    
    func maxInsightsDays() -> Int {
        effectiveIsPlusSubscriber ? TierLimits.plusInsightsDays : TierLimits.freeInsightsDays
    }
    
    func maxHistoryDays() -> Int {
        effectiveIsPlusSubscriber ? TierLimits.plusHistoryDays : TierLimits.freeHistoryDays
    }

    func maxReflectionHistoryDays() -> Int {
        effectiveIsPlusSubscriber ? TierLimits.plusReflectionHistoryDays : TierLimits.freeReflectionHistoryDays
    }

    // MARK: - StoreKit Operations
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIds = [Self.monthlyProductId, Self.yearlyProductId]
            products = try await Product.products(for: productIds)
            products.sort { $0.price < $1.price }
        } catch {
            errorMessage = "Could not load subscription options."
            CrashReporter.logStoreKitFailure(operation: "loadProducts", error: error)
        }
        
        isLoading = false
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus()
                AnalyticsTracker.shared.trackSubscriptionStarted(productId: product.id)
                return true
                
            case .userCancelled:
                return false
                
            case .pending:
                errorMessage = "Purchase is pending approval."
                return false
                
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
            CrashReporter.logStoreKitFailure(operation: "purchase", error: error, productId: product.id)
            throw error
        }
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            // Track restore if user now has a subscription
            if isPlusSubscriber, let productId = purchasedProductIds.first {
                AnalyticsTracker.shared.trackSubscriptionRestored(productId: productId)
            }
        } catch {
            errorMessage = "Could not restore purchases."
            CrashReporter.logStoreKitFailure(operation: "restorePurchases", error: error)
        }
    }
    
    // MARK: - Private Methods

    private func updateSubscriptionStatus() async {
        var validSubscription = false
        var latestExpiryDate: Date?
        var inBillingRetry = false
        var inGracePeriod = false
        var newPurchasedIds: Set<String> = []

        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            let productId = transaction.productID
            guard productId == Self.monthlyProductId || productId == Self.yearlyProductId else {
                continue
            }

            // Check if transaction has been revoked
            if transaction.revocationDate != nil {
                continue
            }

            newPurchasedIds.insert(productId)

            // Check subscription status for auto-renewable subscriptions
            if let subscriptionInfo = await getSubscriptionStatus(for: productId) {
                switch subscriptionInfo.state {
                case .subscribed:
                    validSubscription = true
                case .inBillingRetryPeriod:
                    // User is in billing retry - still grant access per Apple guidelines
                    validSubscription = true
                    inBillingRetry = true
                case .inGracePeriod:
                    // User is in grace period - still grant access per Apple guidelines
                    validSubscription = true
                    inGracePeriod = true
                case .expired, .revoked:
                    // Subscription is no longer valid
                    break
                default:
                    // For unknown states, check expiration date
                    if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                        validSubscription = true
                    }
                }

                // Track the latest expiry date for caching from the transaction
                if let expirationDate = transaction.expirationDate,
                   expirationDate > (latestExpiryDate ?? .distantPast) {
                    latestExpiryDate = expirationDate
                }
            } else {
                // Fallback: Check transaction expiration date directly
                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        validSubscription = true
                    }
                    if expirationDate > (latestExpiryDate ?? .distantPast) {
                        latestExpiryDate = expirationDate
                    }
                }
            }
        }

        // Update published state
        let wasSubscriber = isPlusSubscriber
        purchasedProductIds = newPurchasedIds
        isPlusSubscriber = validSubscription
        isInBillingRetry = inBillingRetry
        isInGracePeriod = inGracePeriod

        // Cache the status for offline support
        cacheSubscriptionStatus(validSubscription, expiryDate: latestExpiryDate)

        // Notify SyncManager if premium status changed (enables/disables cloud sync)
        if wasSubscriber != validSubscription {
            Task { @MainActor in
                SyncManager.shared.onPremiumStatusChanged()
            }
        }

        // Check for pending transactions
        await checkForPendingTransactions()
    }

    /// Get subscription status for a product
    private func getSubscriptionStatus(for productId: String) async -> Product.SubscriptionInfo.Status? {
        guard let product = products.first(where: { $0.id == productId }),
              let subscription = product.subscription else {
            return nil
        }

        do {
            let statuses = try await subscription.status
            // Return the first active status for this product
            return statuses.first { status in
                guard case .verified(let transaction) = status.transaction else { return false }
                return transaction.productID == productId
            }
        } catch {
            CrashReporter.logStoreKitFailure(operation: "getSubscriptionStatus", error: error, productId: productId)
            return nil
        }
    }

    /// Check for pending transactions that need attention
    private func checkForPendingTransactions() async {
        var hasPending = false

        for await result in Transaction.unfinished {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.monthlyProductId ||
                   transaction.productID == Self.yearlyProductId {
                    hasPending = true
                    break
                }
            }
        }

        hasPendingTransaction = hasPending
    }

    private func listenForTransactions() -> Task<Void, Error> {
        // Use weak self for safety. SubscriptionManager is a singleton that should
        // never be deallocated, but using weak prevents crashes if it somehow is.
        // We log critical errors if self becomes nil during transaction processing.
        return Task.detached { [weak self] in
            #if DEBUG
            print("[SubscriptionManager] Transaction listener started")
            #endif

            for await result in Transaction.updates {
                guard let self = self else {
                    // This should never happen with a singleton, but handle gracefully
                    #if DEBUG
                    assertionFailure("[SubscriptionManager] CRITICAL: SubscriptionManager deallocated while listening for transactions")
                    #endif
                    CrashReporter.logNonFatal(
                        NSError(
                            domain: "SubscriptionManager",
                            code: -999,
                            userInfo: [NSLocalizedDescriptionKey: "SubscriptionManager deallocated during transaction listening"]
                        ),
                        context: "Transaction listener lost reference to SubscriptionManager"
                    )
                    return
                }

                switch result {
                case .verified(let transaction):
                    #if DEBUG
                    print("[SubscriptionManager] Received verified transaction: \(transaction.productID)")
                    #endif
                    // Finish the transaction and update status
                    await transaction.finish()
                    await self.updateSubscriptionStatus()

                case .unverified(let transaction, let error):
                    #if DEBUG
                    print("[SubscriptionManager] Received unverified transaction: \(transaction.productID), error: \(error)")
                    #endif
                    // Log unverified transactions but don't grant access
                    CrashReporter.logSubscriptionVerificationFailure(
                        reason: error.localizedDescription,
                        productId: transaction.productID
                    )
                    // Still finish the transaction to prevent re-delivery
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }

            #if DEBUG
            print("[SubscriptionManager] Transaction listener ended unexpectedly")
            #endif
        }
    }

    /// Restart the transaction listener if it was cancelled or ended unexpectedly.
    /// Call this on app foreground to ensure we don't miss transactions.
    func ensureTransactionListenerRunning() {
        if updateListenerTask?.isCancelled == true || updateListenerTask == nil {
            #if DEBUG
            print("[SubscriptionManager] Restarting transaction listener")
            #endif
            updateListenerTask = listenForTransactions()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case failedVerification
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed."
        case .purchaseFailed:
            return "Purchase could not be completed."
        }
    }
}

// MARK: - Price Formatting

extension Product {
    var localizedPricePerMonth: String {
        if id == SubscriptionManager.yearlyProductId {
            let monthlyPrice = price / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = priceFormatStyle.locale
            return formatter.string(from: monthlyPrice as NSDecimalNumber) ?? displayPrice
        }
        return displayPrice
    }

    /// Calculate actual savings percentage compared to monthly pricing.
    /// Returns nil if comparison cannot be made (e.g., monthly product not available).
    func savingsPercentage(comparedTo monthlyProduct: Product?) -> Int? {
        guard id == SubscriptionManager.yearlyProductId,
              let monthly = monthlyProduct else {
            return nil
        }

        // Calculate yearly cost if paying monthly
        let yearlyAtMonthlyRate = monthly.price * 12

        // Ensure we're not dividing by zero and yearly is actually cheaper
        guard yearlyAtMonthlyRate > 0, price < yearlyAtMonthlyRate else {
            return nil
        }

        // Calculate savings percentage
        let savings = ((yearlyAtMonthlyRate - price) / yearlyAtMonthlyRate) * 100
        return NSDecimalNumber(decimal: savings).intValue
    }

    /// Deprecated: Use savingsPercentage(comparedTo:) for accurate calculation
    var savingsPercentage: Int? {
        // Return nil to indicate savings should be calculated dynamically
        // This prevents showing potentially incorrect hardcoded values
        if id == SubscriptionManager.yearlyProductId {
            // Will be calculated dynamically in UI using savingsPercentage(comparedTo:)
            return nil
        }
        return nil
    }

    /// Returns "month" or "year" for display in subscription text
    var subscriptionPeriodText: String {
        if id == SubscriptionManager.yearlyProductId {
            return "year"
        }
        return "month"
    }

    /// Returns "monthly" or "yearly" for renewal disclosure text
    var renewalPeriodText: String {
        if id == SubscriptionManager.yearlyProductId {
            return "yearly"
        }
        return "monthly"
    }
}
