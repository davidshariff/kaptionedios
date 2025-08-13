import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToSettings = Notification.Name("navigateToSettings")
    static let navigateToHelp = Notification.Name("navigateToHelp")
    static let navigateToFeedback = Notification.Name("navigateToFeedback")
    static let navigateToAbout = Notification.Name("navigateToAbout")
    static let navigateToEditor = Notification.Name("navigateToEditor")
}

/// Manages app takeovers for upgrades, maintenance, announcements, etc.
class TakeoverManager: ObservableObject {
    static let shared = TakeoverManager()
    
    @Published var isTakeoverActive = false
    @Published var currentTakeoverConfig: TakeoverConfig?
    
    private var cancellables = Set<AnyCancellable>()
    private let configManager = ConfigurationManager.shared
    
    private init() {
        setupConfigurationObserver()
    }
    
    // MARK: - Public Methods
    
    /// Checks if takeover should be shown and activates it if needed
    func checkAndShowTakeover() {
        guard configManager.isTakeoverEnabled() else {
            print("[TakeoverManager] Takeover is disabled in configuration")
            return
        }
        
        let config = configManager.getTakeoverConfig()
        
        // Don't show if already active
        guard !isTakeoverActive else {
            print("[TakeoverManager] Takeover already active")
            return
        }
        
        // Validate config has required content
        guard !config.title.isEmpty && !config.message.isEmpty else {
            print("[TakeoverManager] Takeover config missing required content")
            return
        }
        
        print("[TakeoverManager] Activating takeover: \(config.type.rawValue)")
        
        DispatchQueue.main.async {
            self.currentTakeoverConfig = config
            self.isTakeoverActive = true
        }
    }
    
    /// Dismisses the current takeover
    func dismissTakeover() {
        print("[TakeoverManager] Dismissing takeover")
        
        DispatchQueue.main.async {
            self.isTakeoverActive = false
            self.currentTakeoverConfig = nil
        }
    }
    
    /// Handles the action button tap
    func handleActionButton() {
        guard let config = currentTakeoverConfig else { return }
        
        print("[TakeoverManager] Action button tapped for takeover: \(config.type.rawValue)")
        
        // First, try to open URL if provided (for any takeover type)
        if let actionURL = config.actionURL,
           let url = URL(string: actionURL) {
            openURL(url)
            // Don't dismiss if forceUpgrade is true
            if !config.forceUpgrade {
                dismissTakeover()
            }
            return
        }
        
        // Fall back to type-specific actions
        switch config.type {
        case .upgrade:
            handleUpgradeAction()
        case .maintenance:
            handleMaintenanceAction()
        case .announcement:
            handleAnnouncementAction()
        case .message:
            handleMessageAction()
        case .error:
            handleErrorAction()
        }
        
        // Dismiss takeover unless it's a force upgrade
        if !config.forceUpgrade {
            dismissTakeover()
        }
    }
    
