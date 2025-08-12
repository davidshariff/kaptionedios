import Foundation

/// RevenueCat configuration constants
struct RevenueCatConfig {
    
    // MARK: - API Keys
    
    /// RevenueCat API Keys (replace with your actual keys from RevenueCat dashboard)
    struct APIKeys {
        #if DEBUG
        static let debug = "appl_sArGgNOqlzovQItCyGBRZobhFNC"
        #else
        static let release = "appl_YOUR_RELEASE_API_KEY_HERE"
        #endif
        
        static var current: String {
            #if DEBUG
            return debug
            #else
            return release
            #endif
        }
    }
    
    // MARK: - Product Identifiers
    
    /// Product IDs that match your App Store Connect configuration
    struct ProductIDs {
        // Pro tier products
        static let proMonthly = "kaptioned_pro_monthly"
        static let proYearly = "kaptioned_pro_yearly"
        
        // Unlimited tier products
        static let unlimitedMonthly = "kaptioned_unlimited_monthly"
        static let unlimitedYearly = "kaptioned_unlimited_yearly"
        
        /// All product IDs for easy reference
        static let allProducts = [
            proMonthly,
            proYearly,
            unlimitedMonthly,
            unlimitedYearly
        ]
    }
    
    // MARK: - Entitlement IDs
    
    /// Entitlement identifiers from RevenueCat dashboard
    struct Entitlements {
        static let proAccess = "pro_access"
        static let unlimitedAccess = "unlimited_access"
    }
    
    // MARK: - Offering IDs
    
    /// Offering identifiers from RevenueCat dashboard
    struct Offerings {
        static let main = "main_offering"
        static let pro = "pro_offering"
        static let unlimited = "unlimited_offering"
    }
    
    // MARK: - User Properties
    
    /// Custom user properties for analytics
    struct UserProperties {
        static let appVersion = "app_version"
        static let firstLaunch = "first_launch_date"
        static let videosCreated = "videos_created_count"
        static let lastActiveDate = "last_active_date"
    }
    
    // MARK: - Paywall Configuration
    
    /// RevenueCat Paywall configuration
    struct Paywall {
        /// Default paywall offering identifier
        static let defaultOffering = "main_offering"
        
        /// Paywall display modes
        enum DisplayMode {
            case fullScreen
            case card
            case condensedCard
        }
        
        /// Default display mode for paywalls
        static let defaultDisplayMode: DisplayMode = .fullScreen
    }
}

// MARK: - Setup Instructions

/*
 
 📋 REVENUECAT SETUP CHECKLIST:
 
 1. 📱 APP STORE CONNECT SETUP:
    - Create your in-app purchase products with the IDs above
    - ⚠️ IMPORTANT: Set up subscription groups correctly for upgrades
      * Put ALL pro and unlimited products in the SAME subscription group
      * Set subscription levels: Pro = Level 1, Unlimited = Level 2
      * This enables automatic upgrade/downgrade with proration
    - Configure pricing and availability
    - Submit for review
 
 2. 🔧 REVENUECAT DASHBOARD SETUP:
    - Create a new app in RevenueCat dashboard
    - Add your App Store Connect integration
    - Create entitlements: "premium_access" and "unlimited_access"
    - Create offerings and attach products
    - Copy your API keys and replace the placeholders above
 
 3. 🛠 XCODE PROJECT SETUP:
    - Add RevenueCat SDK via Swift Package Manager: https://github.com/RevenueCat/purchases-ios
    - Enable "In-App Purchase" capability in your app target
    - Add StoreKit framework if needed
 
 4. ⚙️ CONFIGURATION:
    - Replace "YOUR_DEBUG_API_KEY_HERE" and "YOUR_RELEASE_API_KEY_HERE" with your actual keys
    - Update product IDs to match your App Store Connect products
    - Verify entitlement IDs match your RevenueCat dashboard
 
 5. 🧪 TESTING:
    - Use sandbox Apple ID for testing
    - Test purchases in simulator/device
    - Verify entitlements are granted correctly
    - Test restore purchases functionality
 
 6. 🚀 PRODUCTION:
    - Switch to production API key
    - Test with real Apple ID (but don't publish yet)
    - Submit app for App Store review
 
 */
