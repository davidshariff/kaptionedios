import Foundation
import CryptoKit
import Combine
import UIKit
import RevenueCat
import StoreKit

/// Manages subscription status and enforces video creation limits with encrypted storage
/// Now integrated with RevenueCat for real payment processing
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var currentStatus: SubscriptionStatus = SubscriptionStatus()
    @Published var isLoading: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let subscriptionKey = "encrypted_subscription_data"
    private let deviceKey = "device_identifier"
    
    private init() {
        loadSubscriptionStatus()
        
        // Sync with RevenueCat on init
        Task {
            await syncWithRevenueCat()
        }
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
            RevenueCatManager.shared.presentPaywall()
            print("[SubscriptionManager] Showing RevenueCat paywall")
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
        
        // Clear StoreKit 2 transactions (for testing)
        await clearStoreKitTransactions()
        
        // Create a fresh anonymous user with new UUID
        do {
            let newUserID = UUID().uuidString
            let (customerInfo, created) = try await Purchases.shared.logIn(newUserID)
            print("[SubscriptionManager] 🔄 Fresh anonymous RevenueCat user created: \(newUserID)")
        } catch {
            print("[SubscriptionManager] ⚠️ Error creating new anonymous user: \(error)")
            // This is not critical - RevenueCat will work with default anonymous user
        }
    }
    
    // MARK: - RevenueCat Integration
    
    /// Sync local subscription status with RevenueCat
    @MainActor
    func syncWithRevenueCat() async {
        print("[SubscriptionManager] 🔄 Starting sync with RevenueCat...")
        await RevenueCatManager.shared.loadCustomerInfo()
        
        let revenueCatTier = RevenueCatManager.shared.currentSubscriptionTier
        let revenueCatExpiry = RevenueCatManager.shared.subscriptionExpiryDate
        
        print("[SubscriptionManager] 📊 RevenueCat tier: \(revenueCatTier.displayName)")
        print("[SubscriptionManager] 📊 Local tier before sync: \(currentStatus.tier.displayName)")
        
        // Update local status to match RevenueCat
        let newStatus = SubscriptionStatus(
            tier: revenueCatTier,
            videosCreated: currentStatus.videosCreated, // Keep local video count
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
        let success = await RevenueCatManager.shared.restorePurchases()
        if success {
            await syncWithRevenueCat()
        }
        return success
    }
    
    // MARK: - Private Methods
    
    private func loadSubscriptionStatus() {
        guard let encryptedData = userDefaults.data(forKey: subscriptionKey) else {
            print("[SubscriptionManager] No subscription data found, using default free tier")
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
    
    private func saveSubscriptionStatus(_ status: SubscriptionStatus) {
        do {
            let data = try JSONEncoder().encode(status)
            let encryptedData = try encryptData(data)
            userDefaults.set(encryptedData, forKey: subscriptionKey)
            print("[SubscriptionManager] Subscription status saved successfully")
        } catch {
            print("[SubscriptionManager] Failed to save subscription status: \(error)")
        }
    }
    
    // MARK: - Encryption Methods
    
    private func getDeviceKey() -> String {
        if let existingKey = userDefaults.string(forKey: deviceKey) {
            return existingKey
        }
        
        // Generate a unique device identifier
        let deviceKey = UUID().uuidString + Bundle.main.bundleIdentifier! + UIDevice.current.identifierForVendor!.uuidString
        let deviceKeyData = deviceKey.data(using: .utf8)!
        let hashedKey = SHA256.hash(data: deviceKeyData)
        let keyString = hashedKey.compactMap { String(format: "%02x", $0) }.joined()
        
        userDefaults.set(keyString, forKey: deviceKey)
        return keyString
    }
    
    private func encryptData(_ data: Data) throws -> Data {
        let key = getDeviceKey()
        let keyData = key.data(using: .utf8)!
        let keyHash = SHA256.hash(data: keyData)
        let symmetricKey = SymmetricKey(data: keyHash)
        
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        return sealedBox.combined!
    }
    
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
