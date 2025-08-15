import Foundation
import Combine

// MARK: - App Configuration Models

/// Main configuration structure for the app
struct AppConfig: Codable {
    var api: APIConfig
    var transcription: TranscriptionConfig
    var features: FeatureConfig
    var revenueCat: RevenueCatSettings
    var paywall: PaywallConfig
    var takeover: TakeoverConfig
    var subscription: SubscriptionConfig
    
    // Custom decoding to handle missing fields in old configs
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        api = try container.decode(APIConfig.self, forKey: .api)
        transcription = try container.decode(TranscriptionConfig.self, forKey: .transcription)
        features = try container.decode(FeatureConfig.self, forKey: .features)
        
        // Handle missing fields gracefully with defaults
        revenueCat = try container.decodeIfPresent(RevenueCatSettings.self, forKey: .revenueCat) ?? RevenueCatSettings.default
        paywall = try container.decodeIfPresent(PaywallConfig.self, forKey: .paywall) ?? PaywallConfig.default
        takeover = try container.decodeIfPresent(TakeoverConfig.self, forKey: .takeover) ?? TakeoverConfig.default
        subscription = try container.decodeIfPresent(SubscriptionConfig.self, forKey: .subscription) ?? SubscriptionConfig.default
    }
    
    // Standard initializer
    init(api: APIConfig, transcription: TranscriptionConfig, features: FeatureConfig, revenueCat: RevenueCatSettings, paywall: PaywallConfig, takeover: TakeoverConfig, subscription: SubscriptionConfig) {
        self.api = api
        self.transcription = transcription
        self.features = features
        self.revenueCat = revenueCat
        self.paywall = paywall
        self.takeover = takeover
        self.subscription = subscription
    }
    
    static let `default` = AppConfig(
        api: APIConfig.default,
        transcription: TranscriptionConfig.default,
        features: FeatureConfig.default,
        revenueCat: RevenueCatSettings.default,
        paywall: PaywallConfig.default,
        takeover: TakeoverConfig.default,
        subscription: SubscriptionConfig.default
    )
}

/// API-related configuration
struct APIConfig: Codable {
    let baseURL: String
    let timeout: TimeInterval
    let retryAttempts: Int
    
    static let `default` = APIConfig(
        baseURL: "https://premium-tetra-together.ngrok-free.app",
        timeout: 30.0,
        retryAttempts: 3
    )
}

/// Transcription service configuration
struct TranscriptionConfig: Codable {
    let endpoint: String
    let defaultLanguage: String
    let maxWordsPerLine: Int
    let supportedLanguages: [String]
    let defaultPreset: String
    let presets: [RemoteSubtitleStyle]?
    let excludePresets: [String]?
    
    // Custom decoding to handle missing fields in old cached configs
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        endpoint = try container.decode(String.self, forKey: .endpoint)
        defaultLanguage = try container.decode(String.self, forKey: .defaultLanguage)
        maxWordsPerLine = try container.decode(Int.self, forKey: .maxWordsPerLine)
        supportedLanguages = try container.decode([String].self, forKey: .supportedLanguages)
        
        // Handle missing fields gracefully with defaults
        defaultPreset = try container.decodeIfPresent(String.self, forKey: .defaultPreset) ?? "Modern White"
        presets = try container.decodeIfPresent([RemoteSubtitleStyle].self, forKey: .presets)
        excludePresets = try container.decodeIfPresent([String].self, forKey: .excludePresets)
    }
    
    // Standard initializer
    init(endpoint: String, defaultLanguage: String, maxWordsPerLine: Int, supportedLanguages: [String], defaultPreset: String, presets: [RemoteSubtitleStyle]?, excludePresets: [String]?) {
        self.endpoint = endpoint
        self.defaultLanguage = defaultLanguage
        self.maxWordsPerLine = maxWordsPerLine
        self.supportedLanguages = supportedLanguages
        self.defaultPreset = defaultPreset
        self.presets = presets
        self.excludePresets = excludePresets
    }
    
    static let `default` = TranscriptionConfig(
        endpoint: "/transcribe",
        defaultLanguage: "en",
        maxWordsPerLine: 1,
        supportedLanguages: ["en", "es", "fr", "de", "it", "pt", "ru", "zh", "ja", "ko"],
        defaultPreset: "Modern White",
        presets: nil, // Will merge with built-in presets
        excludePresets: nil // No presets excluded by default
    )
}

