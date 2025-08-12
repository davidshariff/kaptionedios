import Foundation
import CryptoKit
import Combine

#if canImport(RevenueCat)
import RevenueCat
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Manages subscription status and enforces video creation limits with encrypted storage
/// Now integrated with RevenueCat for real payment processing
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var currentStatus: SubscriptionStatus = SubscriptionStatus()
    @Published var isLoading: Bool = false
    @Published var showSubscriptionSuccess: Bool = false
    @Published var successSubscriptionTier: String = ""
    @Published var showAlreadySubscribed: Bool = false
    @Published var showNoVideosLeft: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let subscriptionKey = "encrypted_subscription_data"
    private let deviceKey = "device_identifier"
    
    private init() {
        // Only load local subscription status on init
        // RevenueCat sync will be triggered manually after configuration is ready
        Task { @MainActor in
            loadSubscriptionStatus()
            print("[SubscriptionManager] 📱 Initialized with local subscription status only")
        }
    }
    
    /// Initialize RevenueCat sync after configuration is ready
    func initializeRevenueCatSync() async {
        print("[SubscriptionManager] 🔄 Waiting for ConfigurationManager to be ready...")
        await ConfigurationManager.shared.waitForConfigurationReady()
        print("[SubscriptionManager] ✅ ConfigurationManager ready, proceeding with RevenueCat sync")
        
        await syncWithRevenueCat()
    }
    
    /// Force refresh subscription status from RevenueCat
    func refreshSubscriptionStatus() {
        Task {
            await syncWithRevenueCat()
        }
    }
    
    // MARK: - Public Methods
    
    /// Checks if user can create a new video
    func canCreateNewVideo() -> Bool {
        return currentStatus.canCreateNewVideo
    }
    
    /// Records a new video creation
    @MainActor
    func recordVideoCreation() {
        var newStatus = currentStatus
        newStatus = SubscriptionStatus(
            tier: newStatus.tier,
            videosCreated: newStatus.videosCreated + 1,
            subscriptionExpiryDate: newStatus.subscriptionExpiryDate,
            isActive: newStatus.isActive
        )
        currentStatus = newStatus
        saveSubscriptionStatus(newStatus)
        
        print("[SubscriptionManager] Video creation recorded. Total: \(newStatus.videosCreated)")
    }
    
    /// Gets the remaining video count for current tier
    func getRemainingVideos() -> Int {
        return currentStatus.remainingVideos
    }
    
    /// Show RevenueCat paywall for subscription upgrade
    func showUpgradePaywall() {
        Task { @MainActor in
            // Check if upgrades are allowed via configuration
            let upgradesAllowed = ConfigurationManager.shared.areUpgradesAllowed()
            
            // Check if user is already a pro member and upgrades are enabled
            if currentStatus.tier == .pro && upgradesAllowed {
                // Show unlimited tier paywall for existing pro members
                RevenueCatManager.shared.presentPaywall(offeringIdentifier: "1_tier_unlimited")
                print("[SubscriptionManager] Showing unlimited tier paywall for existing pro member (upgrades enabled)")
            } else if currentStatus.tier == .pro && !upgradesAllowed {
                // Pro users cannot upgrade when upgrades are disabled
                print("[SubscriptionManager] ⚠️ Upgrades disabled - checking video status for pro user")
                
                if currentStatus.remainingVideos > 0 {
                    // User has videos left - show "already subscribed" view
                    showAlreadySubscribed = true
                    print("[SubscriptionManager] Showing already subscribed view for pro user with videos remaining")
                } else {
                    // User has no videos left - show "no videos left" view
                    showNoVideosLeft = true
                    print("[SubscriptionManager] Showing no videos left view for pro user")
                }
            } else if currentStatus.tier == .unlimited && !upgradesAllowed {
                // Unlimited users don't need upgrades, show already subscribed
                showAlreadySubscribed = true
                print("[SubscriptionManager] Showing already subscribed view for unlimited user")
            } else {
                // Show regular paywall for free users
                RevenueCatManager.shared.presentPaywall()
                print("[SubscriptionManager] Showing regular paywall for free user")
            }
        }
    }
    
    /// Show subscription success popup
    @MainActor
    func showSubscriptionSuccessPopup(for tier: SubscriptionTier) {
        successSubscriptionTier = tier.displayName
        showSubscriptionSuccess = true
        print("[SubscriptionManager] 🎉 Showing subscription success popup for: \(tier.displayName)")
    }
    
    /// Dismiss all subscription-related views
    @MainActor
    func dismissAllViews() {
        showSubscriptionSuccess = false
        showAlreadySubscribed = false
        showNoVideosLeft = false
        print("[SubscriptionManager] 📱 All subscription views dismissed")
    }
    
    /// Reset video count when user purchases a new subscription
    @MainActor
    func resetVideoCountForNewSubscription() async {
        print("[SubscriptionManager] 🔄 Resetting video count for new subscription purchase")
        
        // Get current status and reset video count
        let resetStatus = SubscriptionStatus(
            tier: currentStatus.tier,
            videosCreated: 0, // Reset to 0
            subscriptionExpiryDate: currentStatus.subscriptionExpiryDate,
            isActive: currentStatus.isActive
        )
        
        // Update current status and save
        currentStatus = resetStatus
        saveSubscriptionStatus(resetStatus)
        
        print("[SubscriptionManager] ✅ Video count reset to 0 for new subscription")
    }
    
    /// Check if video count should be reset based on subscription renewal
    @MainActor
    func checkAndResetForRenewal() async {
        // This method can be called periodically to check if subscription has renewed
        // and reset video count if needed. For now, it's a placeholder for future enhancement.
        
        guard let expiryDate = currentStatus.subscriptionExpiryDate else {
            return
        }
        
        // If the expiry date has passed and user still has an active subscription,
        // it means the subscription has renewed
        if expiryDate < Date() && currentStatus.isActive && currentStatus.tier != .free {
            print("[SubscriptionManager] 🔄 Subscription appears to have renewed, resetting video count")
            await resetVideoCountForNewSubscription()
        }
    }
    

    
    /// Resets subscription status and clears all RevenueCat data (for testing purposes)
    @MainActor
    func resetSubscription() async {
        // Reset local subscription status
        let newStatus = SubscriptionStatus()
        currentStatus = newStatus
        saveSubscriptionStatus(newStatus)
        
        print("[SubscriptionManager] 🔄 Local subscription reset to free tier")
        
        // Clear RevenueCat data
        await clearRevenueCatData()
        
        print("[SubscriptionManager] ✅ Complete subscription reset finished")
    }
    
    /// Clears all RevenueCat data (local cache and remote user data)
    @MainActor
    private func clearRevenueCatData() async {
        guard await RevenueCatManager.shared.isConfigured else {
            print("[SubscriptionManager] ⚠️ RevenueCat not configured, skipping data clear")
            return
        }
        
        do {
            // Log out current user (clears local cache)
            let customerInfo = try await Purchases.shared.logOut()
            print("[SubscriptionManager] 🔄 RevenueCat user logged out, cache cleared")
            
        } catch {
            // Check if error is just "user already anonymous" - this is expected and OK
            let errorMessage = error.localizedDescription
            if errorMessage.contains("anonymous") {
                print("[SubscriptionManager] ℹ️ User was already anonymous - no logout needed")
            } else {
                print("[SubscriptionManager] ⚠️ Error during RevenueCat logout: \(error)")
            }
        }
        
        // Always reset manager state (whether logout succeeded or not)
        await RevenueCatManager.shared.resetState()
        
        // Create a fresh anonymous user with new UUID (only if RevenueCat is configured)
        if await RevenueCatManager.shared.isConfigured {
            do {
                let newUserID = UUID().uuidString
                let (customerInfo, created) = try await Purchases.shared.logIn(newUserID)
                print("[SubscriptionManager] 🔄 Fresh anonymous RevenueCat user created: \(newUserID)")
            } catch {
                print("[SubscriptionManager] ⚠️ Error creating new anonymous user: \(error)")
                // This is not critical - RevenueCat will work with default anonymous user
            }
        }
    }
    
    // MARK: - RevenueCat Integration
    
    /// Sync local subscription status with RevenueCat
    @MainActor
    func syncWithRevenueCat() async {
        print("[SubscriptionManager] 🔄 Starting sync with RevenueCat...")
        
        // Check if RevenueCat is configured
        guard await RevenueCatManager.shared.isConfigured else {
            print("[SubscriptionManager] ⚠️ RevenueCat not configured, skipping sync")
            return
        }
        
        await RevenueCatManager.shared.loadCustomerInfo()
        
        let revenueCatTier = RevenueCatManager.shared.currentSubscriptionTier
        let revenueCatExpiry = RevenueCatManager.shared.subscriptionExpiryDate
        
        print("[SubscriptionManager] 📊 RevenueCat tier: \(revenueCatTier.displayName)")
        print("[SubscriptionManager] 📊 Local tier before sync: \(currentStatus.tier.displayName)")
        
        // Check if we need to migrate data due to RevenueCat user ID availability
        await migrateToRevenueCatUserID()
        
        // Reload subscription status after potential migration
        loadSubscriptionStatus()
        
        // Update local status to match RevenueCat
        let newStatus = SubscriptionStatus(
            tier: revenueCatTier,
            videosCreated: currentStatus.videosCreated, // Keep local video count (now persistent with RevenueCat ID)
            subscriptionExpiryDate: revenueCatExpiry,
            isActive: RevenueCatManager.shared.hasActiveSubscription || revenueCatTier == .free
        )
        
        // Always update to ensure UI reflects current state
        currentStatus = newStatus
        saveSubscriptionStatus(newStatus)
        print("[SubscriptionManager] ✅ Synced with RevenueCat: \(revenueCatTier.displayName)")
    }
    
    /// Restore purchases from RevenueCat
    func restorePurchases() async -> Bool {
        guard await RevenueCatManager.shared.isConfigured else {
            print("[SubscriptionManager] ⚠️ RevenueCat not configured, cannot restore purchases")
            return false
        }
        
        let success = await RevenueCatManager.shared.restorePurchases()
        if success {
            let previousTier = currentStatus.tier
            await syncWithRevenueCat()
            
            // If user restored a subscription and they were previously free, reset video count
            if previousTier == .free && currentStatus.tier != .free {
                await resetVideoCountForNewSubscription()
                print("[SubscriptionManager] 🔄 Video count reset due to successful purchase restoration")
            }
        }
        return success
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func loadSubscriptionStatus() {
        let keyToUse = getStorageKey()
        
        guard let encryptedData = userDefaults.data(forKey: keyToUse) else {
            print("[SubscriptionManager] No subscription data found for key: \(keyToUse), using default free tier")
            return
        }
        
        do {
            let decryptedData = try decryptData(encryptedData)
            let status = try JSONDecoder().decode(SubscriptionStatus.self, from: decryptedData)
            currentStatus = status
            print("[SubscriptionManager] Loaded subscription status: \(status.tier.displayName), videos: \(status.videosCreated)")
        } catch {
            print("[SubscriptionManager] Failed to load subscription status: \(error), using default")
            currentStatus = SubscriptionStatus()
        }
    }
    
    @MainActor
    private func saveSubscriptionStatus(_ status: SubscriptionStatus) {
        let keyToUse = getStorageKey()
        
        do {
            let data = try JSONEncoder().encode(status)
            let encryptedData = try encryptData(data)
            userDefaults.set(encryptedData, forKey: keyToUse)
            print("[SubscriptionManager] Subscription status saved successfully with key: \(keyToUse)")
        } catch {
            print("[SubscriptionManager] Failed to save subscription status: \(error)")
        }
    }
    
    /// Get the appropriate storage key based on available RevenueCat user ID
    @MainActor
    private func getStorageKey() -> String {
        if let revenueCatUserID = getRevenueCatUserID() {
            let revenueCatKey = "rc_" + revenueCatUserID
            return "encrypted_subscription_data_" + revenueCatKey
        } else {
            // Fallback to original key for backwards compatibility
            return subscriptionKey
        }
    }
    
    // MARK: - Encryption Methods
    
    @MainActor
    private func getDeviceKey() -> String {
        // First, try to get RevenueCat user ID for persistent tracking
        if let revenueCatUserID = getRevenueCatUserID() {
            let keyString = "rc_" + revenueCatUserID
            print("[SubscriptionManager] Using RevenueCat user ID for encryption key: \(revenueCatUserID)")
            return keyString
        }
        
        // Fallback to device-based key for backwards compatibility
        if let existingKey = userDefaults.string(forKey: deviceKey) {
            return existingKey
        }
        
        // Generate a unique device identifier as last resort
        #if canImport(UIKit)
        let vendorID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        let vendorID = UUID().uuidString
        #endif
        let deviceKey = UUID().uuidString + Bundle.main.bundleIdentifier! + vendorID
        let deviceKeyData = deviceKey.data(using: .utf8)!
        let hashedKey = SHA256.hash(data: deviceKeyData)
        let keyString = hashedKey.compactMap { String(format: "%02x", $0) }.joined()
        
        userDefaults.set(keyString, forKey: deviceKey)
        print("[SubscriptionManager] ⚠️ Using fallback device-based key")
        return keyString
    }
    
    /// Get RevenueCat user ID for persistent video count tracking
    @MainActor
    private func getRevenueCatUserID() -> String? {
        guard RevenueCatManager.shared.isConfigured else {
            print("[SubscriptionManager] RevenueCat not configured, cannot get user ID")
            return nil
        }
        
        guard let customerInfo = RevenueCatManager.shared.customerInfo else {
            print("[SubscriptionManager] No RevenueCat customer info available")
            return nil
        }
        
        let userID = customerInfo.originalAppUserId
        print("[SubscriptionManager] Retrieved RevenueCat user ID: \(userID)")
        return userID
    }
    
    /// Migrate existing subscription data from device-based key to RevenueCat user ID
    @MainActor
    private func migrateToRevenueCatUserID() async {
        // Only migrate if we have RevenueCat user ID and old device-based data exists
        guard let revenueCatUserID = getRevenueCatUserID() else {
            print("[SubscriptionManager] No RevenueCat user ID available for migration")
            return
        }
        
        let revenueCatKey = "rc_" + revenueCatUserID
        let revenueCatSubscriptionKey = "encrypted_subscription_data_" + revenueCatKey
        
        // Check if we already have data with RevenueCat key
        if userDefaults.data(forKey: revenueCatSubscriptionKey) != nil {
            print("[SubscriptionManager] RevenueCat-based data already exists, no migration needed")
            return
        }
        
        // Check if we have old device-based data to migrate
        if let oldEncryptedData = userDefaults.data(forKey: subscriptionKey) {
            print("[SubscriptionManager] 🔄 Migrating subscription data to RevenueCat user ID...")
            
            do {
                // Try to decrypt old data with device-based key
                let oldDeviceKey = getOldDeviceKey()
                let oldKeyData = oldDeviceKey.data(using: .utf8)!
                let oldKeyHash = SHA256.hash(data: oldKeyData)
                let oldSymmetricKey = SymmetricKey(data: oldKeyHash)
                
                let oldSealedBox = try AES.GCM.SealedBox(combined: oldEncryptedData)
                let decryptedData = try AES.GCM.open(oldSealedBox, using: oldSymmetricKey)
                
                // Re-encrypt with RevenueCat-based key
                let newKeyData = revenueCatKey.data(using: .utf8)!
                let newKeyHash = SHA256.hash(data: newKeyData)
                let newSymmetricKey = SymmetricKey(data: newKeyHash)
                
                let newSealedBox = try AES.GCM.seal(decryptedData, using: newSymmetricKey)
                
                // Save with new key
                userDefaults.set(newSealedBox.combined!, forKey: revenueCatSubscriptionKey)
                
                // Remove old data
                userDefaults.removeObject(forKey: subscriptionKey)
                
                print("[SubscriptionManager] ✅ Successfully migrated subscription data to RevenueCat user ID")
                
            } catch {
                print("[SubscriptionManager] ⚠️ Failed to migrate subscription data: \(error)")
                // If migration fails, we'll start fresh with the new system
            }
        } else {
            print("[SubscriptionManager] No old subscription data to migrate")
        }
    }
    
    /// Get the old device-based key for migration purposes
    private func getOldDeviceKey() -> String {
        if let existingKey = userDefaults.string(forKey: deviceKey) {
            return existingKey
        }
        
        // Generate the same key that would have been created originally
        #if canImport(UIKit)
        let vendorID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        let vendorID = UUID().uuidString
        #endif
        let deviceKey = UUID().uuidString + Bundle.main.bundleIdentifier! + vendorID
        let deviceKeyData = deviceKey.data(using: .utf8)!
        let hashedKey = SHA256.hash(data: deviceKeyData)
        let keyString = hashedKey.compactMap { String(format: "%02x", $0) }.joined()
        
        return keyString
    }
    
    @MainActor
    private func encryptData(_ data: Data) throws -> Data {
        let key = getDeviceKey()
        let keyData = key.data(using: .utf8)!
        let keyHash = SHA256.hash(data: keyData)
        let symmetricKey = SymmetricKey(data: keyHash)
        
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        return sealedBox.combined!
    }
    
    @MainActor
    private func decryptData(_ encryptedData: Data) throws -> Data {
        let key = getDeviceKey()
        let keyData = key.data(using: .utf8)!
        let keyHash = SHA256.hash(data: keyData)
        let symmetricKey = SymmetricKey(data: keyHash)
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
}

// MARK: - Extensions

extension SubscriptionManager {
    
    /// Gets a user-friendly message about subscription limits
    func getSubscriptionMessage() -> String {
        let status = currentStatus
        
        switch status.tier {
        case .free:
            if status.videosCreated >= 1 {
                let proMax = SubscriptionTier.pro.maxVideos
                return "You've used your free video. Upgrade to Pro for \(proMax) videos or Unlimited for unlimited videos!"
            } else {
                return "You have 1 free video remaining."
            }
        case .pro:
            if status.remainingVideos == 0 {
                if let expiryDate = status.subscriptionExpiryDate {
                    let daysUntilRenewal = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
                    if daysUntilRenewal > 0 {
                        return "You've reached your Pro limit of \(status.tier.maxVideos) videos. You'll be able to create videos again in \(daysUntilRenewal) day\(daysUntilRenewal == 1 ? "" : "s")."
                    } else {
                        return "You've reached your Pro limit of \(status.tier.maxVideos) videos. Your subscription will renew soon!"
                    }
                } else {
                    return "You've reached your Pro limit of \(status.tier.maxVideos) videos. Upgrade to Unlimited for unlimited videos!"
                }
            } else {
                return "You have \(status.remainingVideos) video\(status.remainingVideos == 1 ? "" : "s") remaining in your Pro plan."
            }
        case .unlimited:
            return "Unlimited videos with your Unlimited subscription!"
        }
    }
    
    /// Gets the upgrade message for the current tier
    func getUpgradeMessage() -> String {
        switch currentStatus.tier {
        case .free:
            let proMax = SubscriptionTier.pro.maxVideos
            return "Upgrade to Pro for \(proMax) videos per month or Unlimited for unlimited videos!"
        case .pro:
            return "Upgrade to Unlimited for unlimited videos and no monthly limits!"
        case .unlimited:
            return "You already have unlimited access to all features!"
        }
    }
}
