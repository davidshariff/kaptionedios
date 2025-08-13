import Foundation

// MARK: - Subscription Models

/// Represents different subscription tiers
enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case unlimited = "unlimited"
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .pro:
            return "Pro"
        case .unlimited:
            return "Unlimited"
        }
    }
    
    var maxVideos: Int {
        let config = ConfigurationManager.shared.getSubscriptionConfig()
        switch self {
        case .free:
            return config.freeVideos
        case .pro:
            return config.proVideos
        case .unlimited:
            return config.unlimitedVideos
        }
    }
    
    var canCreateNewVideo: Bool {
        return true // All tiers can create videos, limits handled in SubscriptionStatus
    }
}

/// Represents the current subscription status
struct SubscriptionStatus: Codable {
    let tier: SubscriptionTier
    let videosCreated: Int
    let subscriptionExpiryDate: Date?
    let isActive: Bool
    
    var canCreateNewVideo: Bool {
        if tier == .unlimited {
            return true
        }
        
        // Both free and pro tiers check against their maxVideos limit
        return videosCreated < tier.maxVideos
    }
    
    var remainingVideos: Int {
        if tier == .unlimited {
            return Int.max
        }
        return max(0, tier.maxVideos - videosCreated)
    }
    
    init(tier: SubscriptionTier = .free, videosCreated: Int = 0, subscriptionExpiryDate: Date? = nil, isActive: Bool = true) {
        self.tier = tier
        self.videosCreated = videosCreated
        self.subscriptionExpiryDate = subscriptionExpiryDate
        self.isActive = isActive
    }
}