/// Feature flags and settings
struct FeatureConfig: Codable {
    let enableKaraoke: Bool
    let enableAdvancedStyling: Bool
    let maxVideoDuration: TimeInterval
    let supportedVideoFormats: [String]
    let enableTextLayoutOptimization: Bool
    let showCrownInEmptyState: Bool
    
    // Custom decoding to handle missing fields in old configs
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        enableKaraoke = try container.decode(Bool.self, forKey: .enableKaraoke)
        enableAdvancedStyling = try container.decode(Bool.self, forKey: .enableAdvancedStyling)
        maxVideoDuration = try container.decode(TimeInterval.self, forKey: .maxVideoDuration)
        supportedVideoFormats = try container.decode([String].self, forKey: .supportedVideoFormats)
        
        // Handle missing fields gracefully with defaults
        enableTextLayoutOptimization = try container.decodeIfPresent(Bool.self, forKey: .enableTextLayoutOptimization) ?? true
        showCrownInEmptyState = try container.decodeIfPresent(Bool.self, forKey: .showCrownInEmptyState) ?? true
    }
    
    // Standard initializer
    init(enableKaraoke: Bool, enableAdvancedStyling: Bool, maxVideoDuration: TimeInterval, supportedVideoFormats: [String], enableTextLayoutOptimization: Bool, showCrownInEmptyState: Bool) {
        self.enableKaraoke = enableKaraoke
        self.enableAdvancedStyling = enableAdvancedStyling
        self.maxVideoDuration = maxVideoDuration
        self.supportedVideoFormats = supportedVideoFormats
        self.enableTextLayoutOptimization = enableTextLayoutOptimization
        self.showCrownInEmptyState = showCrownInEmptyState
    }
    
    static let `default` = FeatureConfig(
        enableKaraoke: true,
        enableAdvancedStyling: true,
        maxVideoDuration: 300.0, // 5 minutes
        supportedVideoFormats: ["mp4", "mov", "avi", "mkv"],
        enableTextLayoutOptimization: true,
        showCrownInEmptyState: true
    )
}

/// RevenueCat configuration settings
struct RevenueCatSettings: Codable {
    let apiKey: String
    let paywallOffering: String
    let useCustomPaywall: Bool
    let enableAnalytics: Bool
    let allowUpgrades: Bool
    
    static let `default` = RevenueCatSettings(
        apiKey: "appl_sArGgNOqlzovQItCyGBRZobhFNC", // Default/fallback key
        paywallOffering: "1_tier_pro",
        useCustomPaywall: true,
        enableAnalytics: true,
        allowUpgrades: false
    )
}

/// Paywall theme and appearance configuration
struct PaywallConfig: Codable {
    let theme: String
    
    // TODO: i don't think this works because we don't pass it to RevenueCatManager correctly
    static let `default` = PaywallConfig(
        theme: "dark"
    )
}

/// Takeover configuration for full-screen app takeovers
public struct TakeoverConfig: Codable {
    let isEnabled: Bool
    let type: TakeoverType
    let title: String
    let message: String
    let actionButtonText: String
    let cancelButtonText: String
    let actionURL: String?
    let backgroundColor: String?
    let textColor: String?
    let buttonColor: String?
    let icon: String?
    let dismissible: Bool
    let forceUpgrade: Bool
    
