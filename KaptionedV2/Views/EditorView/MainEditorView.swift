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
    @State var showCrossOverlay: Bool = false // New state for cross overlay
    @State var showEditSubtitlesMode: Bool = false // New state for edit subtitles mode
    @State var toolbarOffset: CGFloat = 100 // State to control toolbar position
    @State var showPresetsBottomSheet: Bool = false // State to track presets bottom sheet
    @State var showPresetConfirm: Bool = false // State for preset confirmation
    @State var pendingPreset: SubtitleStyle? = nil // State for pending preset
    @State var videoPlayerHeight: CGFloat = 0 // State for video player height
    @State var videoPlayerSize: VideoPlayerSize = .half // State to track video player size
    @State var availableHeightExcludingPlayer: CGFloat = 200 // State for available height excluding video player
    @State var rulerOffset: CGFloat = 0 // State to track ruler offset
    @State var actualTimelineWidth: CGFloat = 0 // State for actual timeline width
    @State var rulerStartInParentX: CGFloat = 0 // State for ruler start position in parent
    @State var externalDragOffset: CGFloat = 0 // State for external drag offset from text boxes
    @State var externalZoomOffset: CGFloat = 0 // State for external zoom offset from text boxes
    
    // Enum for video player sizes
    enum VideoPlayerSize: CaseIterable {
        case quarter, half, threeQuarters, full, custom
        
        var displayName: String {
            switch self {
            case .quarter: return "¼"
            case .half: return "½"
            case .threeQuarters: return "¾"
            case .full: return "Full"
            case .custom: return "Custom"
            }
        }
        
        var iconName: String {
            switch self {
            case .quarter: return "rectangle.compress.vertical"
            case .half: return "rectangle"
            case .threeQuarters: return "rectangle.expand.vertical"
            case .full: return "rectangle.fill"
            case .custom: return "rectangle.dashed"
            }
        }
    }
    
    @StateObject var editorVM = EditorViewModel()
    @StateObject var videoPlayer = VideoPlayerManager()
    @StateObject var textEditor = TextEditorViewModel()
    @StateObject var audioRecorder = AudioRecorderManager()
    
    // Function to calculate video player height based on size and screen dimensions
    private func calculateVideoPlayerHeight(for size: VideoPlayerSize, screenHeight: CGFloat, headerHeight: CGFloat = 0) -> CGFloat {
        switch size {
        case .quarter:
            return screenHeight * 0.25
        case .half:
            return screenHeight * 0.5
        case .threeQuarters:
            return screenHeight * 0.75
        case .full:
            return screenHeight - headerHeight // Subtract header height for full size
        case .custom:
            return 200 // Custom height when presets bottom sheet is open
        }
    }
    
    var body: some View {
        ZStack{
            GeometryReader { proxy in

                // main editor view
                VStack(spacing: 0){

                    headerView(safeAreaTop: proxy.safeAreaInsets.top)

                    // video player
                    PlayerHolderView(
                        availableHeight: .constant(videoPlayerHeight),
                        editorVM: editorVM, 
                        videoPlayer: videoPlayer, 
                        textEditor: textEditor
                    )
                    .frame(height: videoPlayerHeight) // Dynamic height based on controls and bottom sheet
                    .animation(.easeInOut(duration: 0.5), value: videoPlayerHeight) // Smooth animation when video height changes
                    .animation(.easeInOut(duration: 0.5), value: showPresetsBottomSheet) // Smooth animation when bottom sheet opens/closes

                    draggableSection()

                    Spacer()

                    if !showEditSubtitlesMode {
                        ToolsSectionView(
                            videoPlayer: videoPlayer, 
                            editorVM: editorVM, 
                            textEditor: textEditor, 
                            showCustomSubslistSheet: $showCustomSubslistSheet,
                            showEditSubtitlesMode: $showEditSubtitlesMode,
                            showPresetsBottomSheet: $showPresetsBottomSheet
                        )
                    }

                }
                // Set initial video player height
                .onAppear{
                    setVideo(proxy)
                    let headerHeight = 50 + proxy.safeAreaInsets.top + 40 + 20 // header height + safe area + top padding + bottom padding
                    videoPlayerHeight = calculateVideoPlayerHeight(for: videoPlayerSize, screenHeight: proxy.size.height, headerHeight: headerHeight)
                }
                // Update video player height when video player size changes
                .onChange(of: videoPlayerSize) { _ in
                    let headerHeight = 50 + proxy.safeAreaInsets.top + 40 + 20 // header height + safe area + top padding + bottom padding
                    videoPlayerHeight = calculateVideoPlayerHeight(for: videoPlayerSize, screenHeight: proxy.size.height, headerHeight: headerHeight)
                }
                .onChange(of: videoPlayerHeight) { _ in
                    // Update available height whenever video player height changes
                    let headerHeight = 50 + proxy.safeAreaInsets.top + 40 + 20 // header height + safe area + top padding + bottom padding
                    availableHeightExcludingPlayer = proxy.size.height - videoPlayerHeight - headerHeight // Subtract video height, header, and some padding
                }
                // Update video player height when bottom sheet state changes
                .onChange(of: showPresetsBottomSheet) { newValue in
                    if newValue {
                        // When bottom sheet opens, set to quarter size
                        videoPlayerSize = .quarter
                    } else {
                        // When bottom sheet closes, restore to half size
                        videoPlayerSize = .half
                    }
                }
                // Update video player height when edit mode changes
                .onChange(of: showEditSubtitlesMode) { newValue in
                    if newValue {
                        // When edit mode is activated, set to half size
                        videoPlayerSize = .half
                    }
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
            
            // Presets bottom sheet
            if showPresetsBottomSheet {
                VStack(spacing: 0) {
                    Spacer()
                    PresetsListView(
                        isPresented: $showPresetsBottomSheet,
                        showPresetConfirm: $showPresetConfirm,
                        pendingPreset: $pendingPreset,
                        onSelect: { style in
                            print("DEBUG: Preset selected: \(style.name)")
                            pendingPreset = style
                            showPresetConfirm = true
                            print("DEBUG: showPresetConfirm set to: \(showPresetConfirm)")
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: availableHeightExcludingPlayer) // Dynamic height based on available space
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2000)
                    .animation(.easeInOut(duration: 0.5), value: showPresetsBottomSheet)
                }
            }
            
            // Centered cross overlay
            if showCrossOverlay {
                CrossOverlayView()
                    .zIndex(1500)
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
        .confirmationDialog(
            "Apply preset to all subtitles?",
            isPresented: $showPresetConfirm,
            titleVisibility: .visible
        ) {
            Button("Apply", role: .destructive) {
                print("DEBUG: Apply button tapped")
                if let style = pendingPreset {
                    print("DEBUG: Applying style: \(style.name)")
                    if isKaraokePreset(style) {
                        print("DEBUG: Generating karaoke subtitles")
                        // For karaoke presets, generate new subtitles
                        if let video = editorVM.currentVideo {
                            let karaokeType = getKaraokeType(for: style)
                            // Convert current textBoxes to lines format
                            let lines = textEditor.textBoxes.map { textBox in
                                (text: textBox.text, start: textBox.timeRange.lowerBound, end: textBox.timeRange.upperBound)
                            }
                            let subs = KaraokeSubsHelper.generateKaraokeSubs(
                                for: video,
                                karaokeType: karaokeType,
                                lines: lines
                            )
                            textEditor.textBoxes = subs
                            editorVM.setText(subs)
                        }
                    } else {
                        print("DEBUG: Applying regular preset")
                        // For regular presets, apply style to existing subtitles
                        textEditor.textBoxes = textEditor.textBoxes.map { style.apply(to: $0) }
                        editorVM.setText(textEditor.textBoxes)
                    }
                }
                showPresetConfirm = false
                // Only close the preset view for karaoke presets
                if let style = pendingPreset, isKaraokePreset(style) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showPresetsBottomSheet = false
                    }
                }
                pendingPreset = nil
            }
            Button("Cancel", role: .cancel) {
                print("DEBUG: Cancel button tapped")
                pendingPreset = nil
            }
        } message: {
            Text("This will replace the style of all subtitles with the selected preset.")
        }
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
    
    // Helper functions for preset handling
    private func isKaraokePreset(_ style: SubtitleStyle) -> Bool {
        return style.name == "Highlight by letter" || 
               style.name == "Highlight by word" || 
               style.name == "Background by word"
    }
    
    private func getKaraokeType(for style: SubtitleStyle) -> KaraokeType {
        switch style.name {
        case "Highlight by letter": return .letter
        case "Highlight by word": return .word
        case "Background by word": return .wordbg
        default: return .word
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
            
            // Center buttons container
            HStack(spacing: 20) {
                // Video player size toggle button
                Button {
                    // Cycle through video player sizes (excluding custom)
                    let cycleSizes: [VideoPlayerSize] = [.quarter, .half, .threeQuarters, .full]
                    if let currentIndex = cycleSizes.firstIndex(of: videoPlayerSize) {
                        let nextIndex = (currentIndex + 1) % cycleSizes.count
                        videoPlayerSize = cycleSizes[nextIndex]
                    } else {
                        // If current size is custom, go to half
                        videoPlayerSize = .half
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: videoPlayerSize.iconName)
                        Text(videoPlayerSize.displayName)
                            .font(.caption2)
                    }
                }
                .foregroundColor(videoPlayerSize == .custom ? .green : .white)
                
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
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            
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
    
    private func draggableSection() -> some View {

        VStack(spacing: 0) {
            if !showEditSubtitlesMode, !showPresetsBottomSheet {
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
                            value: $videoPlayer.currentTime,
                            selectedTextBox: $textEditor.selectedTextBox,
                            bounds: video.rangeDuration,
                            disableOffset: false,
                            textBoxes: video.textBoxes,
                            duration: video.originalDuration,
                            offset: $rulerOffset,
                            actualTimelineWidth: $actualTimelineWidth,
                            rulerStartInParentX: $rulerStartInParentX,
                            externalDragOffset: $externalDragOffset,
                            externalZoomOffset: $externalZoomOffset,
                            backgroundView: {
                                RulerView(
                                    value: $videoPlayer.currentTime,
                                    bounds: video.rangeDuration,
                                    disableOffset: false,
                                    duration: video.originalDuration, 
                                    currentTime: videoPlayer.currentTime, 
                                    showPlayhead: true, 
                                    tickHeight: 60, 
                                    customPixelsPerSecond: 50,
                                    actualTimelineWidth: $actualTimelineWidth,
                                    rulerStartInParentX: $rulerStartInParentX,
                                    exposedOffset: $rulerOffset,
                                    externalDragOffset: $externalDragOffset,
                                    externalZoomOffset: $externalZoomOffset,
                                    onChange: {
                                        videoPlayer.scrubState = .scrubEnded(videoPlayer.currentTime)
                                    }
                                )
                                .frame(maxHeight: .infinity)
                            },
                            actionView: {
                                Rectangle()
                                    .opacity(0)
                            },
                            onChange: {
                                videoPlayer.scrubState = .scrubEnded(videoPlayer.currentTime)
                            },
                            onSeek: { time in
                                videoPlayer.seekToTime(time)
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
            
        }

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



