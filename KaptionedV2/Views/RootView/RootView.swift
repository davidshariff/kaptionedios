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
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        if rootVM.projects.isEmpty {
                            // Empty state with welcome design
                            emptyStateView
                        } else {
                            ProjectsGridView(
                                rootVM: rootVM,
                                item: $item,
                                showDeleteConfirmation: $showDeleteConfirmation,
                                projectToDelete: $projectToDelete
                            )
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
        }
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
                // Large icon with gradient background and animations
                ZStack {
                    // Animated background circle with pulsing effect
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(1.0)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: UUID()
                        )
                        .overlay(
                            // Flashlight beam effect
                            FlashlightBeamView()
                        )
                    
                    // Floating sparkles around the icon
                    ForEach(0..<8, id: \.self) { index in
                        SparkleView()
                            .offset(
                                x: 80 * cos(Double(index) * .pi / 4),
                                y: 80 * sin(Double(index) * .pi / 4)
                            )
                            .animation(
                                Animation.easeInOut(duration: 3.0 + Double(index) * 0.2)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1),
                                value: UUID()
                            )
                    }
                    
                    // Main icon
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: UUID()
                        )
                }
                
                VStack(spacing: 8) {
                    Text("Welcome to Kaptioned")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .opacity(0.8)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: UUID()
                        )
                    
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
                        // Icon with background
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
    

    
    
    private func loadPhotosItem(_ newItem: PhotosPickerItem?){
        Task {
            self.showLoader = true
            if let video = try await newItem?.loadTransferable(type: VideoItem.self) {
                selectedVideoURL = video.url
                // Show loader for at least 1 second so animation is visible
                try await Task.sleep(for: .milliseconds(1000))
                self.showLoader = false
                self.showEditor.toggle()
                
            } else {
                print("Failed load video")
                self.showLoader = false
            }
        }
    }
}

// MARK: - Premium Loader Component
struct PremiumLoaderView: View {
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Outer pulsing ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.2),
                            Color.blue.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 90, height: 90)
                .scaleEffect(pulseScale)
                .opacity(0.6)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                    value: pulseScale
                )
            
            // Main gradient ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.4),
                            Color.purple.opacity(0.3),
                            Color.pink.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 75, height: 75)
            
            // Animated progress ring
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.blue,
                            Color.purple,
                            Color.pink,
                            Color.blue.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 75, height: 75)
                .rotationEffect(.degrees(-90))
                .rotationEffect(.degrees(rotationAngle))
                .animation(
                    .linear(duration: 2.5)
                    .repeatForever(autoreverses: false),
                    value: rotationAngle
                )
            
            // Inner core with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.4),
                                Color.purple.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 0.8 : 0.4)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Center dot
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                    .shadow(color: .blue.opacity(0.5), radius: 4, x: 0, y: 0)
            }
            
            // Sparkle effects
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 2, height: 2)
                    .offset(x: 35)
                    .rotationEffect(.degrees(Double(index) * 60))
                    .rotationEffect(.degrees(rotationAngle * 0.5))
                    .opacity(isAnimating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
            pulseScale = 1.3
            rotationAngle = 360
        }
    }
}

// Sparkle view for floating animations with individual color changes
private struct SparkleView: View {
    @State private var isAnimating = false
    @State private var colorIndex = 0
    
    private let colors: [Color] = [
        .blue.opacity(0.6),
        .purple.opacity(0.6),
        .pink.opacity(0.6),
        .orange.opacity(0.6),
        .green.opacity(0.6)
    ]
    
    // Random delay for each sparkle to start color cycling
    private let randomDelay: Double
    
    init() {
        self.randomDelay = Double.random(in: 0...2.0)
    }
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 12))
            .foregroundColor(colors[colorIndex])
            .scaleEffect(isAnimating ? 1.5 : 0.5)
            .opacity(isAnimating ? 1.0 : 0.3)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
                
                // Individual color cycling animation with random delay
                DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                    Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            colorIndex = (colorIndex + 1) % colors.count
                        }
                    }
                }
            }
    }
}

// Flashlight beam view that rotates around the circle
private struct FlashlightBeamView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .white.opacity(0.4),
                        .blue.opacity(0.2),
                        .clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 50
                )
            )
            .frame(width: 120, height: 120)
            .rotationEffect(.degrees(rotationAngle))
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 3.0)
                        .repeatForever(autoreverses: false)
                ) {
                    rotationAngle = 360
                }
            }
    }
}
