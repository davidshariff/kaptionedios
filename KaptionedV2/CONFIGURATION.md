# Configuration System

This document explains how the configuration system works in KaptionedV2.

## Overview

The configuration system allows the app to load remote configuration settings from a server and merge them with default values. This enables dynamic configuration updates without requiring app updates.

## Architecture

### Components

1. **ConfigurationManager.swift** - Contains all configuration models and manages loading, caching, and merging of configurations
2. **ConfigurationManager+Extensions.swift** - Provides convenient access methods

### Configuration Structure

```swift
struct AppConfig {
    var api: APIConfig           // API endpoints and settings
    var transcription: TranscriptionConfig  // Transcription service settings
    var features: FeatureConfig  // Feature flags and limits
    var revenueCat: RevenueCatConfig  // RevenueCat paywall and analytics settings
    var paywall: PaywallConfig   // Paywall theme and appearance settings
}
```

## Usage

### Basic Usage

```swift
// Get the shared configuration manager
let configManager = ConfigurationManager.shared

// Access configuration values
let transcriptionURL = configManager.getTranscriptionURL()
let defaultLanguage = configManager.getDefaultLanguage()
let isKaraokeEnabled = configManager.isKaraokeEnabled()

// RevenueCat configuration
let paywallOffering = configManager.getPaywallOffering()
let useCustomPaywall = configManager.shouldUseCustomPaywall()

// Paywall configuration
let paywallTheme = configManager.getPaywallTheme()
let paywallAccentColor = configManager.getPaywallAccentColor()
```

### Using Convenience Extensions

```swift
// Using the global AppConfig variable
let url = AppConfig.transcriptionURL
let language = AppConfig.defaultLanguage
let karaokeEnabled = AppConfig.karaokeEnabled

// RevenueCat configuration
let offering = AppConfig.paywallOffering
let customPaywall = AppConfig.useCustomPaywall

// Paywall configuration
let theme = AppConfig.paywallTheme
let accentColor = AppConfig.paywallAccentColor
```

### In Views

```swift
struct MyView: View {
    @ObservedObject var configManager = ConfigurationManager.shared
    
    var body: some View {
        VStack {
            if configManager.isLoading {
                ProgressView("Loading configuration...")
            } else {
                Text("API URL: \(configManager.currentConfig.api.baseURL)")
            }
        }
    }
}
```

## Configuration Loading

### Automatic Loading

The configuration is automatically loaded when the app starts in `VideoEditorSwiftUIApp.swift`:

```swift
.onAppear {
    configManager.loadRemoteConfig()
}
```

### Manual Loading

You can manually trigger configuration loading:

```swift
ConfigurationManager.shared.loadRemoteConfig()
```

## Configuration Endpoint

The app expects a configuration endpoint at:
```
https://premium-tetra-together.ngrok-free.app/configs
```

### Expected Response Format

```json
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
            "supportedLanguages": ["en", "es", "fr"]
        },
        "features": {
            "enableKaraoke": true,
            "enableAdvancedStyling": true,
            "maxVideoDuration": 300.0,
            "supportedVideoFormats": ["mp4", "mov"]
        }
    },
    "message": "Configuration loaded successfully",
    "timestamp": "2024-01-01T00:00:00Z"
}
```

## Caching

The configuration is automatically cached in UserDefaults and will be loaded from cache on app startup. If the remote configuration fails to load, the app will use the cached configuration or fall back to defaults.

## Error Handling

The configuration manager handles various error scenarios:

- Network failures
- Invalid JSON responses
- Missing configuration data
- Cache corruption

In all cases, the app will fall back to default configuration values to ensure it continues to function.

## Updating TranscriptionHelper

The `TranscriptionHelper` has been updated to use the configuration system instead of hardcoded values:

```swift
// Before (hardcoded)
let url = URL(string: "https://premium-tetra-together.ngrok-free.app/transcribe")!
let language = "en"
let maxWordsPerLine = 1

// After (configuration-based)
let url = configManager.getTranscriptionURL()
let language = configManager.getDefaultLanguage()
let maxWordsPerLine = configManager.getDefaultMaxWordsPerLine()
```

## Adding New Configuration Options

To add new configuration options:

1. Add the new property to the appropriate config struct in `ConfigurationManager.swift`
2. Add a default value in the `default` static property
3. Add a getter method in `ConfigurationManager.swift`
4. Add a convenience property in `ConfigurationManager+Extensions.swift`
5. Update the merging logic in `mergeConfigs` method if needed

## Configuration Options

### RevenueCat Configuration

The `RevenueCatConfig` struct controls RevenueCat paywall and analytics settings:

```swift
struct RevenueCatConfig {
    let paywallOffering: String    // Offering ID to use for paywall (default: "1_tier_pro")
    let useCustomPaywall: Bool     // Whether to use custom paywall (default: true)
    let enableAnalytics: Bool      // Whether to enable RevenueCat analytics (default: true)
}
```

**Usage:**
```swift
let configManager = ConfigurationManager.shared
let offering = configManager.getPaywallOffering() // Returns "1_tier_pro" by default
let useCustom = configManager.shouldUseCustomPaywall()
```

### Paywall Configuration

The `PaywallConfig` struct controls RevenueCat paywall appearance using basic theming:

```swift
struct PaywallConfig {
    let theme: String              // Theme setting: "light", "dark", "automatic" (default: "light")
}
```

**Usage:**
```swift
let configManager = ConfigurationManager.shared
let theme = configManager.getPaywallTheme() // Returns "light" by default
```

**Theme Values:**
- `"light"` - Forces light theme
- `"dark"` - Forces dark theme  
- `"automatic"` - Uses system setting (default for unknown values)

The paywall theming applies basic background color changes to the PaywallViewController.