    static let `default` = TakeoverConfig(
        isEnabled: false,
        type: .message,
        title: "",
        message: "",
        actionButtonText: "OK",
        cancelButtonText: "Cancel",
        actionURL: nil,
        backgroundColor: nil,
        textColor: nil,
        buttonColor: nil,
        icon: nil,
        dismissible: true,
        forceUpgrade: false
    )
}

/// Types of takeover screens
public enum TakeoverType: String, Codable, CaseIterable {
    case message = "message"
    case upgrade = "upgrade"
    case maintenance = "maintenance"
    case announcement = "announcement"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .message: return "Message"
        case .upgrade: return "Upgrade Required"
        case .maintenance: return "Maintenance"
        case .announcement: return "Announcement"
        case .error: return "Error"
        }
    }
    
    var defaultIcon: String {
        switch self {
        case .message: return "message.circle.fill"
        case .upgrade: return "crown.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .announcement: return "megaphone.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var defaultBackgroundColor: String {
        switch self {
        case .message: return "blue"
        case .upgrade: return "purple"
        case .maintenance: return "orange"
        case .announcement: return "green"
        case .error: return "red"
        }
    }
}

/// Remote subtitle style configuration
struct RemoteSubtitleStyle: Codable {
    let name: String
    let fontSize: Double
    let bgColor: String // Hex color
    let fontColor: String // Hex color
    let strokeColor: String // Hex color
    let strokeWidth: Double
    let backgroundPadding: Double
    let cornerRadius: Double
    let shadowColor: String // Hex color
    let shadowRadius: Double
    let shadowX: Double
    let shadowY: Double
    let shadowOpacity: Double
    let isKaraokePreset: Bool
    let karaokeConfig: RemoteKaraokeConfig?
}

/// Remote karaoke configuration
struct RemoteKaraokeConfig: Codable {
    let type: String // "word", "wordbg", "wordAndScale"
    let highlightColor: String // Hex color
    let wordBGColor: String // Hex color
    let previewWordSpacing: Double
    let exportWordSpacing: Double
}

/// Subscription limits configuration
struct SubscriptionConfig: Codable {
    let freeVideos: Int
    let proVideos: Int
    let unlimitedVideos: Int // Should always be Int.max
    
    static let `default` = SubscriptionConfig(
        freeVideos: 1,
        proVideos: 10,
        unlimitedVideos: Int.max
    )
}

// MARK: - API Response Models

/// Response from the config endpoint
struct ConfigResponse: Codable {
    let success: Bool
    let config: AppConfig?
    let message: String?
    let timestamp: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case config
        case message
        case timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        config = try container.decodeIfPresent(AppConfig.self, forKey: .config)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
    }
}

// MARK: - Configuration Manager

