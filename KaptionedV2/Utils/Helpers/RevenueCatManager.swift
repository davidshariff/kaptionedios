import Foundation
import UIKit
import RevenueCat
import RevenueCatUI

/// RevenueCat integration manager for handling subscriptions and purchases
@MainActor
class RevenueCatManager: NSObject, ObservableObject {
    static let shared = RevenueCatManager()
    
    @Published var customerInfo: CustomerInfo?
    @Published var offerings: Offerings?
    @Published var isLoading = false
    @Published var error: Error?
    
    // RevenueCat Configuration
    private let apiKey: String = RevenueCatConfig.APIKeys.current
    private let proEntitlementID = RevenueCatConfig.Entitlements.proAccess
    private let unlimitedEntitlementID = RevenueCatConfig.Entitlements.unlimitedAccess
    
    private override init() {
        // Configuration is now handled by RevenueCatConfig
        super.init()
    }
    
    // MARK: - Configuration
    
    /// Configure RevenueCat on app launch
    func configure() {
        guard !apiKey.contains("YOUR_") else {
            print("⚠️ [RevenueCatManager] Please set your RevenueCat API key")
            return
        }
        
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        
        // Set up delegate
        Purchases.shared.delegate = self
        
        print("✅ [RevenueCatManager] RevenueCat configured successfully")
        
        // Load initial data
        Task {
            await loadCustomerInfo()
            await loadOfferings()
        }
    }
    
    /// Identify user with RevenueCat
    func identifyUser(userID: String) {
        Task {
            do {
                let (customerInfo, _) = try await Purchases.shared.logIn(userID)
                await MainActor.run {
                    self.customerInfo = customerInfo
                }
                print("✅ [RevenueCatManager] User identified: \(userID)")
            } catch {
                await MainActor.run {
                    self.error = error
                }
                print("❌ [RevenueCatManager] Failed to identify user: \(error)")
            }
        }
    }
    
    // MARK: - Data Loading
    
