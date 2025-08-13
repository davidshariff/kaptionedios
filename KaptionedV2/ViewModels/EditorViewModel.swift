import Foundation
import AVKit
import SwiftUI
import Photos
import Combine

class EditorViewModel: ObservableObject{
    
    @Published var currentVideo: Video?
    @Published var selectedTools: ToolEnum?
    @Published var frames = VideoFrames()
    @Published var isSelectVideo: Bool = true
    
    @Published var isLoading: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    
    @Published var showLanguagePicker: Bool = false
    @Published var isLanguagePickerFromNewProject: Bool = false

    // Now using RevenueCat paywall directly
    
    /// Check if the current video has existing subtitles
    var hasExistingSubtitles: Bool {
        return currentVideo?.textBoxes.isEmpty == false
    }
    
    @Published var videoPlayerSize: VideoPlayerSize = .half
    @Published var showWordTimeline: Bool = true
    
    var onSaving: (() -> Void)?
    var onTextBoxesUpdated: (([TextBox]) -> Void)?
    var onSubtitlesGenerated: (() -> Void)?
    var maxWordsPerLine: Int {
        return ConfigurationManager.shared.getDefaultMaxWordsPerLine()
    }
    
    private var projectEntity: ProjectEntity?
    
    // Function to calculate video player height based on size and screen dimensions
    func calculateVideoPlayerHeight(for size: VideoPlayerSize, screenHeight: CGFloat, headerHeight: CGFloat = 0) -> CGFloat {
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
    
    /// Returns the actual rendered rect of the video on screen
    /// Takes into account the current video player size, aspect ratio, rotation, and scaling
    var videoRect: CGRect {
        guard let video = currentVideo else {
            return .zero
        }
        
        // Get the video's natural size
        let naturalSize = video.frameSize
        guard naturalSize.width > 0 && naturalSize.height > 0 else {
            return .zero
        }
        
        // Get screen dimensions
        let screenBounds = UIScreen.main.bounds
        let screenWidth = screenBounds.width
        let screenHeight = screenBounds.height
        let headerHeight: CGFloat = 140 // Approximate header height
        
        // Calculate the container height based on current videoPlayerSize
        let containerHeight = calculateVideoPlayerHeight(for: videoPlayerSize, screenHeight: screenHeight, headerHeight: headerHeight)
        let containerWidth = screenWidth
        
        // Account for rotation - swap dimensions if rotated 90° or 270°
        let isRotated = Int(video.rotation) % 180 != 0
        let videoWidth = isRotated ? naturalSize.height : naturalSize.width
        let videoHeight = isRotated ? naturalSize.width : naturalSize.height
        
        // Calculate aspect ratio and fit within container
        let aspectRatio = videoWidth / videoHeight
        var renderedWidth = containerWidth
        var renderedHeight = containerWidth / aspectRatio
        
        // If height exceeds container, scale down
        if renderedHeight > containerHeight {
            renderedHeight = containerHeight
            renderedWidth = containerHeight * aspectRatio
        }
        
        // Apply video frames scaling if active
        if let frames = video.videoFrames, frames.isActive {
            let scale = frames.scale
            renderedWidth *= scale
            renderedHeight *= scale
        }
        
        // Center the video in the container
        let x = (containerWidth - renderedWidth) / 2
        let y = (containerHeight - renderedHeight) / 2
        
        return CGRect(x: x, y: y, width: renderedWidth, height: renderedHeight)
    }

    func setNewVideo(_ url: URL, geo: GeometryProxy){
        currentVideo = .init(url: url)
        currentVideo?.updateThumbnails(geo)
        createProject()
        
        // Automatically generate subtitles for new videos
        generateSubtitlesAutomatically()
    }
    
    func setProject(_ project: ProjectEntity, geo: GeometryProxy){
        projectEntity = project
        
        guard let url = project.videoURL else {return}
        
        currentVideo = .init(url: url, rangeDuration: project.lowerBound...project.upperBound, rate: Float(project.rate), rotation: project.rotation)
        currentVideo?.toolsApplied = project.wrappedTools
        currentVideo?.filterName = project.filterName
        currentVideo?.colorCorrection = .init(brightness: project.brightness, contrast: project.contrast, saturation: project.saturation)
        let frame = VideoFrames(scaleValue: project.frameScale, frameColor: project.wrappedColor)
        currentVideo?.videoFrames = frame
        self.frames = frame
        currentVideo?.updateThumbnails(geo)
        currentVideo?.textBoxes = project.wrappedTextBoxes
        if let audio = project.audio?.audioModel{
            currentVideo?.audio = audio
        }
        debugPrintTextBoxes()
    }

    func debugPrintTextBoxes(){
        if let boxes = currentVideo?.textBoxes, !boxes.isEmpty {
            print("[DEBUG] Project loaded with pre-existing textBoxes:")
            for box in boxes {
                print("   '\(box.text)'")
            }
        }
    }
        
}

//MARK: - Core data logic
extension EditorViewModel{
    
    private func createProject(){
        guard let currentVideo else { return }
        let context = PersistenceController.shared.viewContext
        projectEntity = ProjectEntity.create(video: currentVideo, context: context)
    }
    
