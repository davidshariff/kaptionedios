import Foundation
import CryptoKit
import Combine
import UIKit

/// Manages subscription status and enforces video creation limits with encrypted storage
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var currentStatus: SubscriptionStatus = SubscriptionStatus()
    @Published var isLoading: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let subscriptionKey = "encrypted_subscription_data"
    private let deviceKey = "device_identifier"
    
    private init() {
        loadSubscriptionStatus()
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
    
    /// Upgrades the user to a new subscription tier
    func upgradeToTier(_ tier: SubscriptionTier) {
        let newStatus = SubscriptionStatus(
            tier: tier,
            videosCreated: currentStatus.videosCreated,
            subscriptionExpiryDate: tier == .free ? nil : Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days for paid tiers
            isActive: true
        )
        currentStatus = newStatus
        saveSubscriptionStatus(newStatus)
        
        print("[SubscriptionManager] Upgraded to \(tier.displayName) tier")
    }
    
    /// Resets subscription status (for testing purposes)
    func resetSubscription() {
        let newStatus = SubscriptionStatus()
        currentStatus = newStatus
        saveSubscriptionStatus(newStatus)
        
        print("[SubscriptionManager] Subscription reset to free tier")
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
                let premiumMax = SubscriptionTier.premium.maxVideos
                return "You've used your free video. Upgrade to Premium for \(premiumMax) videos or Unlimited for unlimited videos!"
            } else {
                return "You have 1 free video remaining."
            }
        case .premium:
            if status.remainingVideos == 0 {
                if let expiryDate = status.subscriptionExpiryDate {
                    let daysUntilRenewal = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
                    if daysUntilRenewal > 0 {
                        return "You've reached your Premium limit of \(status.tier.maxVideos) videos. You'll be able to create videos again in \(daysUntilRenewal) day\(daysUntilRenewal == 1 ? "" : "s")."
                    } else {
                        return "You've reached your Premium limit of \(status.tier.maxVideos) videos. Your subscription will renew soon!"
                    }
                } else {
                    return "You've reached your Premium limit of \(status.tier.maxVideos) videos. Upgrade to Unlimited for unlimited videos!"
                }
            } else {
                return "You have \(status.remainingVideos) video\(status.remainingVideos == 1 ? "" : "s") remaining in your Premium plan."
            }
        case .unlimited:
            return "Unlimited videos with your Unlimited subscription!"
        }
    }
    
    /// Gets the upgrade message for the current tier
    func getUpgradeMessage() -> String {
        switch currentStatus.tier {
        case .free:
            let premiumMax = SubscriptionTier.premium.maxVideos
            return "Upgrade to Premium for \(premiumMax) videos per month or Unlimited for unlimited videos!"
        case .premium:
            return "Upgrade to Unlimited for unlimited videos and no monthly limits!"
        case .unlimited:
            return "You already have unlimited access to all features!"
        }
    }
}
