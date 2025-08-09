//
//  ExporterViewModel.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 24.04.2023.
//

import Foundation
import Combine
import Photos
import UIKit
import SwiftUI


class ExporterViewModel: ObservableObject{
    
    var video: Video
    /// Closure to provide the latest textBoxes before export
    var syncTextBoxes: (() -> [TextBox])?
    
    @Published var renderState: ExportState = .unknown
    @Published var showAlert: Bool = false
    @Published var progressTimer: TimeInterval = .zero
    @Published var selectedQuality: VideoQuality = .medium
    @Published var currentStage: ExportStage = .preparing
    @Published var overallProgress: Double = 0.0
    private var cancellable = Set<AnyCancellable>()
    private var action: ActionEnum = .save
    private let editorHelper = VideoEditor()
    private var timer: Timer?
    
    init(video: Video){
        self.video = video
        startRenderStateSubs()
    }
    
    
    deinit{
        cancellable.forEach({$0.cancel()})
        resetTimer()
    }
    
    
    @MainActor
    private func renderVideo() async{
        renderState = .loading
        currentStage = .preparing
        overallProgress = 0.0
        
        // Defensive: sync latest textBoxes from UI if available
        if let latest = syncTextBoxes?() {
            video.textBoxes = latest
        }
        
        do{
            let url = try await editorHelper.startRender(
                video: video, 
                videoQuality: selectedQuality,
                progressCallback: { [weak self] stage, progress in
                    await self?.handleProgressUpdate(stage: stage, progress: progress)
                }
            )
            
            await updateStage(.completed, progress: 1.0)
            renderState = .loaded(url)
        }catch{
            renderState = .failed(error)
        }
    }
    
    @MainActor
    private func updateStage(_ stage: ExportStage, progress: Double) {
        currentStage = stage
        overallProgress = progress
    }
    
    @MainActor
    private func handleProgressUpdate(stage: String, progress: Double) {
        // Convert string stage to ExportStage
        let exportStage: ExportStage
        switch stage {
        case "processing":
            exportStage = .firstPass  // Use firstPass stage for processing
        case "completed":
            exportStage = .completed
        default:
            exportStage = .preparing
        }
        
        currentStage = exportStage
        
        // Simplified single-pass progress mapping (0-100%)
        let newProgress: Double
        
        switch exportStage {
        case .preparing:
            newProgress = 0.0
        case .firstPass:  // This is our main processing stage
            newProgress = 0.05 + (progress * 0.90)  // 5-95% (main export work)
        case .secondPass:
            newProgress = 0.95  // Not used anymore
        case .saving:
            newProgress = 0.95 + (progress * 0.05)  // 95-100%
        case .completed:
            newProgress = 1.0
        }
        
        // Apply progress directly for more accuracy
        overallProgress = newProgress
        
        print("📊 [ExporterVM] Stage: \(stage), Progress: \(Int(progress * 100))%, Overall: \(Int(overallProgress * 100))%")
    }
    

    
    @MainActor
    private func updateStageProgress(_ stage: ExportStage, progress: Double) {
        currentStage = stage
        overallProgress = progress
    }
    
    
   
    func action(_ action: ActionEnum) async{
        self.action = action
        await renderVideo()
    }

  private func startRenderStateSubs(){
        $renderState
            .sink {[weak self] state in
                guard let self = self else {return}
                switch state {
                case .loading:
                    self.startProgressTimer()
                case .loaded(let url):
                    if self.action == .save{
                        self.currentStage = .saving
                        self.overallProgress = 0.9
                        self.saveVideoInLib(url)
                    }else{
                        self.showShareSheet(data: url)
                    }
                    self.resetTimer()
                default:
                    break
                }
            }
            .store(in: &cancellable)
    }
    
    private func startProgressTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.progressTimer += 0.1
        }
    }
    
    
    private func resetTimer(){
        timer?.invalidate()
        timer = nil
        progressTimer = .zero
        currentStage = .preparing
        overallProgress = 0.0
    }
    
    private func showShareSheet(data: Any){
        DispatchQueue.main.async {
            self.renderState = .unknown
        }
        UIActivityViewController(activityItems: [data], applicationActivities: nil).presentInKeyWindow()
    }
    
    private func saveVideoInLib(_ url: URL){
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) {[weak self] saved, error in
            guard let self = self else {return}
            if saved {
                DispatchQueue.main.async {
                    self.renderState = .saved
                }
            }
        }
    }
    
    enum ActionEnum: Int{
        case save, share
    }
    
    
    
    enum ExportState: Identifiable, Equatable {
        
        case unknown, loading, loaded(URL), failed(Error), saved
        
        var id: Int{
            switch self {
            case .unknown: return 0
            case .loading: return 1
            case .loaded: return 2
            case .failed: return 3
            case .saved: return 4
            }
        }
        
        static func == (lhs: ExporterViewModel.ExportState, rhs: ExporterViewModel.ExportState) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    enum ExportStage: String, CaseIterable {
        case preparing = "Preparing..."
        case firstPass = "Processing Video"
        case secondPass = "Applying Filters"  // Keep for UI compatibility but not used
        case saving = "Saving..."
        case completed = "Complete"
        
        var description: String {
            switch self {
            case .preparing:
                return "Getting everything ready"
            case .firstPass:
                return "Compositing video with text overlays and effects"
            case .secondPass:
                return "Applying color filters and effects"  // Not used
            case .saving:
                return "Finalizing and saving video"
            case .completed:
                return "Export complete!"
            }
        }
        
        var icon: String {
            switch self {
            case .preparing:
                return "gear"
            case .firstPass:
                return "text.badge.plus"
            case .secondPass:
                return "camera.filters"
            case .saving:
                return "square.and.arrow.down"
            case .completed:
                return "checkmark.circle"
            }
        }
    }
    
}