    /// Load customer information
    func loadCustomerInfo() async {
        await MainActor.run { isLoading = true }
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await MainActor.run {
                self.customerInfo = customerInfo
                self.isLoading = false
            }
            print("✅ [RevenueCatManager] Customer info loaded")
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            print("❌ [RevenueCatManager] Failed to load customer info: \(error)")
        }
    }
    
    /// Load available offerings
    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            await MainActor.run {
                self.offerings = offerings
            }
            print("✅ [RevenueCatManager] Offerings loaded: \(offerings.all.keys)")
        } catch {
            await MainActor.run {
                self.error = error
            }
            print("❌ [RevenueCatManager] Failed to load offerings: \(error)")
        }
    }
    
    // MARK: - Debug and Analysis
    
    /// Get detailed subscription information for debugging
    func getSubscriptionDebugInfo() -> String {
        guard let customerInfo = customerInfo else {
            return "No customer info available"
        }
        
        var info = ["=== RevenueCat Debug Info ==="]
        
        // Customer info
        info.append("User ID: \(customerInfo.originalAppUserId)")
        info.append("Active Subscriptions: \(customerInfo.activeSubscriptions)")
        
        // Current detected tier
        info.append("Detected Tier: \(currentSubscriptionTier.displayName)")
        
        // All entitlements
        info.append("\n--- All Entitlements ---")
        for (key, entitlement) in customerInfo.entitlements.all {
            info.append("• \(key): active=\(entitlement.isActive), product=\(entitlement.productIdentifier)")
        }
        
        // Active entitlements
        info.append("\n--- Active Entitlements ---")
        for (key, entitlement) in customerInfo.entitlements.active {
            info.append("• \(key): product=\(entitlement.productIdentifier), expires=\(entitlement.expirationDate?.description ?? "never")")
        }
        
        // Tier mapping
        let tierMapping = detectTierMapping()
        info.append("\n--- Product → Tier Mapping ---")
        for (product, tier) in tierMapping {
            info.append("• \(product) → \(tier.displayName)")
        }
        
        // Offerings
        if let offerings = offerings {
            info.append("\n--- Available Offerings ---")
            for (key, offering) in offerings.all {
                info.append("• \(key): \(offering.availablePackages.count) packages")
                for package in offering.availablePackages {
                    info.append("  - \(package.packageType.rawValue): \(package.storeProduct.productIdentifier)")
                }
            }
        } else {
            info.append("\n--- No Offerings Available ---")
            info.append("This is why tier detection is using hardcoded mappings")
        }
        
        return info.joined(separator: "\n")
    }
    
    /// Automatically detect tier mapping from RevenueCat offerings
    func detectTierMapping() -> [String: SubscriptionTier] {
        var tierMapping: [String: SubscriptionTier] = [:]
        
        // Create mapping for your actual 5 product IDs
        
        // Pro tier (3 products)
        tierMapping["1m_subscription"] = .pro              // Pro Monthly
        tierMapping["1y_subscription"] = .pro              // Pro Yearly  
        tierMapping["1y_subscription_pro"] = .pro          // Pro Yearly Alt
        
        // Unlimited tier (2 products)
        tierMapping["1y_unlimited"] = .unlimited           // Unlimited Yearly
        tierMapping["1m_subscription_unlimited"] = .unlimited  // Unlimited Monthly
        
        print("[RevenueCatManager] 🔍 Mapped 5 actual product IDs: 3 Pro + 2 Unlimited")
        
        // If offerings are available, check for unmapped products
        if let offerings = offerings {
            print("[RevenueCatManager] 🔍 Analyzing \(offerings.all.count) offerings...")
            
            var foundProducts: Set<String> = []
            var unmappedProducts: [String] = []
            
            for (offeringKey, offering) in offerings.all {
                print("[RevenueCatManager] 🔍 Analyzing offering: \(offeringKey)")
                
                for package in offering.availablePackages {
                    let productId = package.storeProduct.productIdentifier
                    foundProducts.insert(productId)
                    
                    // Check if this product is mapped
                    if tierMapping[productId] == nil {
                        unmappedProducts.append(productId)
                    }
                }
            }
            
            // Report findings
            print("[RevenueCatManager] 🔍 Found \(foundProducts.count) products in RevenueCat offerings")
            
            if !unmappedProducts.isEmpty {
                print("⚠️ [RevenueCatManager] WARNING: Found \(unmappedProducts.count) unmapped products:")
                for product in unmappedProducts {
                    print("⚠️ [RevenueCatManager]   • \(product) - NOT MAPPED TO ANY TIER")
                }
                print("⚠️ [RevenueCatManager] These products won't be recognized by the app!")
                print("⚠️ [RevenueCatManager] Add them to the tierMapping in detectTierMapping()")
            } else {
                print("✅ [RevenueCatManager] All RevenueCat products are properly mapped")
            }
        } else {
            print("[RevenueCatManager] 🔍 No offerings available, using hardcoded mapping only")
        }
        
        print("[RevenueCatManager] 🔍 Final tier mapping: \(tierMapping)")
        return tierMapping
    }
    
    // MARK: - Reset and Cleanup
    
    /// Resets all RevenueCat manager state (for testing)
    @MainActor
    func resetState() {
        customerInfo = nil
        offerings = nil
        isLoading = false
        error = nil
        
        print("[RevenueCatManager] 🔄 Manager state reset")
    }
    
    // MARK: - Subscription Status
    
    /// Get current subscription tier based on RevenueCat entitlements
    var currentSubscriptionTier: SubscriptionTier {
        guard let customerInfo = customerInfo else { 
            print("[RevenueCatManager] 📊 No customer info available, returning .free")
            return .free 
        }
        
        print("[RevenueCatManager] 📊 Checking entitlements...")
        print("[RevenueCatManager] 📊 All available entitlements: \(Array(customerInfo.entitlements.all.keys))")
        
        // Debug all entitlements with their product identifiers
        for (key, entitlement) in customerInfo.entitlements.all {
            print("[RevenueCatManager] 📊 Entitlement '\(key)': isActive = \(entitlement.isActive), productIdentifier = \(entitlement.productIdentifier)")
        }
        
        // Get active entitlements
        let activeEntitlements = customerInfo.entitlements.active
        print("[RevenueCatManager] 📊 Active entitlements: \(Array(activeEntitlements.keys))")
        
        // If no active entitlements, return free
        guard !activeEntitlements.isEmpty else {
            print("[RevenueCatManager] 📊 Detected tier: Free (no active entitlements)")
            return .free
        }
        
        // Get tier mapping from offerings
        let tierMapping = detectTierMapping()
        
        // Analyze active entitlements to determine tier
        for (entitlementKey, entitlement) in activeEntitlements {
            let productId = entitlement.productIdentifier
            let entitlementName = entitlementKey.lowercased()
            
            print("[RevenueCatManager] 📊 Analyzing entitlement '\(entitlementKey)' with product '\(productId)'")
            
            // First, try to use the tier mapping from offerings
            if let mappedTier = tierMapping[productId] {
                print("[RevenueCatManager] 📊 Detected tier: \(mappedTier.displayName) (mapped from product: \(productId))")
                return mappedTier
            }
            
            // Fallback: Check entitlement and product names for tier indicators
            if entitlementName.contains("unlimited") || productId.lowercased().contains("unlimited") {
                print("[RevenueCatManager] 📊 Detected tier: Unlimited (entitlement: \(entitlementKey))")
                return .unlimited
            }
            
            if entitlementName.contains("pro") || productId.lowercased().contains("pro") {
                print("[RevenueCatManager] 📊 Detected tier: Pro (entitlement: \(entitlementKey))")
                return .pro
            }
        }
        
        // If we have active entitlements but can't categorize them, 
        // assume the first one is Pro (since you only have Pro and Unlimited)
        let firstEntitlement = activeEntitlements.first!
        print("[RevenueCatManager] 📊 Could not categorize entitlement, assuming Pro for: \(firstEntitlement.key)")
        return .pro
    }
    
    /// Check if user has active subscription
    var hasActiveSubscription: Bool {
        return currentSubscriptionTier != .free
    }
    
    /// Get subscription expiry date
    var subscriptionExpiryDate: Date? {
        guard let customerInfo = customerInfo else { return nil }
        
        // Get the active entitlements
        let activeEntitlements = customerInfo.entitlements.active
        
        // Prefer unlimited, then pro, then any active entitlement
        if let unlimited = activeEntitlements.first(where: { $0.key.lowercased().contains("unlimited") }) {
            return unlimited.value.expirationDate
        } else if let pro = activeEntitlements.first(where: { 
            let key = $0.key.lowercased()
            return key.contains("pro") || key.contains("monthly") || key.contains("yearly")
        }) {
            return pro.value.expirationDate
        } else if let firstActive = activeEntitlements.first {
            return firstActive.value.expirationDate
        }
        
        return nil
    }
    
    // MARK: - Paywall Methods
    
    /// Present RevenueCat's built-in paywall
    func presentPaywall() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ [RevenueCatManager] Could not find root view controller for paywall")
            return
        }
        
        // Find the topmost presented view controller
        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }
        
        // Get configured paywall offering from ConfigurationManager
        let configuredOffering = ConfigurationManager.shared.getPaywallOffering()
        
        // Try to find the configured offering, fall back to default if not available
        if let offerings = offerings,
           let configuredOfferingObj = offerings.all[configuredOffering] {
            // Use configured offering
            let paywallViewController = PaywallViewController(offering: configuredOfferingObj)
            paywallViewController.delegate = self
            
            // Apply paywall theme configuration
            applyPaywallTheme(paywallViewController)
            
            topController.present(paywallViewController, animated: true)
            print("✅ [RevenueCatManager] Paywall presented with configured offering: \(configuredOffering)")
        } else {
            // Fall back to default paywall
            let paywallViewController = PaywallViewController()
            paywallViewController.delegate = self
            
            // Apply paywall theme configuration
            applyPaywallTheme(paywallViewController)
            
            topController.present(paywallViewController, animated: true)
            print("⚠️ [RevenueCatManager] Paywall presented with default offering (configured offering '\(configuredOffering)' not found)")
        }
    }
    
    /// Present paywall for specific offering
    func presentPaywall(offering: Offering) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ [RevenueCatManager] Could not find root view controller for paywall")
            return
        }
        
        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }
        
        let paywallViewController = PaywallViewController(offering: offering)
        paywallViewController.delegate = self
        
        topController.present(paywallViewController, animated: true)
        print("✅ [RevenueCatManager] Paywall presented with offering: \(offering.identifier)")
    }
    
    /// Apply paywall theme configuration
    private func applyPaywallTheme(_ paywallViewController: PaywallViewController) {
        let paywallTheme = ConfigurationManager.shared.getPaywallTheme()
        
        // Apply theme configuration to the paywall
        switch paywallTheme.lowercased() {
        case "light":
            paywallViewController.view.backgroundColor = UIColor.white
            // You can add more light theme styling here
        case "dark":
            paywallViewController.view.backgroundColor = UIColor.black
            // You can add more dark theme styling here
        default:
            // Use system default
            break
        }
        
        print("🎨 [RevenueCatManager] Applied paywall theme: \(paywallTheme)")
    }
    
    // MARK: - Purchase Methods
    
    /// Purchase a subscription package (now mainly used internally)
    func purchasePackage(_ package: Package) async -> Bool {
        await MainActor.run { isLoading = true }
        
        do {
            let (_, customerInfo, _) = try await Purchases.shared.purchase(package: package)
            
            await MainActor.run {
                self.customerInfo = customerInfo
                self.isLoading = false
            }
            
            print("✅ [RevenueCatManager] Purchase successful: \(package.storeProduct.localizedTitle)")
            return true
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            
            print("❌ [RevenueCatManager] Purchase failed: \(error)")
            return false
        }
    }
    
    /// Restore purchases
    func restorePurchases() async -> Bool {
        await MainActor.run { isLoading = true }
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            
            await MainActor.run {
                self.customerInfo = customerInfo
                self.isLoading = false
            }
            
            print("✅ [RevenueCatManager] Purchases restored")
            return true
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            
            print("❌ [RevenueCatManager] Failed to restore purchases: \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get available packages for a specific tier
    func getPackages(for tier: SubscriptionTier) -> [Package] {
        guard let offerings = offerings else { return [] }
        
        var packages: [Package] = []
        
        switch tier {
        case .pro:
            // Look for pro packages in current offering
            if let current = offerings.current {
                packages = current.availablePackages.filter { package in
                    let productId = package.storeProduct.productIdentifier.lowercased()
                    return productId.contains("pro") || productId.contains("monthly") || productId.contains("yearly")
                }
            }
        case .unlimited:
            // Look for unlimited packages
            if let current = offerings.current {
                packages = current.availablePackages.filter { package in
                    package.storeProduct.productIdentifier.lowercased().contains("unlimited")
                }
            }
        case .free:
            break // No packages for free tier
        }
        
        return packages
    }
    
    /// Get the best package for a tier (usually monthly)
    func getBestPackage(for tier: SubscriptionTier) -> Package? {
        let packages = getPackages(for: tier)
        
        // Prefer monthly packages
        return packages.first { $0.packageType == .monthly } ?? packages.first
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            print("🔄 [RevenueCatManager] Customer info updated via delegate")
        }
    }
}

// MARK: - PaywallViewControllerDelegate

extension RevenueCatManager: PaywallViewControllerDelegate {
    nonisolated func paywallViewController(_ controller: PaywallViewController, didFinishPurchasingWith customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            print("✅ [RevenueCatManager] Paywall purchase completed successfully")
            
            // Sync with local subscription manager
            await SubscriptionManager.shared.syncWithRevenueCat()
            
            // Dismiss the paywall
            controller.dismiss(animated: true)
        }
    }
    
    nonisolated func paywallViewControllerDidCancel(_ controller: PaywallViewController) {
        print("ℹ️ [RevenueCatManager] Paywall was cancelled by user")
        Task { @MainActor in
            controller.dismiss(animated: true)
        }
    }
    
    private nonisolated func paywallViewController(_ controller: PaywallViewController, didFailPurchasingWith error: any Error) {
        print("❌ [RevenueCatManager] Paywall purchase failed: \(error)")
        // Don't dismiss automatically on error - let user try again
    }
}
