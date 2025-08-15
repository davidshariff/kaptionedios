import Foundation

// MARK: - Configuration Manager Extensions

extension ConfigurationManager {
    
    /// Convenience method to get the full transcription URL
    var transcriptionURL: URL {
        return getTranscriptionURL()
    }
    
    /// Convenience method to get the default language
    var defaultLanguage: String {
        return getDefaultLanguage()
    }
    
    /// Convenience method to get the default max words per line
    var defaultMaxWordsPerLine: Int {
        return getDefaultMaxWordsPerLine()
    }
    
    /// Convenience method to get supported languages
    var supportedLanguages: [String] {
        return getSupportedLanguages()
    }
    
    /// Convenience method to check if karaoke is enabled
    var karaokeEnabled: Bool {
        return isKaraokeEnabled()
    }
    
    /// Convenience method to check if advanced styling is enabled
    var advancedStylingEnabled: Bool {
        return isAdvancedStylingEnabled()
    }
    
    /// Convenience method to get max video duration
    var maxVideoDuration: TimeInterval {
        return getMaxVideoDuration()
    }
    
    /// Convenience method to get supported video formats
    var supportedVideoFormats: [String] {
        return getSupportedVideoFormats()
    }
    
    /// Convenience method to check if text layout optimization is enabled
    var textLayoutOptimizationEnabled: Bool {
        return isTextLayoutOptimizationEnabled()
    }
    
    /// Convenience method to check if crown should be shown in empty state
    var showCrownInEmptyState: Bool {
        return shouldShowCrownInEmptyState()
    }
    
    // MARK: - RevenueCat Configuration Convenience Properties
    
    /// Convenience method to get the configured paywall offering
    var paywallOffering: String {
        return getPaywallOffering()
    }
    
    /// Convenience method to check if custom paywall should be used
    var useCustomPaywall: Bool {
        return shouldUseCustomPaywall()
    }
    
    /// Convenience method to check if RevenueCat analytics should be enabled
    var revenueCatAnalyticsEnabled: Bool {
        return isRevenueCatAnalyticsEnabled()
    }
    
    // MARK: - Paywall Configuration Convenience Properties
    
    /// Convenience method to get the configured paywall theme
    var paywallTheme: String {
        return getPaywallTheme()
    }
}

