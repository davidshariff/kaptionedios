//
//  MainEditorView.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 14.04.2023.
//
import AVKit
import SwiftUI
import PhotosUI

struct MainEditorView: View {

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    var project: ProjectEntity?
    var selectedVideoURl: URL?

    @State var showVideoQualitySheet: Bool = false
    @State var showRecordView: Bool = false
    @State var showCustomSubslistSheet: Bool = false
    @State var controlsHeight: CGFloat = 350 // New state for draggable height
    @State var showCrossOverlay: Bool = false // New state for cross overlay
    @State var showEditSubtitlesMode: Bool = false // New state for edit subtitles mode
    @State var isToolbarAnimating: Bool = false // State to control toolbar animation
    @State var toolbarOffset: CGFloat = 100 // State to control toolbar position
    
    @StateObject var editorVM = EditorViewModel()
    @StateObject var audioRecorder = AudioRecorderManager()
    @StateObject var videoPlayer = VideoPlayerManager()
    @StateObject var textEditor = TextEditorViewModel()
    
    var body: some View {
        ZStack{
            GeometryReader { proxy in
                // main editor view
                VStack(spacing: 0){
                    headerView(safeAreaTop: proxy.safeAreaInsets.top)
                    // video player
                    PlayerHolderView(
                        availableHeight: .constant(proxy.size.height - controlsHeight - 100),
                        editorVM: editorVM, 
                        videoPlayer: videoPlayer, 
                        textEditor: textEditor
                    )
                    .frame(height: proxy.size.height - controlsHeight - 100) // Dynamic height based on controls
                    draggableSection(proxy: proxy)
                }
                .onAppear{
                    setVideo(proxy)
                }
            }
            
            if showVideoQualitySheet, let video = editorVM.currentVideo{
                VideoExporterBottomSheetView(isPresented: $showVideoQualitySheet, video: video)
            }

            // Loading overlay for subtitle generation
            if editorVM.isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView("Generating subtitles...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding(32)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .ignoresSafeArea()
            }
            // Error overlay for subtitle generation
            if editorVM.showErrorAlert {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(editorVM.errorMessage)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                        Button(action: { editorVM.showErrorAlert = false }) {
                            Text("Dismiss")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(32)
                    .background(Color(.systemGray6).opacity(0.95))
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .transition(.opacity)
                .animation(.easeInOut, value: editorVM.showErrorAlert)
            }
            
            // Custom subslist sheet
            if showCustomSubslistSheet {
                SubslistView(isPresented: $showCustomSubslistSheet, textEditor: textEditor, videoPlayer: videoPlayer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1000)
                    .animation(.easeInOut(duration: 0.5), value: showCustomSubslistSheet)
            }
            
            // Centered cross overlay
            if showCrossOverlay {
                CrossOverlayView()
                    .zIndex(1500)
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(.all, edges: .top)
        .fullScreenCover(isPresented: $showRecordView) {
            RecordVideoView{ url in
                videoPlayer.loadState = .loaded(url)
            }
        }
        .statusBar(hidden: true)
        .onChange(of: scenePhase) { phase in
            saveProject(phase)
        }
        .blur(radius: textEditor.showEditor ? 10 : 0)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay {
            if textEditor.showEditor{
                TextEditorView(viewModel: textEditor, onSave: editorVM.setText)
            }
        }
    }
}

// MARK: - Cross Overlay View
struct CrossOverlayView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Horizontal line - full width
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: geometry.size.width, height: 1)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Vertical line - full height
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 1, height: geometry.size.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .allowsHitTesting(false) // Allow touches to pass through
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        MainEditorView(selectedVideoURl: URL(string: "file:///Users/bogdanzykov/Library/Developer/CoreSimulator/Devices/86D65E8C-7D49-47AF-A511-BFA631289CB1/data/Containers/Data/Application/52E5EF3C-9E78-4676-B3EA-03BD22CCD09A/Documents/video_copy.mp4"))
    }
}

