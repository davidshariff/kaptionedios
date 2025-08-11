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

                    // Load remote configuration when app starts
                    configManager.loadRemoteConfig()
                    
                    // Configure RevenueCat
                    RevenueCatManager.shared.configure()
                    
                    // Refresh subscription status to sync with RevenueCat
                    SubscriptionManager.shared.refreshSubscriptionStatus()
                    
                    // Debug RevenueCat setup after a short delay to let it load
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                        await MainActor.run {
                            print("\n" + RevenueCatManager.shared.getSubscriptionDebugInfo() + "\n")
                        }
                    }

                }
                //.debugRevenueCatOverlay()
        }
    }
}
