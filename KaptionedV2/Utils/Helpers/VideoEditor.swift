//
//  VideoEditor.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 22.04.2023.
//

import Foundation
import AVFoundation
import UIKit
import Combine

class VideoEditor{
    
    @Published var currentTimePublisher: TimeInterval = 0.0
    
    // Progress callback type - using String instead of ExportStage to avoid circular import
    typealias ProgressCallback = @MainActor (String, Double) async -> Void
    
    ///The renderer is made up of half-sequential operations:
    func startRender(video: Video, videoQuality: VideoQuality, progressCallback: ProgressCallback? = nil) async throws -> URL{
        print("🚀 [VideoEditor] startRender called – quality: \(videoQuality)  resolution: \(videoQuality.size)")
        do{
            await progressCallback?("processing", 0.0)
            let url = try await resizeAndLayerOperation(video: video, videoQuality: videoQuality, progressCallback: progressCallback)
            await progressCallback?("completed", 1.0)
            print("✅ [VideoEditor] Finished render – output: \(url)")
            return url
        }catch{
            print("🛑 [VideoEditor] Render failed: \(error)")
            throw error
        }
    }
    
    
    ///Cut, resizing, rotate and set quality
    private func resizeAndLayerOperation(video: Video,
                                  videoQuality: VideoQuality,
                                  progressCallback: ProgressCallback? = nil) async throws -> URL{
        
        // Calculate complexity for progress estimation
        let textLayerCount = video.textBoxes.count
        let hasComplexText = video.textBoxes.contains { $0.wordTimings != nil }
        let estimatedComplexity = textLayerCount + (hasComplexText ? 5 : 0)
        
        print("📊 [VideoEditor] Export complexity: \(textLayerCount) text layers, complex: \(hasComplexText)")
        
        // Phase 1: Setup composition (0-10%)
        await progressCallback?("processing", 0.0)
        let composition = AVMutableComposition()
        
        let timeRange = getTimeRange(for: video.originalDuration, with: video.rangeDuration)
        let asset = video.asset
        await progressCallback?("processing", 0.05)
        
        ///Set new timeScale
        try await setTimeScaleAndAddTracks(to: composition, from: asset, audio: video.audio, timeScale: Float64(video.rate), videoVolume: video.volume)
        await progressCallback?("processing", 0.10)
        
        ///Get new timeScale video track
        guard let videoTrack = try await composition.loadTracks(withMediaType: .video).first else {
            throw ExporterError.unknow
        }
        
        // Phase 2: Video preparation (10-20%)
        ///Prepair new video size
        let naturalSize = videoTrack.naturalSize
        let videoTrackPreferredTransform = try await videoTrack.load(.preferredTransform)
        let outputSize = getSizeFromOrientation(newSize: videoQuality.size, videoTrackPreferredTransform: videoTrackPreferredTransform)
        await progressCallback?("processing", 0.15)
        
        ///Create layerInstructions and set new size, scale, mirror
        let layerInstruction = videoCompositionInstructionForTrackWithSizeAndTime(
            preferredTransform: videoTrackPreferredTransform,
            naturalSize: naturalSize,
            newSize: outputSize,
            track: videoTrack,
            scale: video.videoFrames?.scale ?? 1,
            isMirror: video.isMirror
        )
        await progressCallback?("processing", 0.20)
        
        // Phase 3: Video composition setup (20-30%)
        ///Create mutable video composition
        let videoComposition = AVMutableVideoComposition()
        ///Set rander video  size
        videoComposition.renderSize = outputSize
        ///Set frame duration 30fps
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        await progressCallback?("processing", 0.25)
        
        // Phase 4: Create text layers (30-50%) - progress based on complexity
        ///Create background layer color and scale video
        await progressCallback?("processing", 0.30)
        let overlayTrackID = await createLayersWithProgress(video.videoFrames, video: video, size: outputSize, videoComposition: videoComposition, progressCallback: progressCallback, startProgress: 0.30, endProgress: 0.50)
        
        // Phase 5: Final composition setup (50-60%)
        ///Set Video Composition Instruction
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        if let overlayID = overlayTrackID {
            let overlayInstruction = AVMutableVideoCompositionLayerInstruction()
            overlayInstruction.trackID = overlayID
            instruction.layerInstructions = [overlayInstruction, layerInstruction]
        } else {
            instruction.layerInstructions = [layerInstruction]
        }
        
        ///Set instruction in videoComposition
        videoComposition.instructions = [instruction]
        await progressCallback?("processing", 0.60)
        
        // Phase 6: Export session (60-100%)
        ///Create file path in temp directory
        let outputURL = createTempPath()
        
        ///Create exportSession
        let session = try exportSession(composition: composition, videoComposition: videoComposition, outputURL: outputURL, timeRange: timeRange)
        print("⏳ [VideoEditor] Starting video export (resize/compose/text) to \(outputURL.path)")
        
        // Monitor progress for export (60-100%)
        await withTaskGroup(of: Void.self) { group in
            // Progress monitoring task
            group.addTask {
                await self.monitorExportProgressWithOffset(session: session, stage: "processing", progressCallback: progressCallback, startOffset: 0.60)
            }
            
            // Export task
            group.addTask {
                await session.export()
            }
        }
        
        if let error = session.error {
            print("🛑 [VideoEditor] Export error: \(error)")
            throw error
        } else {
            if let url = session.outputURL{
                print("✅ [VideoEditor] Export finished: \(url)")
                return url
            }
            throw ExporterError.failed
        }
    }
    

}

//MARK: - Helpers
extension VideoEditor{
    
