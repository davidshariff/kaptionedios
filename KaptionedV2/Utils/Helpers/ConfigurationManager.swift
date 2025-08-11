import Foundation
import Combine

// MARK: - App Configuration Models

/// Main configuration structure for the app
struct AppConfig: Codable {
    var api: APIConfig
    var transcription: TranscriptionConfig
    var features: FeatureConfig
    
    static let `default` = AppConfig(
        api: APIConfig.default,
        transcription: TranscriptionConfig.default,
        features: FeatureConfig.default
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
    
    static let `default` = TranscriptionConfig(
        endpoint: "/transcribe",
        defaultLanguage: "en",
        maxWordsPerLine: 1,
        supportedLanguages: ["en", "es", "fr", "de", "it", "pt", "ru", "zh", "ja", "ko"]
    )
}

/// Feature flags and settings
struct FeatureConfig: Codable {
    let enableKaraoke: Bool
    let enableAdvancedStyling: Bool
    let maxVideoDuration: TimeInterval
    let supportedVideoFormats: [String]
    
    static let `default` = FeatureConfig(
        enableKaraoke: true,
        enableAdvancedStyling: true,
        maxVideoDuration: 300.0, // 5 minutes
        supportedVideoFormats: ["mp4", "mov", "avi", "mkv"]
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
    
    // MARK: - Private Methods
    
    private func handleConfigResponse(_ response: ConfigResponse) {
        if response.success, let remoteConfig = response.config {
            // Merge remote config with defaults
            let mergedConfig = mergeConfigs(default: AppConfig.default, remote: remoteConfig)
            currentConfig = mergedConfig
            lastUpdateTime = Date() // Use current time since timestamp is now a string
            
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
            supportedLanguages: remoteConfig.transcription.supportedLanguages.isEmpty ? defaultConfig.transcription.supportedLanguages : remoteConfig.transcription.supportedLanguages
        )
        
        // Merge feature config
        let mergedFeatureConfig = FeatureConfig(
            enableKaraoke: remoteConfig.features.enableKaraoke,
            enableAdvancedStyling: remoteConfig.features.enableAdvancedStyling,
            maxVideoDuration: remoteConfig.features.maxVideoDuration > 0 ? remoteConfig.features.maxVideoDuration : defaultConfig.features.maxVideoDuration,
            supportedVideoFormats: remoteConfig.features.supportedVideoFormats.isEmpty ? defaultConfig.features.supportedVideoFormats : remoteConfig.features.supportedVideoFormats
        )
        
        return AppConfig(
            api: mergedAPIConfig,
            transcription: mergedTranscriptionConfig,
            features: mergedFeatureConfig
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
            currentConfig = cachedConfig
            lastUpdateTime = userDefaults.object(forKey: lastUpdateKey) as? Date
            print("[ConfigurationManager] Loaded cached configuration")
        } catch {
            print("[ConfigurationManager] Failed to load cached configuration: \(error), using defaults")
            currentConfig = AppConfig.default
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
