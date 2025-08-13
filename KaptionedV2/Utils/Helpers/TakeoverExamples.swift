import Foundation
import SwiftUI

/// Example takeover configurations for testing and reference
struct TakeoverExamples {
    
    // MARK: - Upgrade Takeover
    
    static let upgradeTakeover = TakeoverConfig(
        isEnabled: true,
        type: .upgrade,
        title: "Upgrade to Premium",
        message: "Unlock unlimited video processing, advanced styling options, and priority support with our premium subscription.",
        actionButtonText: "Upgrade Now",
        cancelButtonText: "Maybe Later",
        actionURL: nil,
        backgroundColor: "#8B5CF6", // Purple
        textColor: "#FFFFFF",
        buttonColor: "#7C3AED",
        icon: "crown.fill",
        dismissible: true,
        forceUpgrade: false
    )
    
    // MARK: - Maintenance Takeover
    
    static let maintenanceTakeover = TakeoverConfig(
        isEnabled: true,
        type: .maintenance,
        title: "Scheduled Maintenance",
        message: "We're performing scheduled maintenance to improve your experience. This should take about 30 minutes.",
        actionButtonText: "Check Status",
        cancelButtonText: "OK",
        actionURL: "https://status.kaptioned.com",
        backgroundColor: "#F59E0B", // Orange
        textColor: "#FFFFFF",
        buttonColor: "#D97706",
        icon: "wrench.and.screwdriver.fill",
        dismissible: true,
        forceUpgrade: false
    )
    
    // MARK: - URL Test Takeover
    
    static let urlTestTakeover = TakeoverConfig(
        isEnabled: true,
        type: .announcement,
        title: "Visit Our Website",
        message: "Check out our website for tutorials, tips, and the latest updates!",
        actionButtonText: "Visit Website",
        cancelButtonText: "Maybe Later",
        actionURL: "https://kaptioned.com",
        backgroundColor: "#3B82F6", // Blue
        textColor: "#FFFFFF",
        buttonColor: "#2563EB",
        icon: "globe",
        dismissible: true,
        forceUpgrade: false
    )
    
    // MARK: - Announcement Takeover
    
    static let announcementTakeover = TakeoverConfig(
        isEnabled: true,
        type: .announcement,
        title: "New Features Available!",
        message: "We've added karaoke subtitles, advanced text styling, and improved video processing. Check out what's new!",
        actionButtonText: "Learn More",
        cancelButtonText: "Dismiss",
        actionURL: "https://kaptioned.com/whats-new",
        backgroundColor: "#10B981", // Green
        textColor: "#FFFFFF",
        buttonColor: "#059669",
        icon: "megaphone.fill",
        dismissible: true,
        forceUpgrade: false
    )
    
    // MARK: - Error Takeover
    
    static let errorTakeover = TakeoverConfig(
        isEnabled: true,
        type: .error,
        title: "Service Temporarily Unavailable",
        message: "We're experiencing technical difficulties. Our team is working to resolve this as quickly as possible.",
        actionButtonText: "Try Again",
        cancelButtonText: "OK",
        actionURL: nil,
        backgroundColor: "#EF4444", // Red
        textColor: "#FFFFFF",
        buttonColor: "#DC2626",
        icon: "exclamationmark.triangle.fill",
        dismissible: true,
        forceUpgrade: false
    )
    
    // MARK: - Force Upgrade Takeover
    
    static let forceUpgradeTakeover = TakeoverConfig(
        isEnabled: true,
        type: .upgrade,
        title: "Update Required",
        message: "A new version of Kaptioned is required to continue. Please update to the latest version.",
        actionButtonText: "Update Now",
        cancelButtonText: "Later",
        actionURL: "itms://", // Alternative native scheme
        backgroundColor: "#DC2626", // Red
        textColor: "#FFFFFF",
        buttonColor: "#B91C1C",
        icon: "exclamationmark.triangle.fill",
        dismissible: false,
        forceUpgrade: true
    )
    
    // MARK: - Native Navigation Takeover
    
    static let nativeNavigationTakeover = TakeoverConfig(
        isEnabled: true,
        type: .upgrade,
        title: "Premium Features",
        message: "Unlock advanced features and unlimited video processing with our premium subscription.",
        actionButtonText: "View Subscription",
        cancelButtonText: "Maybe Later",
        actionURL: "kaptioned://subscription",
        backgroundColor: "#8B5CF6", // Purple
        textColor: "#FFFFFF",
        buttonColor: "#7C3AED",
        icon: "crown.fill",
        dismissible: true,
        forceUpgrade: false
    )
    
    // MARK: - Settings Navigation Takeover
    