    func updateProject(){
        guard let projectEntity, let currentVideo else { return }
        ProjectEntity.update(for: currentVideo, project: projectEntity)
    }
}

//MARK: - Tools logic
extension EditorViewModel{
    
    
    func setFilter(_ filter: String?){
        currentVideo?.setFilter(filter)
        if filter != nil{
            setTools()
        }else{
            removeTool()
        }
    }
    
    
    func setText(_ textBox: [TextBox]){
        print("DEBUG: setText called with \(textBox.count) text boxes")
        currentVideo?.textBoxes = textBox
        setTools()
        // Trigger saving indicator and update project
        print("DEBUG: Calling onSaving callback")
        onSaving?()
        print("DEBUG: Calling updateProject")
        updateProject()
        // Notify the TextEditorViewModel about the updated text boxes
        print("DEBUG: Calling onTextBoxesUpdated callback")
        onTextBoxesUpdated?(textBox)
    }
    
    func setFrames(){
        currentVideo?.videoFrames = frames
        setTools()
    }
    
    func setCorrections(_ correction: ColorCorrection){
        currentVideo?.colorCorrection = correction
        setTools()
    }
    
    func updateRate(rate: Float){
        currentVideo?.updateRate(rate)
        setTools()
    }
    
    func rotate(){
        currentVideo?.rotate()
        setTools()
    }
    
    func toggleMirror(){
        currentVideo?.isMirror.toggle()
        setTools()
    }
    
    func setAudio(_ audio: Audio){
        currentVideo?.audio = audio
        setTools()
    }
    
    func setTools(){
        guard let selectedTools else { return }
        currentVideo?.appliedTool(for: selectedTools)
    }
    
    func removeTool(){
        guard let selectedTools else { return }
        self.currentVideo?.removeTool(for: selectedTools)
    }
    
    func removeAudio(){
        guard let url = currentVideo?.audio?.url else {return}
        FileManager.default.removefileExists(for: url)
        currentVideo?.audio = nil
        isSelectVideo = true
        removeTool()
        updateProject()
    }
  
    func reset(){
        guard let selectedTools else {return}
       
        switch selectedTools{
            
        case .subslist:
            currentVideo?.resetRangeDuration()
        case .presets:
            break
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            self.removeTool()
        }
    }
    
    /// Generates subtitles for the current video
    /// This method can be used both for manual generation (via Generate button) and automatic generation (for new videos)
    /// - Parameter showConfirmation: Whether to show a confirmation dialog before generating
    /// - Parameter completion: Optional completion handler called after generation completes
    func generateSubtitles(showConfirmation: Bool = false, completion: (() -> Void)? = nil) {
        guard let video = currentVideo else { 
            completion?()
            return 
        }
        
        // Show language picker for manual generation
        if showConfirmation {
            isLanguagePickerFromNewProject = false
            showLanguagePicker = true
        } else {
            // Direct generation for automatic subtitle generation (use default language from config)
            performSubtitleGeneration(language: ConfigurationManager.shared.getDefaultLanguage(), completion: completion)
        }
    }
    
    /// Performs the actual subtitle generation with the selected language
    /// - Parameter language: The language code for transcription
    /// - Parameter completion: Optional completion handler called after generation completes
    private func performSubtitleGeneration(language: String, completion: (() -> Void)? = nil) {
        guard let video = currentVideo else { 
            completion?()
            return 
        }
        
        print("🎬 [EditorViewModel] Starting subtitle generation with language: \(language)")
        
        self.isLoading = true
        TranscriptionHelper.shared.transcribeVideo(fileURL: video.url, language: language, max_words_per_line: maxWordsPerLine) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isLoading = false
                switch result {
                case .success(let subs):
                    print("🎬 [EditorViewModel] Transcription completed with \(subs.count) subtitle segments")
                    
                    // Optimize all subtitles at once
                    let optimizedTextBoxes = processTextBoxesForLayout(
                        subs: subs,
                        editorVM: self,
                        joiner: " ",
                        targetCPS: 15,
                        minDur: 0.5,
                        maxDur: 4.5,
                        gap: 0.08,
                        expandShortCues: false
                    )

                    // INSERT_YOUR_CODE
                    if let firstTextBox = optimizedTextBoxes.first {
                        print("First optimizedTextBox font size: \(firstTextBox.fontSize)")
                    }
                    
                    // Update the text boxes - this will automatically save to the project
                    self.setText(optimizedTextBoxes)
                    
                    // Notify the TextEditorViewModel about the new text boxes
                    self.onTextBoxesUpdated?(optimizedTextBoxes)
                    
                    // Notify that subtitles have been generated
                    self.onSubtitlesGenerated?()
                    
                    // Record video creation when subtitles are successfully generated
                    Task { @MainActor in
                        SubscriptionManager.shared.recordVideoCreation()
                    }
                    
                    completion?()
                    
                case .failure(let error):
                    print("❌ [EditorViewModel] Transcription failed: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate subtitles: \(error.localizedDescription)"
                    self.showErrorAlert = true
                    completion?()
                }
            }
        }
    }
    
    /// Called when a language is selected from the language picker
    /// - Parameter language: The selected language code
    func onLanguageSelected(_ language: String) {
        performSubtitleGeneration(language: language == "zh-TW" ? "zh" : language)
    }
    
    /// Automatically generates subtitles for new videos - shows language picker
    func generateSubtitlesAutomatically() {
        isLanguagePickerFromNewProject = true
        showLanguagePicker = true
    }
}


