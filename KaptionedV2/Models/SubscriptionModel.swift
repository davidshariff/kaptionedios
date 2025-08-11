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
        switch self {
        case .free:
            return 1
        case .pro:
            return 10
        case .unlimited:
            return Int.max
        }
    }
    
    var canCreateNewVideo: Bool {
        return self != .free // Free tier has special handling
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
        
        if tier == .pro {
            return videosCreated < tier.maxVideos
        }
        
        // Free tier: only allow 1 video
        return videosCreated < 1
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