    static let settingsNavigationTakeover = TakeoverConfig(
        isEnabled: true,
        type: .message,
        title: "App Settings",
        message: "Customize your app experience and manage your preferences.",
        actionButtonText: "Open Settings",
        cancelButtonText: "Not Now",
        actionURL: "kaptioned://settings",
        backgroundColor: "#3B82F6", // Blue
        textColor: "#FFFFFF",
        buttonColor: "#2563EB",
        icon: "gearshape.fill",
        dismissible: true,
        forceUpgrade: false
    )
    
    // MARK: - Simple Message Takeover
    
    static let messageTakeover = TakeoverConfig(
        isEnabled: true,
        type: .message,
        title: "Welcome to Kaptioned!",
        message: "Thank you for downloading our app. We hope you enjoy creating beautiful subtitled videos!",
        actionButtonText: "Get Started",
        cancelButtonText: "Skip",
        actionURL: nil,
        backgroundColor: "#3B82F6", // Blue
        textColor: "#FFFFFF",
        buttonColor: "#2563EB",
        icon: "message.circle.fill",
        dismissible: true,
        forceUpgrade: false
    )
    
    // MARK: - Custom Styled Takeover
    
    static let customStyledTakeover = TakeoverConfig(
        isEnabled: true,
        type: .announcement,
        title: "🎉 Special Offer!",
        message: "Get 50% off your first month of premium! Limited time offer for new subscribers.",
        actionButtonText: "Claim Offer",
        cancelButtonText: "No Thanks",
        actionURL: nil,
        backgroundColor: "#FF6B6B", // Custom pink
        textColor: "#FFFFFF",
        buttonColor: "#FF5252",
        icon: "gift.fill",
        dismissible: true,
        forceUpgrade: false
    )
}

// MARK: - Server Configuration Examples

/// Example server configuration JSON for reference
struct ServerConfigExamples {
    
    /// Example JSON configuration for enabling an upgrade takeover
    static let upgradeConfigJSON = """
    {
        "success": true,
        "config": {
            "api": {
                "baseURL": "https://premium-tetra-together.ngrok-free.app",
                "timeout": 30.0,
                "retryAttempts": 3
            },
            "transcription": {
                "endpoint": "/transcribe",
                "defaultLanguage": "en",
                "maxWordsPerLine": 1,
                "supportedLanguages": ["en", "es", "fr", "de", "it", "pt", "ru", "zh", "ja", "ko"]
            },
            "features": {
                "enableKaraoke": true,
                "enableAdvancedStyling": true,
                "maxVideoDuration": 300.0,
                "supportedVideoFormats": ["mp4", "mov", "avi", "mkv"]
            },
            "revenueCat": {
                "apiKey": "appl_sArGgNOqlzovQItCyGBRZobhFNC",
                "paywallOffering": "1_tier_pro",
                "useCustomPaywall": true,
                "enableAnalytics": true,
                "allowUpgrades": false
            },
            "paywall": {
                "theme": "dark"
            },
            "takeover": {
                "isEnabled": true,
                "type": "upgrade",
                "title": "Upgrade to Premium",
                "message": "Unlock unlimited video processing and advanced features with our premium subscription.",
                "actionButtonText": "Upgrade Now",
                "cancelButtonText": "Maybe Later",
                "actionURL": null,
                "backgroundColor": "#8B5CF6",
                "textColor": "#FFFFFF",
                "buttonColor": "#7C3AED",
                "icon": "crown.fill",
                "dismissible": true,
                "forceUpgrade": false
            }
        },
        "message": "Configuration updated successfully",
        "timestamp": "2024-01-15T10:30:00Z"
    }
    """
    
    /// Example JSON configuration for maintenance mode
    static let maintenanceConfigJSON = """
    {
        "success": true,
        "config": {
            "takeover": {
                "isEnabled": true,
                "type": "maintenance",
                "title": "Scheduled Maintenance",
                "message": "We're performing scheduled maintenance. This should take about 30 minutes.",
                "actionButtonText": "Check Status",
                "cancelButtonText": "OK",
                "actionURL": "https://status.kaptioned.com",
                "backgroundColor": "#F59E0B",
                "textColor": "#FFFFFF",
                "buttonColor": "#D97706",
                "icon": "wrench.and.screwdriver.fill",
                "dismissible": true,
                "forceUpgrade": false
            }
        }
    }
    """
    
    /// Example JSON configuration to disable takeover
    static let disableTakeoverJSON = """
    {
        "success": true,
        "config": {
            "takeover": {
                "isEnabled": false,
                "type": "message",
                "title": "",
                "message": "",
                "actionButtonText": "OK",
                "cancelButtonText": "Cancel",
                "actionURL": null,
                "backgroundColor": null,
                "textColor": null,
                "buttonColor": null,
                "icon": null,
                "dismissible": true,
                "forceUpgrade": false
            }
        }
    }
    """
}