    /// Handles the cancel button tap
    func handleCancelButton() {
        guard let config = currentTakeoverConfig else { return }
        
        print("[TakeoverManager] Cancel button tapped for takeover: \(config.type.rawValue)")
        
        // Only dismiss if it's dismissible
        if config.dismissible {
            dismissTakeover()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupConfigurationObserver() {
        configManager.$currentConfig
            .sink { [weak self] _ in
                // Check for takeover when config changes
                self?.checkAndShowTakeover()
            }
            .store(in: &cancellables)
    }
    
    private func handleUpgradeAction() {
        print("[TakeoverManager] Handling upgrade action")
        
        // Show RevenueCat paywall
        SubscriptionManager.shared.showUpgradePaywall()
    }
    
    private func handleMaintenanceAction() {
        print("[TakeoverManager] Handling maintenance action")
        
        // Could open a maintenance status page or refresh the app
        // For now, just dismiss
    }
    
    private func handleAnnouncementAction() {
        print("[TakeoverManager] Handling announcement action")
        
        // Announcement actions are typically informational
        // URL opening is now handled in the main action method
    }
    
    private func openURL(_ url: URL) {
        print("[TakeoverManager] Opening URL: \(url)")
        
        // Handle custom URL schemes for native navigation
        if url.scheme == "kaptioned" {
            handleNativeURLScheme(url)
            return
        }
        
        #if os(iOS)
        // Special handling for native App Store URLs
        if url.scheme == "itms-apps" || url.scheme == "itms" {
            print("[TakeoverManager] Opening native App Store URL: \(url)")
            UIApplication.shared.open(url) { success in
                if success {
                    print("[TakeoverManager] Successfully opened native App Store")
                } else {
                    print("[TakeoverManager] Failed to open native App Store, falling back to Safari")
                    // Fallback to Safari version
                    let safariURL = url.absoluteString.replacingOccurrences(of: "itms-apps://", with: "https://")
                    if let fallbackURL = URL(string: safariURL) {
                        UIApplication.shared.open(fallbackURL)
                    }
                }
            }
            return
        }
        
        // Special handling for App Store URLs
        if url.host?.contains("apps.apple.com") == true {
            print("[TakeoverManager] Opening App Store URL: \(url)")
            UIApplication.shared.open(url) { success in
                if success {
                    print("[TakeoverManager] Successfully opened App Store URL")
                } else {
                    print("[TakeoverManager] Failed to open App Store URL")
                }
            }
            return
        }
        
        // Use UIApplication to open URL
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                if success {
                    print("[TakeoverManager] Successfully opened URL: \(url)")
                } else {
                    print("[TakeoverManager] Failed to open URL: \(url)")
                }
            }
        } else {
            print("[TakeoverManager] Cannot open URL: \(url)")
        }
        #else
        // For other platforms, just log
        print("[TakeoverManager] Would open URL: \(url)")
        #endif
    }
    
    private func handleNativeURLScheme(_ url: URL) {
        print("[TakeoverManager] Handling native URL scheme: \(url)")
        
        guard let host = url.host else {
            print("[TakeoverManager] Invalid native URL: missing host")
            return
        }
        
        switch host {
        case "settings":
            navigateToSettings()
        case "subscription":
            navigateToSubscription()
        case "help":
            navigateToHelp()
        case "feedback":
            navigateToFeedback()
        case "about":
            navigateToAbout()
        case "editor":
            navigateToEditor()
        default:
            print("[TakeoverManager] Unknown native URL host: \(host)")
        }
    }
    
    // MARK: - Native Navigation Methods
    
    private func navigateToSettings() {
        print("[TakeoverManager] Navigating to Settings")
        // Post notification for settings navigation
        NotificationCenter.default.post(name: .navigateToSettings, object: nil)
    }
    
    private func navigateToSubscription() {
        print("[TakeoverManager] Navigating to Subscription")
        // Show RevenueCat paywall
        SubscriptionManager.shared.showUpgradePaywall()
    }
    
    private func navigateToHelp() {
        print("[TakeoverManager] Navigating to Help")
        // Post notification for help navigation
        NotificationCenter.default.post(name: .navigateToHelp, object: nil)
    }
    
    private func navigateToFeedback() {
        print("[TakeoverManager] Navigating to Feedback")
        // Post notification for feedback navigation
        NotificationCenter.default.post(name: .navigateToFeedback, object: nil)
    }
    
    private func navigateToAbout() {
        print("[TakeoverManager] Navigating to About")
        // Post notification for about navigation
        NotificationCenter.default.post(name: .navigateToAbout, object: nil)
    }
    
    private func navigateToEditor() {
        print("[TakeoverManager] Navigating to Editor")
        // Post notification for editor navigation
        NotificationCenter.default.post(name: .navigateToEditor, object: nil)
    }
    
    private func handleMessageAction() {
        print("[TakeoverManager] Handling message action")
        
        // Simple acknowledgment
    }
    
    private func handleErrorAction() {
        print("[TakeoverManager] Handling error action")
        
        // Could retry operation or refresh app
    }
}

// MARK: - Takeover View Modifier

struct TakeoverModifier: ViewModifier {
    @ObservedObject private var takeoverManager = TakeoverManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if takeoverManager.isTakeoverActive,
                   let config = takeoverManager.currentTakeoverConfig {
                    TakeoverView(
                        config: config,
                        onAction: {
                            takeoverManager.handleActionButton()
                        },
                        onCancel: {
                            takeoverManager.handleCancelButton()
                        }
                    )
                    .zIndex(1000) // Ensure it's on top
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Adds takeover support to any view
    func withTakeover() -> some View {
        modifier(TakeoverModifier())
    }
}
