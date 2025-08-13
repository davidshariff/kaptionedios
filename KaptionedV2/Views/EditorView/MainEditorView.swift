import AVKit
import SwiftUI
import PhotosUI
import CoreData

struct MainEditorView: View {

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    var project: ProjectEntity?
    var selectedVideoURl: URL?

    @State var showVideoQualitySheet: Bool = false
    @State var showRecordView: Bool = false
    @State var showBackConfirmation: Bool = false
    @State var showCustomSubslistSheet: Bool = false
    @State var showCrossOverlay: Bool = false // New state for cross overlay
    @State var showEditSubtitlesMode: Bool = false // New state for edit subtitles mode
    @State var showPresetsBottomSheet: Bool = false // State to track presets bottom sheet
    @State var showPresetConfirm: Bool = false // State for preset confirmation
    @State var isSaving: Bool = false // State for saving indicator

    @State var pendingPreset: SubtitleStyle? = nil // State for pending preset
    @State var videoPlayerHeight: CGFloat = 0 // State for video player height
    @State var availableHeightExcludingPlayer: CGFloat = 200 // State for available height excluding video player
    @State var rulerOffset: CGFloat = 0 // State to track ruler offset
    @State var actualTimelineWidth: CGFloat = 0 // State for actual timeline width
    @State var rulerStartInParentX: CGFloat = 0 // State for ruler start position in parent
    @State var externalDragOffset: CGFloat = 0 // State for external drag offset from text boxes
    @State var externalZoomOffset: CGFloat = 0 // State for external zoom offset from text boxes
    @State var styleSheetOffset: CGFloat = 1000 // State for style sheet slide-up animation
    

    
    @StateObject var editorVM = EditorViewModel()
    @StateObject var videoPlayer = VideoPlayerManager()
    @StateObject var textEditor = TextEditorViewModel()
    @StateObject var audioRecorder = AudioRecorderManager()
    

    
    var body: some View {
        ZStack{

            // main video player view
            GeometryReader { proxy in

                VStack(spacing: 0){

                    headerView(safeAreaTop: proxy.safeAreaInsets.top)

                    // video player
                    PlayerHolderView(
                        availableHeight: .constant(videoPlayerHeight),
                        editorVM: editorVM, 
                        videoPlayer: videoPlayer, 
                        textEditor: textEditor,
                        showEditSubtitlesMode: $showEditSubtitlesMode
                    )
                    .frame(height: videoPlayerHeight) // Dynamic height based on controls and bottom sheet
                    .animation(.easeInOut(duration: 0.5), value: videoPlayerHeight) // Smooth animation when video height changes
                    .animation(.easeInOut(duration: 0.5), value: showPresetsBottomSheet) // Smooth animation when bottom sheet opens/closes

                    centerSection()

                    Spacer()

                    if !showEditSubtitlesMode {
                        ToolsSectionView(
                            videoPlayer: videoPlayer, 
                            editorVM: editorVM, 
                            textEditor: textEditor, 
                            showCustomSubslistSheet: $showCustomSubslistSheet,
                            showEditSubtitlesMode: $showEditSubtitlesMode,
                            showPresetsBottomSheet: $showPresetsBottomSheet,
                            showPresetConfirm: $showPresetConfirm,
                            pendingPreset: $pendingPreset
                        )
                    }

                }
                // Set initial video player height
                .onAppear{
                    setVideo(proxy)
                    let headerHeight = 50 + proxy.safeAreaInsets.top + 40 + 20 // header height + safe area + top padding + bottom padding
                    videoPlayerHeight = editorVM.calculateVideoPlayerHeight(for: editorVM.videoPlayerSize, screenHeight: proxy.size.height, headerHeight: headerHeight)
                    
                    // Set callback to reset video player size when edit text content is closed
                     textEditor.onEditTextContentClosed = {
                         editorVM.videoPlayerSize = .half
                     }
                     
                     // Set callback to save text boxes to the main video model
                     textEditor.onSave = { textBoxes in
                         print("DEBUG: textEditor.onSave called")
                         isSaving = true
                         editorVM.setText(textBoxes)
                         // Hide saving indicator after a short delay
                         DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                             isSaving = false
                         }
                     }
                     
                     // Set callback for saving indicator
                     editorVM.onSaving = {
                         print("DEBUG: onSaving callback triggered")
                         isSaving = true
                         // Hide saving indicator after a short delay
                         DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                             isSaving = false
                         }
                     }
                     
                     // Set callback for automatic text box updates
                     editorVM.onTextBoxesUpdated = { textBoxes in
                         for (index, textBox) in textBoxes.prefix(3).enumerated() {
                             print("   [\(index)] '\(textBox.text)' time: \(textBox.timeRange)")
                         }
                         textEditor.textBoxes = textBoxes
                         print("DEBUG: Updated textEditor.textBoxes to \(textEditor.textBoxes.count) items")
                     }
                     
                     // Set callback for auto-starting video after subtitle generation
                     editorVM.onSubtitlesGenerated = {
                         print("🎬 [MainEditorView] Subtitles generated, auto-starting video")
                         // Add a small delay to ensure everything is loaded
                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                             if let video = editorVM.currentVideo {
                                 videoPlayer.action(video)
                             }
                         }
                     }

                }
                // Update video player height when video player size changes
                .onChange(of: editorVM.videoPlayerSize) { _ in
                    let headerHeight = 50 + proxy.safeAreaInsets.top + 40 + 20 // header height + safe area + top padding + bottom padding
                    videoPlayerHeight = editorVM.calculateVideoPlayerHeight(for: editorVM.videoPlayerSize, screenHeight: proxy.size.height, headerHeight: headerHeight)
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
                        editorVM.videoPlayerSize = .quarter
                    } else {
                        // When bottom sheet closes, restore to half size
                        editorVM.videoPlayerSize = .half
                    }
                }
                // Update video player height when edit mode changes
                .onChange(of: showEditSubtitlesMode) { newValue in
                    if newValue {
                        // When edit mode is activated, set to half size
                        editorVM.videoPlayerSize = .half
                    }
                }
            }
            
            // export view
            if showVideoQualitySheet, let video = editorVM.currentVideo{
                VideoExporterBottomSheetView(isPresented: $showVideoQualitySheet, video: video)
            }

            // Enhanced loading overlay for subtitle generation
            if editorVM.isLoading {
                SubtitleGenerationLoader()
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .animation(.easeInOut(duration: 0.3), value: editorVM.isLoading)
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
            
            // Presets bottom sheet
            if showPresetsBottomSheet {
                VStack(spacing: 0) {
                    Spacer()
                    PresetsListView(
                        isPresented: $showPresetsBottomSheet,
                        pendingPreset: $pendingPreset,
                        onSelect: { style in
                            print("DEBUG: Preset selected: \(style.name)")
                            pendingPreset = style
                            showPresetConfirm = true
                        },
                        currentTextBox: textEditor.selectedTextBox ?? textEditor.textBoxes.first,
                        allTextBoxes: textEditor.textBoxes,
                        currentTime: videoPlayer.currentTime
                    )
                    .frame(maxWidth: .infinity, maxHeight: availableHeightExcludingPlayer) // Dynamic height based on available space
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2000)
                    .animation(.easeInOut(duration: 0.5), value: showPresetsBottomSheet)
                }
            }
            
            // Language picker sheet
            if editorVM.showLanguagePicker {
                LanguagePickerSheet(
                    isPresented: $editorVM.showLanguagePicker,
                    onLanguageSelected: { language in
                        editorVM.onLanguageSelected(language)
                    },
                    hasExistingSubtitles: editorVM.hasExistingSubtitles,
                    isFromNewProject: editorVM.isLanguagePickerFromNewProject
                )
                .zIndex(2500)
            }
                        
            // Centered cross overlay
            if showCrossOverlay {
                CrossOverlayView()
                    .zIndex(1500)
            }
    
            
            // Style Editor View as overlay
            if textEditor.selectedStyleOptionToEdit != nil {
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        StyleEditorView(
                            textEditor: textEditor,
                            selectedStyleOptionToEdit: $textEditor.selectedStyleOptionToEdit
                        )
                        .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.5)
                        //.background(Color.blue.opacity(0.5))
                        .zIndex(3000)
                        .offset(y: styleSheetOffset)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: styleSheetOffset)
                        .onAppear {
                            styleSheetOffset = 0
                        }
                        .onDisappear {
                            styleSheetOffset = 1000
                        }
                    }
                }
            }

        }
        .background(Color.black)
        .navigationBarHidden(true)

        .confirmationDialog("Are you sure?", isPresented: $showBackConfirmation) {
            Button("Yes", role: .destructive) {
                editorVM.updateProject()
                videoPlayer.unloadVideo()
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                // Do nothing, just dismiss the dialog
            }
        } message: {
            Text("Are you sure you want to exit this project?")
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
        .onDisappear {
            // Unload video player to free memory when exiting the view
            videoPlayer.unloadVideo()
        }
        .blur(radius: textEditor.showEditor && !textEditor.showEditTextContent ? 10 : 0)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay {
            if textEditor.showEditor && !textEditor.showEditTextContent {
                TextEditorView(viewModel: textEditor, onSave: editorVM.setText)
            }
        }
    }
    
    // Helper functions for preset handling
    private func isKaraokePreset(_ style: SubtitleStyle) -> Bool {
        return style.name == "Highlight by word" || 
               style.name == "Background by word"
    }
    
    private func getKaraokeType(for style: SubtitleStyle) -> KaraokeType {
        switch style.name {
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
                showBackConfirmation = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "door.left.hand.open")
                    Text("Exit")
                        .font(.caption2)
                }
                .padding(.top, 8)
                .padding(.leading, 8)
            }

            Spacer()
            
            // Center buttons container
            HStack(spacing: 20) {
                
                #if DEBUG
                    // Video player size toggle button
                    Button {
                        // Cycle through video player sizes (excluding custom)
                        let cycleSizes: [VideoPlayerSize] = [.quarter, .half, .threeQuarters, .full]
                        if let currentIndex = cycleSizes.firstIndex(of: editorVM.videoPlayerSize) {
                            let nextIndex = (currentIndex + 1) % cycleSizes.count
                            editorVM.videoPlayerSize = cycleSizes[nextIndex]
                        } else {
                            // If current size is custom, go to half
                            editorVM.videoPlayerSize = .half
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: editorVM.videoPlayerSize.iconName)
                            Text(editorVM.videoPlayerSize.displayName)
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(editorVM.videoPlayerSize == .custom ? .green : .white)
                    
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

                    Button {

                        let processedTextBoxes = processTextBoxesForLayout(
                            subs: editorVM.currentVideo?.textBoxes ?? [],
                            editorVM: editorVM,
                            joiner: " ",
                            targetCPS: 15,
                            minDur: 0.5,
                            maxDur: 4.5,
                            gap: 0.08,
                            expandShortCues: false
                        )

                        // Update the video with the processed text boxes
                        editorVM.setText(processedTextBoxes)

                        
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "rectangle.3.offgrid")
                            Text("Layout")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.white)

                #endif
                
                // Saving indicator
                if isSaving {
                    VStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Saving")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                }
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
    
    private func centerSection() -> some View {

        VStack(spacing: 0) {

            // PlayerControl section - always present but conditionally visible
            if !showEditSubtitlesMode, !showPresetsBottomSheet {
                PlayerControl(recorderManager: audioRecorder, editorVM: editorVM, videoPlayer: videoPlayer, textEditor: textEditor)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.3), value: showEditSubtitlesMode)
                Spacer()
            }

            // Edit subtitles mode section
            if let video = editorVM.currentVideo, showEditSubtitlesMode {

                // Show word timeline only when in edit subtitles mode
                VStack(spacing: 0) {
                    
                    // Top row with time/duration on the left and close button on the right
                    if !textEditor.showEditTextContent && editorVM.showWordTimeline {
                        ZStack {
                            
                            HStack {
                                // Time / Duration on the left with fixed width
                                if let video = editorVM.currentVideo {
                                    HStack(spacing: 2) {
                                        Text("\((videoPlayer.currentTime - video.rangeDuration.lowerBound).formatterTimeString())")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(width: 35, alignment: .trailing)
                                        
                                        Text("/")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Text("\(video.totalDuration.formatterTimeString())")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(width: 35, alignment: .leading)
                                    }
                                    .padding(.top, 8)

                                }
                                
                                Spacer()
                                
                                // Close button on the right
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showEditSubtitlesMode = false
                                        textEditor.selectedTextBox = nil
                                        textEditor.cancelTextEditor()
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.3), in: Circle())
                                }
                                .padding(.top, 8)
                                .padding(.trailing, 8)
                            }
                            
                            // Play/Pause button positioned after time (fixed position)
                            if let video = editorVM.currentVideo {
                                HStack {
                                    Spacer()
                                        .frame(width: 80) // Fixed space for time
                                    
                                    Button {
                                        videoPlayer.action(video)
                                    } label: {
                                        Image(systemName: videoPlayer.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.top, 8)
                                    
                                    Spacer()
                                }
                            }
                            
                            // "Edit Mode" text absolutely centered with better styling
                            Text("(Edit Mode)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.85))
                                .padding(.top, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.7))
                                )


                        }
                        .frame(height: 40)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if !textEditor.showEditTextContent && editorVM.showWordTimeline {
                        ZStack {
                            
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
                                        tickHeight: 80, 
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
                                    .frame(maxHeight: CGFloat.infinity)
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
                                },
                                onTextBoxUpdate: { updatedTextBox in
                                    // Update the text box in the text editor view model
                                    if let index = textEditor.textBoxes.firstIndex(where: { $0.id == updatedTextBox.id }) {
                                        textEditor.textBoxes[index] = updatedTextBox
                                        print("📝 Text editor - updated text box '\(updatedTextBox.text)' with time range: \(updatedTextBox.timeRange)")
                                        
                                        // Call onSave to update the main video model through the editor view model
                                        textEditor.onSave?(textEditor.textBoxes)
                                    }
                                }
                            )
                        }
                        .frame(height: 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if textEditor.showEditor {
                        TextEditorView(viewModel: textEditor, onSave: editorVM.setText)
                    }
                    
                    // Toolbar at the bottom
                    TextToolbar(
                        textEditor: textEditor, 
                        videoPlayerSize: $editorVM.videoPlayerSize, 
                        showWordTimeline: $editorVM.showWordTimeline,
                        onSeek: { time in
                            videoPlayer.seekToTime(time)
                        },
                        currentTime: videoPlayer.currentTime
                    )
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.3), value: showEditSubtitlesMode)
                // Disable the editor when the style editor is open
                .disabled(textEditor.selectedStyleOptionToEdit != nil)
                .overlay {
                    if textEditor.selectedStyleOptionToEdit != nil {
                        Rectangle()
                            .fill(Color.black.opacity(0.6))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                            .zIndex(10)
                            .onTapGesture {
                                textEditor.selectedStyleOptionToEdit = nil
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
    
    // MARK: - Subscription Upgrade Sheet
    

}