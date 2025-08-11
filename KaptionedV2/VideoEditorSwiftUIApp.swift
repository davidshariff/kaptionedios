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
                    // Load remote configuration when app starts
                    configManager.loadRemoteConfig()
                }
        }
    }
}
