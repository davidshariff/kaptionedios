import SwiftUI
import PhotosUI

struct RootView: View {
    @ObservedObject var rootVM: RootViewModel
    @State var item: PhotosPickerItem?
    @State var selectedVideoURL: URL?
    @State var showLoader: Bool = false
    @State var showEditor: Bool = false
    @State var showDeleteConfirmation: Bool = false
    @State var projectToDelete: ProjectEntity?

    // Now using RevenueCat's built-in paywall instead
    let columns = [
        GridItem(.adaptive(minimum: 150)),
        GridItem(.adaptive(minimum: 150)),
    ]
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        if rootVM.projects.isEmpty {
                            Spacer()
                            Spacer()
                            // Empty state with welcome design
                            emptyStateView
                        } else {

                            Text("My projects")
                                .font(.headline)

                            // Regular grid with projects
                            LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
                                newProjectButton
                                
                                ForEach(rootVM.projects) { project in
                                    NavigationLink {
                                        MainEditorView(project: project)
                                    } label: {
                                        cellView(project)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationDestination(isPresented: $showEditor){
                MainEditorView(selectedVideoURl: selectedVideoURL)
            }
            .toolbar {
                if !rootVM.projects.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Kaptioned")
                            .font(.title2.bold())
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        subscriptionStatusButton
                    }
                }
            }
            .onChange(of: item) { newItem in
                loadPhotosItem(newItem)
            }
            .onAppear{
                rootVM.fetch()
            }
            .overlay {
                if showLoader {
                    ZStack {
                        // Backdrop blur
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .background(.ultraThinMaterial)
                        
                        // Loading card
                        VStack(spacing: 20) {
                            // Loading animation
                            if showLoader {
                                PremiumLoaderView()
                            }
                            
                            VStack(spacing: 8) {
                                Text("Loading Video")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Please wait while we prepare your video")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 40)
                    }
                    .scaleEffect(showLoader ? 1.0 : 0.9)
                    .opacity(showLoader ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: showLoader)
                }
            }
            .confirmationDialog(
                "Delete Project",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let project = projectToDelete {
                        rootVM.removeProject(project)
                        projectToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    projectToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this project? This action cannot be undone.")
            }
            // Removed custom subscription sheet - now using RevenueCat paywall
        }
    }
    
    // MARK: - Subscription Status Button
    
    private var subscriptionStatusButton: some View {
        Button {
            // Show RevenueCat paywall
            SubscriptionManager.shared.showUpgradePaywall()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text(SubscriptionManager.shared.currentStatus.tier.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}


