//////////////////////////////////
// Main entry point for the app //
//////////////////////////////////

import SwiftUI

@main
struct VideoEditorSwiftUIApp: App {
    @StateObject var rootVM = RootViewModel(mainContext: PersistenceController.shared.viewContext)
    var body: some Scene {
        WindowGroup {
            RootView(rootVM: rootVM)
                .preferredColorScheme(.dark)
        }
    }
}
