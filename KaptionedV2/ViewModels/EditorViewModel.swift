import Foundation
import AVKit
import SwiftUI
import Photos
import Combine

class EditorViewModel: ObservableObject{
    
    @Published var currentVideo: Video?


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
        
        let videoWidth = naturalSize.width
        let videoHeight = naturalSize.height
        
        // Calculate aspect ratio and fit within container
        let aspectRatio = videoWidth / videoHeight
        var renderedWidth = containerWidth
        var renderedHeight = containerWidth / aspectRatio
        
        // If height exceeds container, scale down
        if renderedHeight > containerHeight {
            renderedHeight = containerHeight
            renderedWidth = containerHeight * aspectRatio
        }
        

        
        // Center the video in the container
        let x = (containerWidth - renderedWidth) / 2
        let y = (containerHeight - renderedHeight) / 2
        
        return CGRect(x: x, y: y, width: renderedWidth, height: renderedHeight)
    }

    func setNewVideo(_ url: URL, geo: GeometryProxy){
        currentVideo = .init(url: url)
        createProject()
        
        // Automatically generate subtitles for new videos
        generateSubtitlesAutomatically()
    }
    
    func setProject(_ project: ProjectEntity, geo: GeometryProxy){
        projectEntity = project
        
        guard let url = project.videoURL else {return}
        
        currentVideo = .init(url: url)
        currentVideo?.toolsApplied = project.wrappedTools
        currentVideo?.textBoxes = project.wrappedTextBoxes


        //debugPrintTextBoxes()
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
    
    

    
    
    func setText(_ textBox: [TextBox]){
        currentVideo?.textBoxes = textBox
        // Trigger saving indicator and update project
        onSaving?()
        updateProject()
        // Notify the TextEditorViewModel about the updated text boxes
        onTextBoxesUpdated?(textBox)
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
                    
                    // Check if text layout optimization is enabled via remote config
                    let finalTextBoxes: [TextBox]
                    if ConfigurationManager.shared.isTextLayoutOptimizationEnabled() {
                        // Optimize all subtitles at once
                        finalTextBoxes = processTextBoxesForLayout(
                            subs: subs,
                            editorVM: self,
                            joiner: " ",
                            targetCPS: 15,
                            minDur: 0.1,
                            maxDur: 4.5,
                            gap: 0.01,
                            expandShortCues: false
                        )
                        print("🎬 [EditorViewModel] Text layout optimization applied")
                    } else {
                        // Use subtitles as-is without optimization
                        finalTextBoxes = subs
                        print("🎬 [EditorViewModel] Text layout optimization disabled, using raw subtitles")
                    }
                    
                    // Update the text boxes - this will automatically save to the project
                    self.setText(finalTextBoxes)
                    
                    // Notify the TextEditorViewModel about the new text boxes
                    self.onTextBoxesUpdated?(finalTextBoxes)
                    
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


