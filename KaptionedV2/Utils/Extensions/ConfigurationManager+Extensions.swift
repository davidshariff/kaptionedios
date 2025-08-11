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
}