extension MainEditorView{
        private func headerView(safeAreaTop: CGFloat) -> some View{
        HStack{
            Button {
                editorVM.updateProject()
                dismiss()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                    Text("Back")
                        .font(.caption2)
                }
                .padding(.top, 8)
                .padding(.leading, 8)
            }

            Spacer()
            
            // Cross overlay toggle button
            Button {
                showCrossOverlay.toggle()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: showCrossOverlay ? "plus.circle.fill" : "plus.circle")
                    Text("Cross")
                        .font(.caption2)
                }
            }
            .foregroundColor(showCrossOverlay ? .yellow : .white)
            
            Spacer()
            
            Button {
                // Ensure text boxes are synced before export
                editorVM.setText(textEditor.textBoxes)
                editorVM.selectedTools = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                    showVideoQualitySheet.toggle()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up.fill")
                    Text("Export")
                    .font(.caption2)
                }
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .frame(height: 50)
        .padding(.top, safeAreaTop + 40)
        .padding(.bottom)
    }
    
    private func draggableSection(proxy: GeometryProxy) -> some View {

        VStack(spacing: 0) {
            if !showEditSubtitlesMode {
                PlayerControl(recorderManager: audioRecorder, editorVM: editorVM, videoPlayer: videoPlayer, textEditor: textEditor)
                Spacer()
            }

            if let video = editorVM.currentVideo, showEditSubtitlesMode {
                // Show word timeline only when in edit subtitles mode
                ZStack {
                    VStack(spacing: 0) {

                        // Top row with close button at the right
                        HStack {
                            Spacer()
                                                    Button {
                            showEditSubtitlesMode = false
                            // Hide toolbar when closing edit mode
                            toolbarOffset = 100
                            textEditor.selectedTextBox = nil
                        } label: {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                        }
                        .frame(height: 40)
                        .padding(.bottom, 8)
                
                        
                        WordTimelineSlider(
                            bounds: video.rangeDuration,
                            disableOffset: false,
                            value: $videoPlayer.currentTime,
                            timelineWidth: 300,
                            textBoxes: video.textBoxes,
                            duration: video.originalDuration,
                            selectedTextBox: $textEditor.selectedTextBox,
                            frameView: {
                                RulerView(duration: video.originalDuration, currentTime: videoPlayer.currentTime, frameWidth: 300, showPlayhead: false, tickHeight: 60)
                                    .frame(maxHeight: .infinity)
                            },
                            actionView: {
                                Rectangle()
                                    .opacity(0)
                            },
                            onChange: {
                                videoPlayer.scrubState = .scrubEnded(videoPlayer.currentTime)
                            }
                        )
                        .frame(height: 120)
                        
                        Spacer()
                    }
                    
                    // Toolbar overlay at the bottom
                    VStack {
                        Spacer()
                        if textEditor.selectedTextBox != nil {
                            HStack(spacing: 0) {
                                Button {
                                    // Handle Edit Text action
                                    if let selectedTextBox = textEditor.selectedTextBox {
                                        textEditor.openTextEditor(isEdit: true, selectedTextBox, timeRange: selectedTextBox.timeRange)
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: "pencil")
                                            .font(.title2)
                                            .frame(width: 24, height: 24)
                                        Text("Edit Text")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 60)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                                }
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                Spacer()
                                    .frame(width: 20)
                                
                                Button {
                                    // Handle Style action
                                    print("Style button tapped")
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: "paintbrush")
                                            .font(.title2)
                                            .frame(width: 24, height: 24)
                                        Text("Style")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 60)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                                }
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .padding(.bottom, 20)
                            .offset(y: toolbarOffset)
                        }
                    }
                }
                .onChange(of: textEditor.selectedTextBox) { newValue in
                    if newValue != nil {
                        // If switching between text boxes (not from nil), trigger animation
                        if textEditor.selectedTextBox != nil {
                            // Slide down
                            withAnimation(.easeInOut(duration: 0.15)) {
                                toolbarOffset = 100
                            }
                            // Then slide up after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    toolbarOffset = 0
                                }
                            }
                        } else {
                            // First time showing, just slide up
                            withAnimation(.easeInOut(duration: 0.3)) {
                                toolbarOffset = 0
                            }
                        }
                    } else {
                        // Hiding toolbar, slide down
                        withAnimation(.easeInOut(duration: 0.3)) {
                            toolbarOffset = 100
                        }
                    }
                }
            }
            
            if !showEditSubtitlesMode {
                ToolsSectionView(
                    videoPlayer: videoPlayer, 
                    editorVM: editorVM, 
                    textEditor: textEditor, 
                    showCustomSubslistSheet: $showCustomSubslistSheet,
                    showEditSubtitlesMode: $showEditSubtitlesMode
                )
                .padding(.bottom, 20)
            }
        }
        .frame(height: controlsHeight)
    }
    
    private func saveProject(_ phase: ScenePhase){
        switch phase{
        case .background, .inactive:
            editorVM.updateProject()
        default:
            break
        }
    }
    
    private func setVideo(_ proxy: GeometryProxy){
        if let selectedVideoURl{
            videoPlayer.loadState = .loaded(selectedVideoURl)
            editorVM.setNewVideo(selectedVideoURl, geo: proxy)
            // Log video information when loading new video
            logVideoInfo(url: selectedVideoURl, isNewVideo: true)
        }
        
        if let project, let url = project.videoURL{
            videoPlayer.loadState = .loaded(url)
            editorVM.setProject(project, geo: proxy)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                videoPlayer.setFilters(mainFilter: CIFilter(name: project.filterName ?? ""), colorCorrection: editorVM.currentVideo?.colorCorrection)
            }
            // Log video information when loading project
            logVideoInfo(url: url, isNewVideo: false)
        }
    }
    
    private func logVideoInfo(url: URL, isNewVideo: Bool) {
        Task {
            do {
                let asset = AVAsset(url: url)
                
                // Get basic video information
                let duration = asset.videoDuration()
                let naturalSize = await asset.naturalSize()
                let fileName = url.lastPathComponent
                let fileSize = getFileSize(url: url)
                
                // Get video track information
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                
                let videoTrack = videoTracks.first
                let frameRate: Float = videoTrack?.nominalFrameRate ?? 0
                let bitrate: Float = videoTrack?.estimatedDataRate ?? 0
                
                // Get additional video properties
                let preferredTransform = try? await videoTrack?.load(.preferredTransform)
                let isPlayable = try? await asset.load(.isPlayable)
                let isExportable = try? await asset.load(.isExportable)
                let hasProtectedContent = try? await asset.load(.hasProtectedContent)
                
                // Calculate aspect ratio
                let aspectRatio = naturalSize?.width ?? 0 > 0 ? (naturalSize?.height ?? 0) / (naturalSize?.width ?? 1) : 0
                let orientation = getVideoOrientation(preferredTransform: preferredTransform)
                
                // Format the log message
                let videoType = isNewVideo ? "NEW VIDEO" : "PROJECT VIDEO"
                let logMessage = """
                🎬 [\(videoType)] Video Loaded Successfully
                📁 File: \(fileName)
                📏 Size: \(fileSize)
                ⏱️ Duration: \(String(format: "%.2f", duration))s (\(duration.formatterTimeString()))
                📐 Resolution: \(Int(naturalSize?.width ?? 0)) x \(Int(naturalSize?.height ?? 0))
                📐 Aspect Ratio: \(String(format: "%.2f", aspectRatio))
                📐 Orientation: \(orientation)
                🎞️ Frame Rate: \(String(format: "%.1f", frameRate)) fps
                📊 Bitrate: \(String(format: "%.0f", bitrate)) bps
                🎵 Audio Tracks: \(audioTracks.count)
                🎬 Video Tracks: \(videoTracks.count)
                ✅ Playable: \(isPlayable ?? false)
                ✅ Exportable: \(isExportable ?? false)
                🔒 Protected: \(hasProtectedContent ?? false)
                🔗 URL: \(url.absoluteString)
                """
                
                print(logMessage)
            } catch {
                print("❌ [VIDEO LOGGING] Error logging video info: \(error.localizedDescription)")
                print("📁 File: \(url.lastPathComponent)")
                print("🔗 URL: \(url.absoluteString)")
            }
        }
    }
    
    private func getVideoOrientation(preferredTransform: CGAffineTransform?) -> String {
        guard let transform = preferredTransform else { return "Unknown" }
        
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            return "Portrait (90°)"
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            return "Portrait (270°)"
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            return "Landscape (0°)"
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            return "Landscape (180°)"
        } else {
            return "Custom"
        }
    }
    
    private func getFileSize(url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useMB, .useGB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: fileSize)
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return "Unknown"
    }
}