    /// Monitor export session progress with offset for final export phase
    private func monitorExportProgressWithOffset(session: AVAssetExportSession, stage: String, progressCallback: ProgressCallback?, startOffset: Double) async {
        guard let progressCallback = progressCallback else { return }
        
        var lastReportedProgress: Float = -1
        var highestProgress: Double = 0.0  // Track highest progress to prevent backward jumps
        let progressRange = 1.0 - startOffset  // Remaining progress range
        var simulatedProgress: Double = 0.0
        var hasRealProgressStarted = false
        
        // Start monitoring immediately
        let startTime = CFAbsoluteTimeGetCurrent()
        
        while session.status == .waiting || session.status == .exporting {
            let currentProgress = session.progress
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            
            // Determine effective progress, ensuring it never goes backward
            let effectiveProgress: Double
            
            if currentProgress > 0.01 && !hasRealProgressStarted {
                // Real progress has started - transition smoothly from simulated
                hasRealProgressStarted = true
                effectiveProgress = max(Double(currentProgress), highestProgress)
            } else if hasRealProgressStarted {
                // Use real progress, but ensure it doesn't go backward
                effectiveProgress = max(Double(currentProgress), highestProgress)
            } else {
                // Still simulating - gradual progress up to 30%
                simulatedProgress = min(0.3, elapsedTime * 0.08) // Slower simulation
                effectiveProgress = max(simulatedProgress, highestProgress)
            }
            
            // Update highest progress to prevent backward movement
            if effectiveProgress > highestProgress {
                highestProgress = effectiveProgress
            }
            
            // Report progress more frequently for smoother updates
            if abs(Float(highestProgress) - lastReportedProgress) >= 0.005 { // 0.5% minimum change
                let adjustedProgress = startOffset + (highestProgress * progressRange)
                await progressCallback(stage, adjustedProgress)
                lastReportedProgress = Float(highestProgress)
                
                let progressType = hasRealProgressStarted ? "Real" : "Sim"
                print("🎬 [VideoEditor] Export progress (\(progressType)): \(Int(highestProgress * 100))% -> Overall: \(Int(adjustedProgress * 100))%")
            }
            
            // Update every 25ms for very smooth progress
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
        
        // Gradually complete the remaining progress
        let finalStartProgress = startOffset + (highestProgress * progressRange)
        await smoothProgressToCompletion(from: finalStartProgress, stage: stage, progressCallback: progressCallback)
    }
    
    /// Smoothly animate progress from current to 100%
    private func smoothProgressToCompletion(from startProgress: Double, stage: String, progressCallback: ProgressCallback?) async {
        guard let progressCallback = progressCallback else { return }
        
        let remainingProgress = 1.0 - startProgress
        let steps = 20 // Number of steps to reach 100%
        let stepSize = remainingProgress / Double(steps)
        
        for i in 1...steps {
            let progress = startProgress + (stepSize * Double(i))
            await progressCallback(stage, progress)
            print("🎬 [VideoEditor] Completing: \(Int(progress * 100))%")
            
            // Slower steps at the end for smooth completion
            let delay = i < steps ? 50_000_000 : 100_000_000 // 50ms or 100ms
            try? await Task.sleep(nanoseconds: UInt64(delay))
        }
        
        print("✅ [VideoEditor] Export stage '\(stage)' completed")
    }
    
    /// Monitor export session progress and call progress callback
    private func monitorExportProgress(session: AVAssetExportSession, stage: String, progressCallback: ProgressCallback?) async {
        guard let progressCallback = progressCallback else { return }
        
        var lastReportedProgress: Float = -1
        
        while session.status == .waiting || session.status == .exporting {
            let currentProgress = session.progress
            
            // Report progress more frequently for smoother updates
            if abs(currentProgress - lastReportedProgress) >= 0.005 { // 0.5% minimum change
                await progressCallback(stage, Double(currentProgress))
                lastReportedProgress = currentProgress
                print("🎬 [VideoEditor] Export progress: \(Int(currentProgress * 100))%")
            }
            
            // Update every 25ms for ultra-smooth progress
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
        
        // Ensure we report 100% completion for this stage
        if session.status == .completed {
            await progressCallback(stage, 1.0)
            print("✅ [VideoEditor] Export stage '\(stage)' completed")
        }
    }
    

    private func exportSession(composition: AVMutableComposition, videoComposition: AVMutableVideoComposition, outputURL: URL, timeRange: CMTimeRange) throws -> AVAssetExportSession {
        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            print("Cannot create export session.")
            throw ExporterError.cannotCreateExportSession
        }
        export.videoComposition = videoComposition
        export.outputFileType = .mp4
        export.outputURL = outputURL
        export.timeRange = timeRange
    
        return export
    }
    
    
    /// Create layers with progress tracking
    private func createLayersWithProgress(_ videoFrame: VideoFrames?, video: Video, size: CGSize, videoComposition: AVMutableVideoComposition, progressCallback: ProgressCallback?, startProgress: Double, endProgress: Double) async -> CMPersistentTrackID? {
        
        guard let videoFrame else { return nil }
        
        let color = videoFrame.frameColor
        let scale = videoFrame.scale
        let scaleSize = CGSize(width: size.width * scale, height: size.height * scale)
        let centerPoint = CGPoint(x: (size.width - scaleSize.width)/2, y: (size.height - scaleSize.height)/2)
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: centerPoint, size: scaleSize)
        let bgLayer = CALayer()
        bgLayer.frame = CGRect(origin: .zero, size: size)
        bgLayer.backgroundColor = UIColor(color).cgColor
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: size)
        
        let progressRange = endProgress - startProgress
        let textLayerCount = video.textBoxes.count
        
        #if targetEnvironment(simulator)
        // When using additionalLayer variant we must not obscure the underlying video track, so we do NOT add bgLayer or videoLayer here.
        if !video.textBoxes.isEmpty {
            for (index, text) in video.textBoxes.enumerated() {
                let layerProgress = startProgress + (Double(index) / Double(textLayerCount)) * progressRange
                await progressCallback?("processing", layerProgress)
                
                let position = convertSize(text.offset, fromFrame: video.geometrySize, toFrame: size)
                let textLayer = createTextLayer(with: text, size: size, position: position.size, ratio: position.ratio, duration: video.totalDuration)
                outputLayer.addSublayer(textLayer)
            }
        }
        #else
        // Device build keeps background/frame behaviour
        outputLayer.addSublayer(bgLayer)
        outputLayer.addSublayer(videoLayer)
        if !video.textBoxes.isEmpty{
            for (index, text) in video.textBoxes.enumerated() {
                let layerProgress = startProgress + (Double(index) / Double(textLayerCount)) * progressRange
                await progressCallback?("processing", layerProgress)
                
                let position = convertSize(text.offset, fromFrame: video.geometrySize, toFrame: size)
                let textLayer = createTextLayer(with: text, size: size, position: position.size, ratio: position.ratio, duration: video.totalDuration)
                outputLayer.addSublayer(textLayer)
            }
        }
        #endif