/// Manages app configuration including remote loading and local caching
class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    
    @Published var currentConfig: AppConfig = AppConfig.default
    @Published var isLoading: Bool = false
    @Published var isReady: Bool = true // Starts as ready with default config
    @Published var lastUpdateTime: Date?
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let configKey = "app_config_cache"
    private let lastUpdateKey = "config_last_update"
    
    private init() {
        loadCachedConfig()
    }
    
    // MARK: - Public Methods
    
    /// Loads configuration from remote server and merges with defaults
    func loadRemoteConfig() {
        guard !isLoading else { return }
        
        isLoading = true
        isReady = false // Mark as not ready while loading
        errorMessage = nil
        
        let configURL = URL(string: "\(AppConfig.default.api.baseURL)/configs")!
        var request = URLRequest(url: configURL)
        request.httpMethod = "GET"
        request.timeoutInterval = AppConfig.default.api.timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Attach app and device metadata as headers (no UIKit)
        let clientHeaders = collectClientMetadataHeaders()
        clientHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        print("[ConfigurationManager] Loading remote config from: \(configURL)")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: ConfigResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    self?.isReady = true // Mark as ready regardless of success/failure
                    
                    switch completion {
                    case .finished:
                        print("[ConfigurationManager] Remote config loaded successfully")
                    case .failure(let error):
                        print("[ConfigurationManager] Failed to load remote config: \(error)")
                        self?.errorMessage = "Failed to load remote configuration: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleConfigResponse(response)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Gets the full transcription URL based on current configuration
    func getTranscriptionURL() -> URL {
        let baseURL = currentConfig.api.baseURL
        let endpoint = currentConfig.transcription.endpoint
        return URL(string: "\(baseURL)\(endpoint)")!
    }
    
    /// Gets the default language for transcription
    func getDefaultLanguage() -> String {
        return currentConfig.transcription.defaultLanguage
    }
    
    /// Gets the default max words per line for transcription
    func getDefaultMaxWordsPerLine() -> Int {
        return currentConfig.transcription.maxWordsPerLine
    }
    
    /// Checks if a language is supported
    func isLanguageSupported(_ language: String) -> Bool {
        return currentConfig.transcription.supportedLanguages.contains(language)
    }
    
    /// Gets supported languages
    func getSupportedLanguages() -> [String] {
        return currentConfig.transcription.supportedLanguages
    }
    
    /// Checks if karaoke feature is enabled
    func isKaraokeEnabled() -> Bool {
        return currentConfig.features.enableKaraoke
    }
    
    /// Checks if advanced styling is enabled
    func isAdvancedStylingEnabled() -> Bool {
        return currentConfig.features.enableAdvancedStyling
    }
    
    /// Gets maximum video duration
    func getMaxVideoDuration() -> TimeInterval {
        return currentConfig.features.maxVideoDuration
    }
    
    /// Gets supported video formats
    func getSupportedVideoFormats() -> [String] {
        return currentConfig.features.supportedVideoFormats
    }
    
    /// Checks if text layout optimization is enabled
    func isTextLayoutOptimizationEnabled() -> Bool {
        return currentConfig.features.enableTextLayoutOptimization
    }
    
    /// Checks if crown should be shown in empty state
    func shouldShowCrownInEmptyState() -> Bool {
        return currentConfig.features.showCrownInEmptyState
    }
    
    /// Gets the default preset name for subtitle generation
    func getDefaultPreset() -> String {
        return currentConfig.transcription.defaultPreset
    }
    
    /// Gets remote presets if available
    func getRemotePresets() -> [RemoteSubtitleStyle]? {
        return currentConfig.transcription.presets
    }
    
    /// Checks if remote presets are available
    func hasRemotePresets() -> Bool {
        return currentConfig.transcription.presets != nil && !currentConfig.transcription.presets!.isEmpty
    }
    
    /// Gets excluded preset names
    func getExcludedPresets() -> [String] {
        return currentConfig.transcription.excludePresets ?? []
    }
    
    /// Clears cached configuration to force fresh remote load
    func clearCachedConfig() {
        userDefaults.removeObject(forKey: configKey)
        userDefaults.removeObject(forKey: lastUpdateKey)
        print("[ConfigurationManager] Cached configuration cleared")
    }
    
    // MARK: - RevenueCat Configuration Methods
    
    /// Gets the configured RevenueCat API key
    func getRevenueCatAPIKey() -> String {
        return currentConfig.revenueCat.apiKey
    }
    
    /// Gets the configured paywall offering identifier
    func getPaywallOffering() -> String {
        return currentConfig.revenueCat.paywallOffering
    }
    
    /// Checks if custom paywall should be used
    func shouldUseCustomPaywall() -> Bool {
        return currentConfig.revenueCat.useCustomPaywall
    }
    
    /// Checks if RevenueCat analytics should be enabled
    func isRevenueCatAnalyticsEnabled() -> Bool {
        return currentConfig.revenueCat.enableAnalytics
    }
    
    /// Checks if subscription upgrades are allowed
    func areUpgradesAllowed() -> Bool {
        return currentConfig.revenueCat.allowUpgrades
    }
    
    // MARK: - Paywall Configuration Methods
    
    /// Gets the configured paywall theme
    func getPaywallTheme() -> String {
        return currentConfig.paywall.theme
    }
    
    // MARK: - Takeover Configuration Methods
    
    /// Checks if takeover is enabled
    func isTakeoverEnabled() -> Bool {
        return currentConfig.takeover.isEnabled
    }
    
    /// Gets the takeover configuration
    func getTakeoverConfig() -> TakeoverConfig {
        return currentConfig.takeover
    }
    
    /// Gets the takeover type
    func getTakeoverType() -> TakeoverType {
        return currentConfig.takeover.type
    }
    
    /// Checks if takeover is dismissible
    func isTakeoverDismissible() -> Bool {
        return currentConfig.takeover.dismissible
    }
    
    /// Checks if takeover forces upgrade
    func isTakeoverForceUpgrade() -> Bool {
        return currentConfig.takeover.forceUpgrade
    }
    
    // MARK: - Subscription Configuration Methods
    
    /// Gets video limit for free tier
    func getFreeVideoLimit() -> Int {
        return currentConfig.subscription.freeVideos
    }
    
    /// Gets video limit for pro tier
    func getProVideoLimit() -> Int {
        return currentConfig.subscription.proVideos
    }
    
    /// Gets video limit for unlimited tier
    func getUnlimitedVideoLimit() -> Int {
        return currentConfig.subscription.unlimitedVideos
    }
    
    /// Gets the subscription configuration
    func getSubscriptionConfig() -> SubscriptionConfig {
        return currentConfig.subscription
    }
    
    // MARK: - Async Configuration Loading
    
    /// Waits for configuration to be ready (either loaded successfully or failed)
    func waitForConfigurationReady() async {
        // If already ready, return immediately
        if await isReady { return }
        
        // Wait for isReady to become true
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var cancellable: AnyCancellable?
            
            cancellable = $isReady
                .filter { $0 } // Wait for true
                .first()
                .sink { _ in
                    continuation.resume()
                    cancellable?.cancel() // Clean up the cancellable
                }
            
            // Store the cancellable in the instance to prevent deallocation
            cancellables.insert(cancellable!)
        }
        
        print("[ConfigurationManager] Configuration ready state achieved")
    }
    
    // MARK: - Private Methods
    
    private func handleConfigResponse(_ response: ConfigResponse) {
        if response.success, let remoteConfig = response.config {
            // Merge remote config with defaults
            let mergedConfig = mergeConfigs(default: AppConfig.default, remote: remoteConfig)
            
            // Update on main thread for @Published property
            DispatchQueue.main.async {
                self.currentConfig = mergedConfig
                self.lastUpdateTime = Date() // Use current time since timestamp is now a string
            }
            
            // Cache the merged configuration
            cacheConfig(mergedConfig)
            
            print("[ConfigurationManager] Configuration updated successfully")
        } else {
            print("[ConfigurationManager] Remote config response was not successful: \(response.message ?? "Unknown error")")
            errorMessage = response.message ?? "Failed to load configuration"
        }
    }
    
    private func mergeConfigs(default defaultConfig: AppConfig, remote remoteConfig: AppConfig) -> AppConfig {
        // Merge API config
        let mergedAPIConfig = APIConfig(
            baseURL: remoteConfig.api.baseURL.isEmpty ? defaultConfig.api.baseURL : remoteConfig.api.baseURL,
            timeout: remoteConfig.api.timeout > 0 ? remoteConfig.api.timeout : defaultConfig.api.timeout,
            retryAttempts: remoteConfig.api.retryAttempts > 0 ? remoteConfig.api.retryAttempts : defaultConfig.api.retryAttempts
        )
        
        // Merge transcription config
        let mergedTranscriptionConfig = TranscriptionConfig(
            endpoint: remoteConfig.transcription.endpoint.isEmpty ? defaultConfig.transcription.endpoint : remoteConfig.transcription.endpoint,
            defaultLanguage: remoteConfig.transcription.defaultLanguage.isEmpty ? defaultConfig.transcription.defaultLanguage : remoteConfig.transcription.defaultLanguage,
            maxWordsPerLine: remoteConfig.transcription.maxWordsPerLine > 0 ? remoteConfig.transcription.maxWordsPerLine : defaultConfig.transcription.maxWordsPerLine,
            supportedLanguages: remoteConfig.transcription.supportedLanguages.isEmpty ? defaultConfig.transcription.supportedLanguages : remoteConfig.transcription.supportedLanguages,
            defaultPreset: remoteConfig.transcription.defaultPreset.isEmpty ? defaultConfig.transcription.defaultPreset : remoteConfig.transcription.defaultPreset,
            presets: remoteConfig.transcription.presets ?? defaultConfig.transcription.presets,
            excludePresets: remoteConfig.transcription.excludePresets ?? defaultConfig.transcription.excludePresets
        )
        
        // Merge feature config
        let mergedFeatureConfig = FeatureConfig(
            enableKaraoke: remoteConfig.features.enableKaraoke,
            enableAdvancedStyling: remoteConfig.features.enableAdvancedStyling,
            maxVideoDuration: remoteConfig.features.maxVideoDuration > 0 ? remoteConfig.features.maxVideoDuration : defaultConfig.features.maxVideoDuration,
            supportedVideoFormats: remoteConfig.features.supportedVideoFormats.isEmpty ? defaultConfig.features.supportedVideoFormats : remoteConfig.features.supportedVideoFormats,
            enableTextLayoutOptimization: remoteConfig.features.enableTextLayoutOptimization,
            showCrownInEmptyState: remoteConfig.features.showCrownInEmptyState
        )
        
        // Merge revenueCat config
        let mergedRevenueCatConfig = RevenueCatSettings(
            apiKey: remoteConfig.revenueCat.apiKey.isEmpty ? defaultConfig.revenueCat.apiKey : remoteConfig.revenueCat.apiKey,
            paywallOffering: remoteConfig.revenueCat.paywallOffering.isEmpty ? defaultConfig.revenueCat.paywallOffering : remoteConfig.revenueCat.paywallOffering,
            useCustomPaywall: remoteConfig.revenueCat.useCustomPaywall,
            enableAnalytics: remoteConfig.revenueCat.enableAnalytics,
            allowUpgrades: remoteConfig.revenueCat.allowUpgrades
        )
        
        // Merge paywall config
        let mergedPaywallConfig = PaywallConfig(
            theme: remoteConfig.paywall.theme.isEmpty ? defaultConfig.paywall.theme : remoteConfig.paywall.theme
        )
        
        // Merge takeover config
        let mergedTakeoverConfig = TakeoverConfig(
            isEnabled: remoteConfig.takeover.isEnabled,
            type: remoteConfig.takeover.type,
            title: remoteConfig.takeover.title.isEmpty ? defaultConfig.takeover.title : remoteConfig.takeover.title,
            message: remoteConfig.takeover.message.isEmpty ? defaultConfig.takeover.message : remoteConfig.takeover.message,
            actionButtonText: remoteConfig.takeover.actionButtonText.isEmpty ? defaultConfig.takeover.actionButtonText : remoteConfig.takeover.actionButtonText,
            cancelButtonText: remoteConfig.takeover.cancelButtonText.isEmpty ? defaultConfig.takeover.cancelButtonText : remoteConfig.takeover.cancelButtonText,
            actionURL: remoteConfig.takeover.actionURL ?? defaultConfig.takeover.actionURL,
            backgroundColor: remoteConfig.takeover.backgroundColor ?? defaultConfig.takeover.backgroundColor,
            textColor: remoteConfig.takeover.textColor ?? defaultConfig.takeover.textColor,
            buttonColor: remoteConfig.takeover.buttonColor ?? defaultConfig.takeover.buttonColor,
            icon: remoteConfig.takeover.icon ?? defaultConfig.takeover.icon,
            dismissible: remoteConfig.takeover.dismissible,
            forceUpgrade: remoteConfig.takeover.forceUpgrade
        )
        
        // Merge subscription config
        let mergedSubscriptionConfig = SubscriptionConfig(
            freeVideos: remoteConfig.subscription.freeVideos > 0 ? remoteConfig.subscription.freeVideos : defaultConfig.subscription.freeVideos,
            proVideos: remoteConfig.subscription.proVideos > 0 ? remoteConfig.subscription.proVideos : defaultConfig.subscription.proVideos,
            unlimitedVideos: remoteConfig.subscription.unlimitedVideos > 0 ? remoteConfig.subscription.unlimitedVideos : defaultConfig.subscription.unlimitedVideos
        )
        
        return AppConfig(
            api: mergedAPIConfig,
            transcription: mergedTranscriptionConfig,
            features: mergedFeatureConfig,
            revenueCat: mergedRevenueCatConfig,
            paywall: mergedPaywallConfig,
            takeover: mergedTakeoverConfig,
            subscription: mergedSubscriptionConfig
        )
    }
    
    private func cacheConfig(_ config: AppConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            userDefaults.set(data, forKey: configKey)
            userDefaults.set(Date(), forKey: lastUpdateKey)
            print("[ConfigurationManager] Configuration cached successfully")
        } catch {
            print("[ConfigurationManager] Failed to cache configuration: \(error)")
        }
    }
    
    private func loadCachedConfig() {
        guard let data = userDefaults.data(forKey: configKey) else {
            print("[ConfigurationManager] No cached configuration found, using defaults")
            return
        }
        
        do {
            let cachedConfig = try JSONDecoder().decode(AppConfig.self, from: data)
            
            // Update on main thread for @Published property
            DispatchQueue.main.async {
                self.currentConfig = cachedConfig
                self.lastUpdateTime = self.userDefaults.object(forKey: self.lastUpdateKey) as? Date
            }
            
            print("[ConfigurationManager] Loaded cached configuration")
        } catch {
            print("[ConfigurationManager] Failed to load cached configuration: \(error), using defaults")
            // Keep using the default config that was set in init
        }
    }

    // MARK: - Client Metadata
    
    /// Collects app and environment metadata to send with the config request.
    /// Uses Foundation-only APIs to avoid UIKit.
    private func collectClientMetadataHeaders() -> [String: String] {
        let infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]
        let appVersion: String = infoDictionary["CFBundleShortVersionString"] as? String ?? "unknown"
        let appBuild: String = infoDictionary["CFBundleVersion"] as? String ?? "unknown"
        let appName: String = (infoDictionary["CFBundleDisplayName"] as? String)
            ?? (infoDictionary["CFBundleName"] as? String)
            ?? "unknown"
        let bundleId: String = Bundle.main.bundleIdentifier ?? "unknown"
        
        let os = "iOS"
        let osVersionStruct = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "\(osVersionStruct.majorVersion).\(osVersionStruct.minorVersion).\(osVersionStruct.patchVersion)"
        
        let locale = Locale.current.identifier
        let timezone = TimeZone.current.identifier
        
        // Compose a concise user-agent style string as well
        let userAgent = "\(appName)/\(appVersion) (build \(appBuild)); \(bundleId); \(os) \(osVersion); locale=\(locale); tz=\(timezone)"
        
        return [
            "X-App-Name": appName,
            "X-App-Bundle-ID": bundleId,
            "X-App-Version": appVersion,
            "X-App-Build": appBuild,
            "X-Platform": os,
            "X-OS-Version": osVersion,
            "X-Locale": locale,
            "X-Timezone": timezone,
            "User-Agent": userAgent
        ]
    }
}
