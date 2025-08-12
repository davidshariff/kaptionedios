//////////////////////////////////
// Main entry point for the app //
//////////////////////////////////

import SwiftUI

@main
struct VideoEditorSwiftUIApp: App {
    
    @StateObject var rootVM = RootViewModel(mainContext: PersistenceController.shared.viewContext)
    @StateObject var configManager = ConfigurationManager.shared 
    
    var body: some Scene {
        WindowGroup {
            RootView(rootVM: rootVM)
                .preferredColorScheme(.dark)
                .onAppear {

                    #if DEBUG
                        print("🛠️ App running in DEBUG mode")
                    #else
                        print("🚀 App running in PRODUCTION mode")
                    #endif

                    // Start the coordinated configuration loading sequence
                    Task {
                        await startupSequence()
                    }

                }
                //.debugRevenueCatOverlay()
        }
    }
    
    // MARK: - Startup Sequence
    
    /// Coordinates the startup sequence: ConfigurationManager -> RevenueCat -> SubscriptionManager
    private func startupSequence() async {
        print("[App] 🚀 Starting coordinated configuration loading sequence...")
        
        // Step 1: Load remote configuration
        print("[App] 📡 Step 1: Loading remote configuration...")
        await MainActor.run {
            configManager.loadRemoteConfig()
        }
        
        // Step 2: Wait for configuration to be ready, then configure RevenueCat
        print("[App] 💳 Step 2: Configuring RevenueCat...")
        await RevenueCatManager.shared.configure()
        
        // Step 3: Now initialize SubscriptionManager's RevenueCat sync
        print("[App] 📊 Step 3: Initializing SubscriptionManager RevenueCat sync...")
        await SubscriptionManager.shared.initializeRevenueCatSync()
        
        // Step 4: Debug info after everything is loaded
        print("[App] 🔍 Step 4: Generating debug info...")
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        await MainActor.run {
            print("\n" + RevenueCatManager.shared.getSubscriptionDebugInfo() + "\n")
        }
        
        print("[App] ✅ Startup sequence completed!")
    }
}