        #if targetEnvironment(simulator)
        // Work-around simulator crash: use additionalLayer variant. We need to supply a unique trackID and add a matching layer instruction later.
        let overlayTrackID: CMPersistentTrackID = CMPersistentTrackID(videoComposition.sourceTrackIDForFrameTiming == kCMPersistentTrackID_Invalid ? 1 : videoComposition.sourceTrackIDForFrameTiming + 1)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            additionalLayer: outputLayer,
            asTrackID: overlayTrackID)
        return overlayTrackID
        #else
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: outputLayer)
        return nil
        #endif
    }

    @discardableResult
    private func createLayers(_ videoFrame: VideoFrames?, video: Video, size: CGSize, videoComposition: AVMutableVideoComposition) -> CMPersistentTrackID?{
        
        guard let videoFrame else {return nil}
        
        let color = videoFrame.frameColor
        let scale = videoFrame.scale
        let scaleSize = CGSize(width: size.width * scale, height: size.height * scale)
        let centerPoint = CGPoint(x: (size.width - scaleSize.width)/2, y: (size.height - scaleSize.height)/2)
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: centerPoint, size: scaleSize)
        let bgLayer = CALayer()
        bgLayer.frame = CGRect(origin: .zero, size: size)
        bgLayer.backgroundColor = UIColor(color).cgColor
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: size)
        
        
        
        #if targetEnvironment(simulator)
        // When using additionalLayer variant we must not obscure the underlying video track, so we do NOT add bgLayer or videoLayer here.
        if !video.textBoxes.isEmpty {
            video.textBoxes.forEach { text in
                let position = convertSize(text.offset, fromFrame: video.geometrySize, toFrame: size)
                let textLayer = createTextLayer(with: text, size: size, position: position.size, ratio: position.ratio, duration: video.totalDuration)
                outputLayer.addSublayer(textLayer)
            }
        }
        #else
        // Device build keeps background/frame behaviour
        outputLayer.addSublayer(bgLayer)
        outputLayer.addSublayer(videoLayer)
        if !video.textBoxes.isEmpty{
            video.textBoxes.forEach { text in
                let position = convertSize(text.offset, fromFrame: video.geometrySize, toFrame: size)
                let textLayer = createTextLayer(with: text, size: size, position: position.size, ratio: position.ratio, duration: video.totalDuration)
                outputLayer.addSublayer(textLayer)
            }
        }
        #endif

        #if targetEnvironment(simulator)
        // Work-around simulator crash: use additionalLayer variant. We need to supply a unique trackID and add a matching layer instruction later.
        let overlayTrackID: CMPersistentTrackID = CMPersistentTrackID(videoComposition.sourceTrackIDForFrameTiming == kCMPersistentTrackID_Invalid ? 1 : videoComposition.sourceTrackIDForFrameTiming + 1)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            additionalLayer: outputLayer,
            asTrackID: overlayTrackID)
        return overlayTrackID
        #else
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: outputLayer)
        return nil
        #endif
    }
    
    ///Set new time scale for audio and video tracks
    private func setTimeScaleAndAddTracks(to composition: AVMutableComposition,
                                          from asset: AVAsset,
                                          audio: Audio?,
                                          timeScale: Float64,
                                          videoVolume: Float) async throws{
        
        let videoTracks =  try await asset.loadTracks(withMediaType: .video)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        
        let duration = try await asset.load(.duration)
        //TotalTimeRange
        let oldTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
        let destinationTimeRange = CMTimeMultiplyByFloat64(duration, multiplier:(1/timeScale))
        // set new time range in audio track
        if audioTracks.count > 0 {
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            compositionAudioTrack?.preferredVolume = videoVolume
            let audioTrack = audioTracks.first!
            try compositionAudioTrack?.insertTimeRange(oldTimeRange, of: audioTrack, at: CMTime.zero)
            compositionAudioTrack?.scaleTimeRange(oldTimeRange, toDuration: destinationTimeRange)
            
            let auduoPreferredTransform = try await audioTrack.load(.preferredTransform)
            compositionAudioTrack?.preferredTransform = auduoPreferredTransform
        }
        
        // set new time range in video track
        if videoTracks.count > 0 {
            let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            let videoTrack = videoTracks.first!
            try compositionVideoTrack?.insertTimeRange(oldTimeRange, of: videoTrack, at: CMTime.zero)
            compositionVideoTrack?.scaleTimeRange(oldTimeRange, toDuration: destinationTimeRange)
            
            let videoPreferredTransform = try await videoTrack.load(.preferredTransform)
            compositionVideoTrack?.preferredTransform = videoPreferredTransform
        }
        
        // Adding audio
        if let audio{
            let asset = AVAsset(url: audio.url)
            guard let secondAudioTrack = try await asset.loadTracks(withMediaType: .audio).first else { return }
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            compositionAudioTrack?.preferredVolume = audio.volume
            try compositionAudioTrack?.insertTimeRange(oldTimeRange, of: secondAudioTrack, at: CMTime.zero)
            compositionAudioTrack?.scaleTimeRange(oldTimeRange, toDuration: destinationTimeRange)
        }
    }
    
    ///create CMTimeRange
    private func getTimeRange(for duration: Double, with timeRange: ClosedRange<Double>) -> CMTimeRange {
        let start = timeRange.lowerBound.clamped(to: 0...duration)
        let end = timeRange.upperBound.clamped(to: start...duration)
        
        let startTime = CMTimeMakeWithSeconds(start, preferredTimescale: 1000)
        let endTime = CMTimeMakeWithSeconds(end, preferredTimescale: 1000)
        
        let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        return timeRange
    }
    
    
    ///set video size for AVMutableVideoCompositionLayerInstruction
    private func videoCompositionInstructionForTrackWithSizeAndTime(preferredTransform: CGAffineTransform, naturalSize: CGSize, newSize: CGSize,  track: AVAssetTrack, scale: Double, isMirror: Bool) -> AVMutableVideoCompositionLayerInstruction {
        
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetInfo = orientationFromTransform(preferredTransform)
        
        var aspectFillRatio:CGFloat = 1
        if naturalSize.height < naturalSize.width {
            aspectFillRatio = newSize.height / naturalSize.height
        }
        else {
            aspectFillRatio = newSize.width / naturalSize.width
        }
        
        let scaleFactor = CGAffineTransform(scaleX: aspectFillRatio, y: aspectFillRatio)
        
        if assetInfo.isPortrait {
           
            let posX = newSize.width/2 - (naturalSize.height * aspectFillRatio)/2
            let posY = newSize.height/2 - (naturalSize.width * aspectFillRatio)/2
            let moveFactor = CGAffineTransform(translationX: posX, y: posY)
            instruction.setTransform(preferredTransform.concatenating(scaleFactor).concatenating(moveFactor), at: .zero)
            
        } else {
            let posX = newSize.width/2 - (naturalSize.width * aspectFillRatio)/2
            let posY = newSize.height/2 - (naturalSize.height * aspectFillRatio)/2
            let moveFactor = CGAffineTransform(translationX: posX, y: posY)
            
            var concat = preferredTransform.concatenating(scaleFactor).concatenating(moveFactor)
            
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                concat = fixUpsideDown.concatenating(scaleFactor).concatenating(moveFactor)
                
            }
            instruction.setTransform(concat, at: .zero)
        }
        

        if isMirror {
            var transform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            transform = transform.translatedBy(x: -newSize.width, y: 0.0)
            instruction.setTransform(transform, at: .zero)
        }
        
        return instruction
    }
    
    
   private func getSizeFromOrientation(newSize: CGSize, videoTrackPreferredTransform: CGAffineTransform) -> CGSize{
        let orientation = self.orientationFromTransform(videoTrackPreferredTransform)
        
        var outputSize = newSize
        if !orientation.isPortrait{
            outputSize.width = newSize.height
            outputSize.height = newSize.width
        }
        print("OutputSize", outputSize)
        return outputSize
    }
    
    
    private func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    
    private func createTempPath() -> URL{
        let tempPath = "\(NSTemporaryDirectory())temp_video.mp4"
        let tempURL = URL(fileURLWithPath: tempPath)
        FileManager.default.removefileExists(for: tempURL)
        return tempURL
    }
    
    private func addImage(to layer: CALayer, watermark: UIImage, videoSize: CGSize) {
        let imageLayer = CALayer()
        let aspect: CGFloat = watermark.size.width / watermark.size.height
        let width = videoSize.width / 4
        let height = width / aspect
        imageLayer.frame = CGRect(
            x: width,
            y: 0,
            width: width,
            height: height)
        imageLayer.contents = watermark.cgImage
        layer.addSublayer(imageLayer)
    }
    

    private func createTextLayer(with model: TextBox, size: CGSize, position: CGSize, ratio: Double, duration: Double) -> CALayer {
        
        let calculatedFontSize = model.fontSize * ratio
        let calculatedPadding = model.backgroundPadding * ratio
        let calculatedCornerRadius = model.cornerRadius * ratio

        // If wordTimings is present, render karaoke-style text highlighting
        if let wordTimings = model.wordTimings {
            return createKaraokeTextLayer(
                wordTimings: wordTimings,
                model: model,
                position: position,
                calculatedFontSize: calculatedFontSize,
                calculatedPadding: calculatedPadding,
                calculatedCornerRadius: calculatedCornerRadius,
                duration: duration
            )
        }
        
        // Check if text has explicit line breaks for center alignment
        let hasExplicitLineBreaks = model.text.contains("\n")
        
        // Create attributed string for reliable text rendering (fill only)
        var fillAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: calculatedFontSize, weight: .medium),
            .foregroundColor: UIColor(model.fontColor),
            .backgroundColor: UIColor.clear // We'll draw the background manually
        ]
        
        // Add center alignment for multi-line text
        if hasExplicitLineBreaks {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            fillAttributes[.paragraphStyle] = paragraphStyle
        }
        
        let fillAttributedString = NSAttributedString(string: model.text, attributes: fillAttributes)
        
        // Create stroke attributed string if needed
        var strokeAttributedString: NSAttributedString?
        if model.strokeColor != .clear && model.strokeWidth > 0 {
            // Scale stroke width relative to font size for better proportions
            let scaledStrokeWidth = min(model.strokeWidth, calculatedFontSize * 0.15) // Max 15% of font size
            
            var strokeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: calculatedFontSize, weight: .medium),
                .foregroundColor: UIColor.clear, // Transparent fill
                .strokeColor: UIColor(model.strokeColor),
                .strokeWidth: scaledStrokeWidth // Positive for stroke-only
            ]
            
            // Add center alignment for multi-line text
            if hasExplicitLineBreaks {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                strokeAttributes[.paragraphStyle] = paragraphStyle
            }
            
            strokeAttributedString = NSAttributedString(string: model.text, attributes: strokeAttributes)
        }
        
        // Use the larger of fill or stroke size for layout
        let textSize = fillAttributedString.size()
        let strokeSize = strokeAttributedString?.size() ?? textSize
        let maxSize = CGSize(width: max(textSize.width, strokeSize.width), height: max(textSize.height, strokeSize.height))
        let paddedSize = CGSize(width: maxSize.width + 2 * calculatedPadding, height: maxSize.height + 2 * calculatedPadding)
        
        // Create layer with background - adjust position to center the text
        let textLayer = CALayer()
        let adjustedX = position.width - (paddedSize.width / 2)
        let adjustedY = position.height - (paddedSize.height / 2)
        textLayer.frame = CGRect(x: adjustedX, y: adjustedY, width: paddedSize.width, height: paddedSize.height)
        textLayer.backgroundColor = UIColor(model.bgColor).cgColor
        textLayer.cornerRadius = calculatedCornerRadius
        
        // Render text to image and set as contents with high quality
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = UIScreen.main.scale * 2.0 // Higher scale for crisp text
        rendererFormat.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: paddedSize, format: rendererFormat)
        let textImage = renderer.image { context in
            // Enable high-quality text rendering
            let cgContext = context.cgContext
            cgContext.setShouldAntialias(true)
            cgContext.setShouldSmoothFonts(true)
            cgContext.setAllowsAntialiasing(true)
            cgContext.setAllowsFontSmoothing(true)
            cgContext.setAllowsFontSubpixelPositioning(true)
            cgContext.setAllowsFontSubpixelQuantization(true)
            
            // Draw stroke layer first (background)
            if let strokeAttr = strokeAttributedString {
                strokeAttr.draw(at: CGPoint(x: calculatedPadding, y: calculatedPadding))
            }
            
            // Draw shadow if needed
            let effectiveRegularShadowRadius = (model.shadowRadius == 0 && model.shadowOpacity > 0 && model.shadowColor != .clear) ? 4.0 : model.shadowRadius
            if effectiveRegularShadowRadius > 0 && model.shadowOpacity > 0 {
                let shadowColor = UIColor(model.shadowColor).withAlphaComponent(model.shadowOpacity)
                cgContext.saveGState()
                cgContext.setShadow(offset: CGSize(width: model.shadowX, height: model.shadowY), blur: effectiveRegularShadowRadius, color: shadowColor.cgColor)
                fillAttributedString.draw(at: CGPoint(x: calculatedPadding, y: calculatedPadding))
                cgContext.restoreGState()
            }
            // Draw main text (without shadow)
            fillAttributedString.draw(at: CGPoint(x: calculatedPadding, y: calculatedPadding))
        }
        textLayer.contents = textImage.cgImage
        textLayer.contentsScale = UIScreen.main.scale * 2.0 // Match the renderer scale
        
        addAnimation(to: textLayer, with: model.timeRange, duration: duration)
        
        return textLayer
    }

    // Creates a karaoke-style text layer with animated highlighting for each word.
    private func createKaraokeTextLayer(
        wordTimings: [WordWithTiming],
        model: TextBox,
        position: CGSize,
        calculatedFontSize: CGFloat,
        calculatedPadding: CGFloat,
        calculatedCornerRadius: CGFloat,
        duration: Double
    ) -> CALayer {

        // Guard: Unwrap optional karaoke properties
        guard let karaokeType = model.karaokeType,
              let highlightColor = model.highlightColor else {
            print("❌ Karaoke properties not available for text: \(model.text)")
            // Return a simple text layer without karaoke effects
            return createSimpleTextLayer(model: model, position: position, calculatedFontSize: calculatedFontSize, calculatedPadding: calculatedPadding, calculatedCornerRadius: calculatedCornerRadius, duration: duration)
        }
        
        // Calculate ratio from the already calculated font size
        let ratio = calculatedFontSize / model.fontSize
        
        // Scale shadow properties like other properties
        // Apply default shadow radius if shadow is intended but radius is 0
        let effectiveShadowRadius = (model.shadowRadius == 0 && model.shadowOpacity > 0 && model.shadowColor != .clear) ? 4.0 : model.shadowRadius
        let calculatedShadowRadius = effectiveShadowRadius * ratio
        let calculatedShadowX = model.shadowX * ratio
        let calculatedShadowY = model.shadowY * ratio

        // 1. Set up font and calculate the layout for karaoke words (supporting multi-line)
        let font = UIFont.systemFont(ofSize: calculatedFontSize, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        
        // Add horizontal padding to each word for word-by-word background (for visual separation)
        let wordHorizontalPadding: CGFloat = (karaokeType == .wordbg) ? 8 : 0
        
        // Check if original text has explicit line breaks
        let hasExplicitLineBreaks = model.text.contains("\n")
        
        // Calculate word layout considering line breaks
        let wordWidths = wordTimings.map { ($0.text as NSString).size(withAttributes: attributes).width + 2 * wordHorizontalPadding }
        
        // Organize words into lines based on original text structure
        let wordLines = organizeKaraokeWordsIntoLines(
            originalText: model.text,
            wordTimings: wordTimings,
            wordWidths: wordWidths,
            hasExplicitLineBreaks: hasExplicitLineBreaks
        )
        
        // Calculate total dimensions
        let lineHeight = font.lineHeight
        let lineSpacing: CGFloat = 4
        let maxLineWidth = wordLines.map { line in
            line.words.enumerated().reduce(0) { width, element in
                let (index, _) = element
                let wordWidth = line.wordWidths[index]
                return width + wordWidth + (index > 0 ? 8 : 0) // 8pt spacing between words
            }
        }.max() ?? 0
        
        let totalHeight = CGFloat(wordLines.count) * lineHeight + CGFloat(max(0, wordLines.count - 1)) * lineSpacing
        let paddedSize = CGSize(width: maxLineWidth + 2 * calculatedPadding, height: totalHeight + 2 * calculatedPadding)
        let textLayer = CALayer()
        // Center the text layer at the given position
        let adjustedX = position.width - (paddedSize.width / 2)
        let adjustedY = position.height - (paddedSize.height / 2)
        textLayer.frame = CGRect(x: adjustedX, y: adjustedY, width: paddedSize.width, height: paddedSize.height)
        textLayer.backgroundColor = UIColor(model.bgColor).cgColor
        textLayer.cornerRadius = calculatedCornerRadius

        // Render the karaoke text as an image for crisp display, and add animated highlight layers for each word
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = UIScreen.main.scale * 2.0 // Higher scale for crisp text
        rendererFormat.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: paddedSize, format: rendererFormat)
        let textImage = renderer.image { context in
            // Enable high-quality text rendering
            let cgContext = context.cgContext
            cgContext.setShouldAntialias(true)
            cgContext.setShouldSmoothFonts(true)
            cgContext.setAllowsAntialiasing(true)
            cgContext.setAllowsFontSmoothing(true)
            cgContext.setAllowsFontSubpixelPositioning(true)
            cgContext.setAllowsFontSubpixelQuantization(true)
            // Loop through each line and word to lay out and animate them individually
            var currentY: CGFloat = calculatedPadding
            var globalWordIndex = 0
            
            for lineData in wordLines {
                // Calculate line width for center alignment
                let lineWidth = lineData.wordWidths.enumerated().reduce(0) { width, element in
                    let (index, wordWidth) = element
                    return width + wordWidth + (index > 0 ? 8 : 0) // 8pt spacing between words
                }
                
                // Start X position for this line (center aligned if multi-line)
                var x: CGFloat = hasExplicitLineBreaks 
                    ? calculatedPadding + (paddedSize.width - 2 * calculatedPadding - lineWidth) / 2
                    : calculatedPadding
                
                for (lineWordIndex, word) in lineData.words.enumerated() {
                    let wordWidth = lineData.wordWidths[lineWordIndex]
                    // Calculate the frame for this word (with horizontal padding for word-by-word)
                    let wordRect = CGRect(x: x, y: currentY, width: wordWidth, height: font.lineHeight)

                // --- Word-by-word: Add rounded green background for active word ---
                // If karaokeType is wordbg, add a background shape layer that will animate in sync with the word highlight
                if karaokeType == .wordbg {
                    guard let wordBGColor = model.wordBGColor else {
                        print("❌ WordBGColor not available for wordbg karaoke type")
                        continue
                    }
                    let bgLayer = CAShapeLayer()
                    let bgCornerRadius: CGFloat = 4
                    let bgRect = wordRect // background matches the padded word rect
                    let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: bgCornerRadius)
                    bgLayer.path = bgPath.cgPath
                    bgLayer.fillColor = UIColor(wordBGColor).withAlphaComponent(0.5).cgColor
                    bgLayer.opacity = 0 // Start invisible
                    // Animate opacity in sync with highlight (appears instantly at word start)
                    let bgAnim = CABasicAnimation(keyPath: "opacity")
                    bgAnim.fromValue = 0
                    bgAnim.toValue = 1
                    bgAnim.beginTime = word.start
                    bgAnim.duration = 0.01 // Instant for word-by-word
                    bgAnim.fillMode = .forwards
                    bgAnim.isRemovedOnCompletion = false
                    bgLayer.add(bgAnim, forKey: "bgOpacity")
                    textLayer.addSublayer(bgLayer)
                }

                // --- Base layer: always visible, original color ---
                // Draw the word in its normal color as the base layer
                let baseLayer = CALayer()
                baseLayer.frame = wordRect
                baseLayer.contentsScale = UIScreen.main.scale * 2.0

                // Render the word as an image for best quality
                let baseRendererFormat = UIGraphicsImageRendererFormat()
                baseRendererFormat.scale = UIScreen.main.scale * 2.0
                baseRendererFormat.opaque = false
                
                let baseRenderer = UIGraphicsImageRenderer(size: wordRect.size, format: baseRendererFormat)
                let baseImage = baseRenderer.image { context in
                    // Enable high-quality text rendering
                    let cgContext = context.cgContext
                    cgContext.setShouldAntialias(true)
                    cgContext.setShouldSmoothFonts(true)
                    cgContext.setAllowsAntialiasing(true)
                    cgContext.setAllowsFontSmoothing(true)
                    cgContext.setAllowsFontSubpixelPositioning(true)
                    cgContext.setAllowsFontSubpixelQuantization(true)
                    
                    // Create stroke and fill attributes
                    var strokeAttributes: [NSAttributedString.Key: Any]?
                    if model.strokeColor != .clear && model.strokeWidth > 0 {
                        let scaledStrokeWidth = min(model.strokeWidth, calculatedFontSize * 0.15)
                        strokeAttributes = [
                            .font: font,
                            .foregroundColor: UIColor.clear,
                            .strokeColor: UIColor(model.strokeColor),
                            .strokeWidth: scaledStrokeWidth
                        ]
                    }
                    
                    let fillAttributes: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: UIColor(model.fontColor)
                    ]
                    
                    let drawRect = CGRect(
                        x: wordHorizontalPadding,
                        y: 0,
                        width: wordRect.width - 2 * wordHorizontalPadding,
                        height: wordRect.height
                    )
                    
                    // Draw shadow if needed - apply to stroke layer when stroke exists, otherwise to fill layer
                    if calculatedShadowRadius > 0 && model.shadowOpacity > 0 {
                        let shadowColor = UIColor(model.shadowColor).withAlphaComponent(model.shadowOpacity)
                        cgContext.saveGState()
                        cgContext.setShadow(offset: CGSize(width: calculatedShadowX, height: calculatedShadowY), blur: calculatedShadowRadius, color: shadowColor.cgColor)
                        
                        if let strokeAttrs = strokeAttributes {
                            // If stroke exists, only apply shadow to stroke layer
                            word.text.draw(in: drawRect, withAttributes: strokeAttrs)
                        } else {
                            // If no stroke, apply shadow to fill layer
                            word.text.draw(in: drawRect, withAttributes: fillAttributes)
                        }
                        cgContext.restoreGState()
                    }
                    
                    // Draw stroke without shadow if needed (only if shadow was applied to stroke)
                    if let strokeAttrs = strokeAttributes, calculatedShadowRadius <= 0 || model.shadowOpacity <= 0 {
                        word.text.draw(in: drawRect, withAttributes: strokeAttrs)
                    }
                    
                    // Draw fill on top without shadow
                    word.text.draw(in: drawRect, withAttributes: fillAttributes)
                }
                baseLayer.contents = baseImage.cgImage
                textLayer.addSublayer(baseLayer)

                // --- Highlight layer: green, animated opacity ---
                // Draw the word in green as a highlight layer, initially invisible
                let highlightLayer = CALayer()
                highlightLayer.frame = wordRect
                highlightLayer.contentsScale = UIScreen.main.scale * 2.0
                highlightLayer.opacity = 0

                // Render the highlighted word as an image
                let highlightRendererFormat = UIGraphicsImageRendererFormat()
                highlightRendererFormat.scale = UIScreen.main.scale * 2.0
                highlightRendererFormat.opaque = false
                
                let highlightRenderer = UIGraphicsImageRenderer(size: wordRect.size, format: highlightRendererFormat)
                let highlightImage = highlightRenderer.image { context in
                    // Enable high-quality text rendering
                    let cgContext = context.cgContext
                    cgContext.setShouldAntialias(true)
                    cgContext.setShouldSmoothFonts(true)
                    cgContext.setAllowsAntialiasing(true)
                    cgContext.setAllowsFontSmoothing(true)
                    cgContext.setAllowsFontSubpixelPositioning(true)
                    cgContext.setAllowsFontSubpixelQuantization(true)
                    
                    // Create stroke and fill attributes for highlight
                    var highlightStrokeAttributes: [NSAttributedString.Key: Any]?
                    if model.strokeColor != .clear && model.strokeWidth > 0 {
                        let scaledStrokeWidth = min(model.strokeWidth, calculatedFontSize * 0.15)
                        highlightStrokeAttributes = [
                            .font: font,
                            .foregroundColor: UIColor.clear,
                            .strokeColor: UIColor(model.strokeColor),
                            .strokeWidth: scaledStrokeWidth
                        ]
                    }
                    
                    let highlightFillAttributes: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: UIColor(highlightColor)
                    ]
                    
                    let highlightDrawRect = CGRect(
                        x: wordHorizontalPadding,
                        y: 0,
                        width: wordRect.width - 2 * wordHorizontalPadding,
                        height: wordRect.height
                    )
                    
                    // Draw shadow if needed - apply to stroke layer when stroke exists, otherwise to fill layer
                    if calculatedShadowRadius > 0 && model.shadowOpacity > 0 {
                        let shadowColor = UIColor(model.shadowColor).withAlphaComponent(model.shadowOpacity)
                        cgContext.saveGState()
                        cgContext.setShadow(offset: CGSize(width: calculatedShadowX, height: calculatedShadowY), blur: calculatedShadowRadius, color: shadowColor.cgColor)
                        
                        if let strokeAttrs = highlightStrokeAttributes {
                            // If stroke exists, only apply shadow to stroke layer
                            word.text.draw(in: highlightDrawRect, withAttributes: strokeAttrs)
                        } else {
                            // If no stroke, apply shadow to fill layer
                            word.text.draw(in: highlightDrawRect, withAttributes: highlightFillAttributes)
                        }
                        cgContext.restoreGState()
                    }
                    
                    // Draw stroke without shadow if needed (only if shadow was applied to stroke)
                    if let strokeAttrs = highlightStrokeAttributes, calculatedShadowRadius <= 0 || model.shadowOpacity <= 0 {
                        word.text.draw(in: highlightDrawRect, withAttributes: strokeAttrs)
                    }
                    
                    // Draw fill on top without shadow
                    word.text.draw(in: highlightDrawRect, withAttributes: highlightFillAttributes)
                }
                highlightLayer.contents = highlightImage.cgImage
                textLayer.addSublayer(highlightLayer)

                // Animate the highlight layer's opacity to fade in at the correct time
                let highlightAnim = CABasicAnimation(keyPath: "opacity")
                highlightAnim.fromValue = 0
                highlightAnim.toValue = 1
                highlightAnim.beginTime = word.start

                // Karaoke animation - appear instantly for word-based highlighting
                highlightAnim.duration = 0.01
                highlightAnim.fillMode = .forwards
                highlightAnim.isRemovedOnCompletion = false
                highlightLayer.add(highlightAnim, forKey: "karaokeOpacity")
                // Move x to the next word position (add spacing)
                x += wordWidth + 8
                globalWordIndex += 1
                }
                
                // Move to next line
                currentY += lineHeight + lineSpacing
            }
        }
        textLayer.contentsScale = UIScreen.main.scale * 2.0
        // Add appearance/disappearance animations for the whole text layer if needed
        addAnimation(to: textLayer, with: model.timeRange, duration: duration)
        return textLayer
    }
    
    func convertSize(_ size: CGSize, fromFrame frameSize1: CGSize, toFrame frameSize2: CGSize) -> (size: CGSize, ratio: Double) {
        
        let widthRatio = frameSize2.width / frameSize1.width
        let heightRatio = frameSize2.height / frameSize1.height
        let ratio = max(widthRatio, heightRatio)
        let newSizeWidth = size.width * ratio
        let newSizeHeight = size.height * ratio
        
        // If original size is (0,0), it means the text is centered - don't apply any offset
        let newSize: CGSize
        if size.width == 0 && size.height == 0 {
            // Centered text - position at center of export frame
            newSize = CGSize(width: frameSize2.width / 2, height: frameSize2.height / 2)
        } else {
            // Offset text - apply the scaled offset from center
            newSize = CGSize(width: (frameSize2.width / 2) + newSizeWidth, height: (frameSize2.height / 2) + -newSizeHeight)
        }
        
        return (CGSize(width: newSize.width, height: newSize.height), ratio)
    }
    
    private func addAnimation(to textLayer: CALayer, with timeRange: ClosedRange<Double>, duration: Double) {
        
        if timeRange.lowerBound > 0{
            let appearance = CABasicAnimation(keyPath: "opacity")
            appearance.fromValue = 0
            appearance.toValue = 1
            appearance.duration = 0.05
            appearance.beginTime = timeRange.lowerBound
            appearance.fillMode = .forwards
            appearance.isRemovedOnCompletion = false
            textLayer.add(appearance, forKey: "Appearance")
            textLayer.opacity = 0
        }
        
        if timeRange.upperBound < duration{
            let disappearance = CABasicAnimation(keyPath: "opacity")
            disappearance.fromValue = 1
            disappearance.toValue = 0
            disappearance.beginTime = timeRange.upperBound
            disappearance.duration = 0.05
            disappearance.fillMode = .forwards
            disappearance.isRemovedOnCompletion = false
            textLayer.add(disappearance, forKey: "Disappearance")
        }
        
    }
    
    // Creates a simple text layer without karaoke effects (fallback when karaoke properties are not available)
    private func createSimpleTextLayer(
        model: TextBox,
        position: CGSize,
        calculatedFontSize: CGFloat,
        calculatedPadding: CGFloat,
        calculatedCornerRadius: CGFloat,
        duration: Double
    ) -> CALayer {
        let font = UIFont.systemFont(ofSize: calculatedFontSize, weight: .bold)
        let textSize = (model.text as NSString).size(withAttributes: [.font: font])
        let paddedSize = CGSize(width: textSize.width + 2 * calculatedPadding, height: textSize.height + 2 * calculatedPadding)
        
        let textLayer = CALayer()
        let adjustedX = position.width - (paddedSize.width / 2)
        let adjustedY = position.height - (paddedSize.height / 2)
        textLayer.frame = CGRect(x: adjustedX, y: adjustedY, width: paddedSize.width, height: paddedSize.height)
        textLayer.backgroundColor = UIColor(model.bgColor).cgColor
        textLayer.cornerRadius = calculatedCornerRadius
        
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = UIScreen.main.scale * 2.0
        rendererFormat.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: paddedSize, format: rendererFormat)
        let textImage = renderer.image { context in
            // Enable high-quality text rendering
            let cgContext = context.cgContext
            cgContext.setShouldAntialias(true)
            cgContext.setShouldSmoothFonts(true)
            cgContext.setAllowsAntialiasing(true)
            cgContext.setAllowsFontSmoothing(true)
            cgContext.setAllowsFontSubpixelPositioning(true)
            cgContext.setAllowsFontSubpixelQuantization(true)
            
            model.text.draw(
                in: CGRect(
                    x: calculatedPadding,
                    y: calculatedPadding,
                    width: textSize.width,
                    height: textSize.height
                ),
                withAttributes: [
                    .font: font,
                    .foregroundColor: UIColor(model.fontColor)
                ]
            )
        }
        textLayer.contents = textImage.cgImage
        textLayer.contentsScale = UIScreen.main.scale * 2.0
        
        addAnimation(to: textLayer, with: model.timeRange, duration: duration)
        return textLayer
    }
    
    // Helper struct for organizing karaoke words into lines
    private struct KaraokeLineData {
        let words: [WordWithTiming]
        let wordWidths: [CGFloat]
    }
    
    // Helper function to organize karaoke words into lines based on original text structure
    private func organizeKaraokeWordsIntoLines(
        originalText: String,
        wordTimings: [WordWithTiming],
        wordWidths: [CGFloat],
        hasExplicitLineBreaks: Bool
    ) -> [KaraokeLineData] {
        
        if !hasExplicitLineBreaks {
            // Single line - return all words
            return [KaraokeLineData(words: wordTimings, wordWidths: wordWidths)]
        }
        
        // Split original text into lines to detect explicit line breaks
        let textLines = originalText.components(separatedBy: .newlines)
        
        var result: [KaraokeLineData] = []
        var wordIndex = 0
        
        for textLine in textLines {
            let lineWords = textLine.split { $0.isWhitespace }.map(String.init)
            var currentLineWords: [WordWithTiming] = []
            var currentLineWidths: [CGFloat] = []
            
            for _ in lineWords {
                if wordIndex < wordTimings.count {
                    currentLineWords.append(wordTimings[wordIndex])
                    currentLineWidths.append(wordWidths[wordIndex])
                    wordIndex += 1
                }
            }
            
            if !currentLineWords.isEmpty {
                result.append(KaraokeLineData(words: currentLineWords, wordWidths: currentLineWidths))
            }
        }
        
        // Add any remaining words to the last line (safety fallback)
        while wordIndex < wordTimings.count {
            if !result.isEmpty {
                result[result.count - 1] = KaraokeLineData(
                    words: result[result.count - 1].words + [wordTimings[wordIndex]],
                    wordWidths: result[result.count - 1].wordWidths + [wordWidths[wordIndex]]
                )
            } else {
                result.append(KaraokeLineData(words: [wordTimings[wordIndex]], wordWidths: [wordWidths[wordIndex]]))
            }
            wordIndex += 1
        }
        
        return result.isEmpty ? [KaraokeLineData(words: wordTimings, wordWidths: wordWidths)] : result
    }
}



enum ExporterError: Error, LocalizedError{
    case unknow
    case cancelled
    case cannotCreateExportSession
    case failed
    
}


extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
    
    
    var degTorad: Double {
        return self * .pi / 180
    }
}


//
//class ObservableExporter {
//    
//    var progressTimer: Timer?
//    let session: AVAssetExportSession
//    public let progress: Binding<Double>
//    public var duration: TimeInterval?
//    
//    init(session: AVAssetExportSession, progress: Binding<Double>) {
//        self.session = session
//        self.progress = progress
//    }
//    
//    func export() async throws -> AVAssetExportSession.Status {
//        progressTimer = Timer(timeInterval: 0.1, repeats: true, block: { timer in
//            self.progress.wrappedValue = Double(self.session.progress)
//        })
//        RunLoop.main.add(progressTimer!, forMode: .common)
//        let startDate = Date()
//        await session.export()
//        progressTimer?.invalidate()
//        let endDate = Date()
//        duration = endDate.timeIntervalSince(startDate)
//        if let error = session.error {
//            throw error
//        } else {
//            return session.status
//        }
//    }
//}