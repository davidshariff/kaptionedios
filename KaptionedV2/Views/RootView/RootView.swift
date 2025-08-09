import SwiftUI
import PhotosUI

struct RootView: View {
    @ObservedObject var rootVM: RootViewModel
    @State private var item: PhotosPickerItem?
    @State private var selectedVideoURL: URL?
    @State private var showLoader: Bool = false
    @State private var showEditor: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var projectToDelete: ProjectEntity?
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
                }
            }
            .onChange(of: item) { newItem in
                loadPhotosItem(newItem)
            }
            .onAppear{
                rootVM.fetch()
            }
            .overlay {
                if showLoader{
                    Color.secondary.opacity(0.2).ignoresSafeArea()
                    VStack(spacing: 10){
                        Text("Loading video")
                        ProgressView()
                    }
                    .padding()
                    .frame(height: 100)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
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
        }
    }
}

struct RootView_Previews2: PreviewProvider {
    static var previews: some View {
        RootView(rootVM: RootViewModel(mainContext: dev.viewContext))
    }
}

extension RootView{
    
    private func optimalFontSize() -> CGFloat {
        // All tip texts
        let tipTexts = [
            "Automatic caption generation",
            "Stunning text styles for social media",
            "Perfect for TikTok, Instagram & YouTube"
        ]
        
        // Find the longest text
        let longestText = tipTexts.max(by: { $0.count < $1.count }) ?? ""
        
        // Estimate available width (screen width minus padding, icon space, etc.)
        let estimatedAvailableWidth: CGFloat = 280 // Conservative estimate
        let maxFontSize: CGFloat = 16
        let minFontSize: CGFloat = 10
        
        // Calculate approximate characters per line
        let charsPerLine = estimatedAvailableWidth / (maxFontSize * 0.6)
        
        if CGFloat(longestText.count) <= charsPerLine {
            return maxFontSize
        } else {
            // Scale down proportionally based on longest text
            let scaleFactor = charsPerLine / CGFloat(longestText.count)
            let calculatedSize = maxFontSize * scaleFactor
            return max(calculatedSize, minFontSize)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            // Hero section with welcome message
            VStack(spacing: 16) {
                // Large icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 8) {
                    Text("Welcome to Kaptioned")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Automatically generate stunning captions for your videos")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            // Enhanced new project button for empty state
            VStack(spacing: 12) {
                PhotosPicker(selection: $item, matching: .videos) {
                    VStack(spacing: 16) {
                        // Icon with animated background
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Create New Project")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Import a video to get started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                // Helpful tips
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "captions.bubble")
                            .foregroundColor(.blue)
                            .font(.title3)
                            .frame(width: 24, height: 24)
                        Text("Automatic caption generation")
                            .font(.system(size: optimalFontSize()))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .font(.title3)
                            .frame(width: 24, height: 24)
                        Text("Stunning text styles for social media")
                            .font(.system(size: optimalFontSize()))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "video.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                            .frame(width: 24, height: 24)
                        Text("Perfect for TikTok, Instagram & YouTube")
                            .font(.system(size: optimalFontSize()))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6).opacity(0.5))
                )
            }
        }
        .padding(.top, 40)
    }
    
    private var newProjectButton: some View{
        
        PhotosPicker(selection: $item, matching: .videos) {
            VStack(spacing: 10) {
                Image(systemName: "plus")
                Text("New project")
            }
            .hCenter()
            .frame(height: 150)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 5))
            .foregroundColor(.white)
        }
    }
       
    private func cellView(_ project: ProjectEntity) -> some View{
        ZStack {
            Color.white
            Image(uiImage: project.uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
            LinearGradient(colors: [.black.opacity(0.35), .black.opacity(0.2), .black.opacity(0.1)], startPoint: .bottom, endPoint: .top)
        }
        .hCenter()
        .frame(height: 150)
        .cornerRadius(5)
        .clipped()
        .overlay {
            VStack{
                Button {
                    projectToDelete = project
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                }
                .hTrailing()
                Spacer()
                Text(project.createAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .foregroundColor(.white)
                    .hLeading()
            }
            .font(.footnote.weight(.medium))
            .padding(10)
        }
    }
    
    
    private func loadPhotosItem(_ newItem: PhotosPickerItem?){
        Task {
            self.showLoader = true
            if let video = try await newItem?.loadTransferable(type: VideoItem.self) {
                selectedVideoURL = video.url
                try await Task.sleep(for: .milliseconds(50))
                self.showLoader = false
                self.showEditor.toggle()
                
            } else {
                print("Failed load video")
                self.showLoader = false
            }
        }
    }
}
