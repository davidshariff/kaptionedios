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
    
    
    ///The renderer is made up of half-sequential operations:
    func startRender(video: Video, videoQuality: VideoQuality) async throws -> URL{
        print("🚀 [VideoEditor] startRender called – quality: \(videoQuality)  resolution: \(videoQuality.size)")
        do{
            let url = try await resizeAndLayerOperation(video: video, videoQuality: videoQuality)
            let finalUrl = try await applyFiltersOperations(video, fromUrl: url)
            print("✅ [VideoEditor] Finished render – output: \(finalUrl)")
            return finalUrl
        }catch{
            print("🛑 [VideoEditor] Render failed: \(error)")
            throw error
        }
    }
    
    
    ///Cut, resizing, rotate and set quality
    private func resizeAndLayerOperation(video: Video,
                                  videoQuality: VideoQuality) async throws -> URL{
        
        let composition = AVMutableComposition()
        
        let timeRange = getTimeRange(for: video.originalDuration, with: video.rangeDuration)
        let asset = video.asset
        
        ///Set new timeScale
        try await setTimeScaleAndAddTracks(to: composition, from: asset, audio: video.audio, timeScale: Float64(video.rate), videoVolume: video.volume)
        
        ///Get new timeScale video track
        guard let videoTrack = try await composition.loadTracks(withMediaType: .video).first else {
            throw ExporterError.unknow
        }
        
        ///Prepair new video size
        let naturalSize = videoTrack.naturalSize
        let videoTrackPreferredTransform = try await videoTrack.load(.preferredTransform)
        let outputSize = getSizeFromOrientation(newSize: videoQuality.size, videoTrackPreferredTransform: videoTrackPreferredTransform)
        
        ///Create layerInstructions and set new size, scale, mirror
        let layerInstruction = videoCompositionInstructionForTrackWithSizeAndTime(
            
            preferredTransform: videoTrackPreferredTransform,
            naturalSize: naturalSize,
            newSize: outputSize,
            track: videoTrack,
            scale: video.videoFrames?.scale ?? 1,
            isMirror: video.isMirror
        )
        
        ///Create mutable video composition
        let videoComposition = AVMutableVideoComposition()
        ///Set rander video  size
        videoComposition.renderSize = outputSize
        ///Set frame duration 30fps
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        ///Create background layer color and scale video
        let overlayTrackID = createLayers(video.videoFrames, video: video, size: outputSize, videoComposition: videoComposition)
        
        ///Set Video Composition Instruction
        let instruction = AVMutableVideoCompositionInstruction()

        ///Set time range
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
        
        ///Create file path in temp directory
        let outputURL = createTempPath()
        
        ///Create exportSession
        let session = try exportSession(composition: composition, videoComposition: videoComposition, outputURL: outputURL, timeRange: timeRange)
        print("⏳ [VideoEditor] Starting first pass export (resize/compose) to \(outputURL.path)")
        
        await session.export()
        
        if let error = session.error {
            print("🛑 [VideoEditor] First pass export error: \(error)")
            throw error
        } else {
            if let url = session.outputURL{
                print("✅ [VideoEditor] First pass export finished: \(url)")
                return url
            }
            throw ExporterError.failed
        }
    }
    
    
    ///Adding filters
    private func applyFiltersOperations(_ video: Video, fromUrl: URL) async throws -> URL {
        
        let filters = Helpers.createFilters(mainFilter: CIFilter(name: video.filterName ?? ""), video.colorCorrection)

        if filters.isEmpty{
            return fromUrl
        }
        let asset = AVAsset(url: fromUrl)
        let composition = asset.setFilters(filters)
        
        let outputURL = createTempPath()
        //export the video to as per your requirement conversion
        
        ///Create exportSession
        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            print("Cannot create export session.")
            throw ExporterError.cannotCreateExportSession
        }
        session.videoComposition = composition
        session.outputFileType = .mp4
        session.outputURL = outputURL
        
        print("⏳ [VideoEditor] Starting second pass export (filters) to \(outputURL.path)")
        await session.export()
        
        if let error = session.error {
            print("🛑 [VideoEditor] Second pass export error: \(error)")
            throw error
        } else {
            if let url = session.outputURL{
                print("✅ [VideoEditor] Second pass export finished: \(url)")
                return url
            }
            throw ExporterError.failed
        }
    }
}

//MARK: - Helpers
extension VideoEditor{
    

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
       
        // Debug: dump layer hierarchy to confirm text layers before export
        #if DEBUG
        func dump(layer: CALayer, indent: String = "") {
            print("\(indent)- Layer: \(layer.self) frame: \(layer.frame) opacity: \(layer.opacity) sublayers: \(layer.sublayers?.count ?? 0)")
            layer.sublayers?.forEach { dump(layer: $0, indent: indent + "  ") }
        }
        print("📐 [VideoEditor] Overlay layer tree before export:")
        dump(layer: outputLayer)
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
        print("🔤 Creating text layer:")
        print("   Text: '\(model.text)'")
        print("   Font size: \(model.fontSize) * \(ratio) = \(model.fontSize * ratio)")
        print("   Position: \(position)")
        print("   Colors: fg=\(model.fontColor), bg=\(model.bgColor), stroke=\(model.strokeColor)")
        print("   Stroke width: \(model.strokeWidth)")
        
        let calculatedFontSize = model.fontSize * ratio
        let calculatedPadding = model.backgroundPadding * ratio
        let calculatedCornerRadius = model.cornerRadius * ratio

        // If karaokeWords is present, render karaoke-style text highlighting
        if let karaokeWords = model.karaokeWords {
            return createKaraokeTextLayer(
                karaokeWords: karaokeWords,
                model: model,
                position: position,
                calculatedFontSize: calculatedFontSize,
                calculatedPadding: calculatedPadding,
                calculatedCornerRadius: calculatedCornerRadius,
                duration: duration
            )
        }

        // Create attributed string for reliable text rendering
        var attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: calculatedFontSize, weight: .medium),
            .foregroundColor: UIColor(model.fontColor),
            .backgroundColor: UIColor.clear // We'll draw the background manually
        ]
        
        // Apply stroke if stroke color is not clear and stroke width is greater than 0
        if model.strokeColor != .clear && model.strokeWidth > 0 {
            attributes[.strokeColor] = UIColor(model.strokeColor)
            attributes[.strokeWidth] = -model.strokeWidth
        }
        
        let attributedString = NSAttributedString(string: model.text, attributes: attributes)
        let textSize = attributedString.size()
        let paddedSize = CGSize(width: textSize.width + 2 * calculatedPadding, height: textSize.height + 2 * calculatedPadding)
        
        // Create layer with background - adjust position to center the text
        let textLayer = CALayer()
        let adjustedX = position.width - (paddedSize.width / 2)
        let adjustedY = position.height - (paddedSize.height / 2)
        textLayer.frame = CGRect(x: adjustedX, y: adjustedY, width: paddedSize.width, height: paddedSize.height)
        textLayer.backgroundColor = UIColor(model.bgColor).cgColor
        textLayer.cornerRadius = calculatedCornerRadius
        
        // Render text to image and set as contents
        let renderer = UIGraphicsImageRenderer(size: paddedSize)
        let textImage = renderer.image { context in
            // Draw shadow if needed
            if model.shadowRadius > 0 && model.shadowOpacity > 0 {
                let shadowColor = UIColor(model.shadowColor).withAlphaComponent(model.shadowOpacity)
                context.cgContext.saveGState()
                context.cgContext.setShadow(offset: CGSize(width: model.shadowX, height: model.shadowY), blur: model.shadowRadius, color: shadowColor.cgColor)
                attributedString.draw(at: CGPoint(x: calculatedPadding, y: calculatedPadding))
                context.cgContext.restoreGState()
            }
            // Draw main text (without shadow)
            attributedString.draw(at: CGPoint(x: calculatedPadding, y: calculatedPadding))
        }
        textLayer.contents = textImage.cgImage
        textLayer.contentsScale = UIScreen.main.scale
        
        addAnimation(to: textLayer, with: model.timeRange, duration: duration)
        
        return textLayer
    }

    // Creates a karaoke-style text layer with animated highlighting for each word.
    private func createKaraokeTextLayer(
        karaokeWords: [KaraokeWord],
        model: TextBox,
        position: CGSize,
        calculatedFontSize: CGFloat,
        calculatedPadding: CGFloat,
        calculatedCornerRadius: CGFloat,
        duration: Double
    ) -> CALayer {

        // 1. Set up font and calculate the width of each word (with padding for word-by-word)
        //    This is needed to lay out each word precisely and to size the overall text layer.
        let font = UIFont.systemFont(ofSize: calculatedFontSize, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        
        // Add horizontal padding to each word for word-by-word background (for visual separation)
        let wordHorizontalPadding: CGFloat = (model.karaokeType == .wordbg) ? 8 : 0

        // Calculate the width of each word, including padding if needed
        let wordWidths = karaokeWords.map { ($0.text as NSString).size(withAttributes: attributes).width + 2 * wordHorizontalPadding }
        // Total width is the sum of all word widths plus spacing between words
        let totalWidth = wordWidths.reduce(0, +) + CGFloat(karaokeWords.count - 1) * 8 // 8pt spacing between words
        // The padded size includes extra padding around the text for background/border
        let paddedSize = CGSize(width: totalWidth + 2 * calculatedPadding, height: font.lineHeight + 2 * calculatedPadding)
        let textLayer = CALayer()
        // Center the text layer at the given position
        let adjustedX = position.width - (paddedSize.width / 2)
        let adjustedY = position.height - (paddedSize.height / 2)
        textLayer.frame = CGRect(x: adjustedX, y: adjustedY, width: paddedSize.width, height: paddedSize.height)
        textLayer.backgroundColor = UIColor(model.bgColor).cgColor
        textLayer.cornerRadius = calculatedCornerRadius

        // Render the karaoke text as an image for crisp display, and add animated highlight layers for each word
        let renderer = UIGraphicsImageRenderer(size: paddedSize)
        let textImage = renderer.image { context in
            var x: CGFloat = calculatedPadding
            // Loop through each word to lay out and animate them individually
            for (i, word) in karaokeWords.enumerated() {
                // Calculate the frame for this word (with horizontal padding for word-by-word)
                let wordRect = CGRect(x: x, y: calculatedPadding, width: wordWidths[i], height: font.lineHeight)

                // --- Word-by-word: Add rounded green background for active word ---
                // If karaokeType is wordbg, add a background shape layer that will animate in sync with the word highlight
                if model.karaokeType == .wordbg {
                    let bgLayer = CAShapeLayer()
                    let bgCornerRadius: CGFloat = 4
                    let bgRect = wordRect // background matches the padded word rect
                    let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: bgCornerRadius)
                    bgLayer.path = bgPath.cgPath
                    bgLayer.fillColor = UIColor(model.wordBGColor).withAlphaComponent(0.5).cgColor
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
                let baseLayer = CATextLayer()
                baseLayer.string = word.text
                baseLayer.font = font
                baseLayer.fontSize = calculatedFontSize
                baseLayer.frame = wordRect
                baseLayer.contentsScale = UIScreen.main.scale
                baseLayer.alignmentMode = .left
                baseLayer.foregroundColor = UIColor(model.fontColor).cgColor

                // Render the word as an image for best quality
                let baseRenderer = UIGraphicsImageRenderer(size: wordRect.size)
                let baseImage = baseRenderer.image { _ in
                    word.text.draw(
                        in: CGRect(
                            x: wordHorizontalPadding,
                            y: 0,
                            width: wordRect.width - 2 * wordHorizontalPadding,
                            height: wordRect.height
                        ),
                        withAttributes: [
                            .font: font,
                            .foregroundColor: UIColor(model.fontColor)
                        ]
                    )
                }
                baseLayer.contents = baseImage.cgImage
                textLayer.addSublayer(baseLayer)

                // --- Highlight layer: green, animated opacity ---
                // Draw the word in green as a highlight layer, initially invisible
                let highlightLayer = CATextLayer()
                highlightLayer.string = word.text
                highlightLayer.font = font
                highlightLayer.fontSize = calculatedFontSize
                highlightLayer.frame = wordRect
                highlightLayer.contentsScale = UIScreen.main.scale
                highlightLayer.alignmentMode = .left
                highlightLayer.foregroundColor = UIColor(model.highlightColor).cgColor
                highlightLayer.opacity = 0

                // Render the highlighted word as an image
                let highlightRenderer = UIGraphicsImageRenderer(size: wordRect.size)
                let highlightImage = highlightRenderer.image { _ in
                    word.text.draw(
                        in: CGRect(
                            x: wordHorizontalPadding,
                            y: 0,
                            width: wordRect.width - 2 * wordHorizontalPadding,
                            height: wordRect.height
                        ),
                        withAttributes: [
                            .font: font,
                            .foregroundColor: UIColor(model.highlightColor)
                        ]
                    )
                }
                highlightLayer.contents = highlightImage.cgImage
                textLayer.addSublayer(highlightLayer)

                // Animate the highlight layer's opacity to fade in at the correct time
                let highlightAnim = CABasicAnimation(keyPath: "opacity")
                highlightAnim.fromValue = 0
                highlightAnim.toValue = 1
                highlightAnim.beginTime = word.start

                // If karaokeType is letter, animate over the word's duration; otherwise, appear instantly
                if model.karaokeType == .letter {
                    highlightAnim.duration = word.end - word.start
                } else {
                    highlightAnim.duration = 0.01
                }
                highlightAnim.fillMode = .forwards
                highlightAnim.isRemovedOnCompletion = false
                highlightLayer.add(highlightAnim, forKey: "karaokeOpacity")
                // Move x to the next word position (add spacing)
                x += wordWidths[i] + 8
                
            }
        }
        textLayer.contentsScale = UIScreen.main.scale
        // Add appearance/disappearance animations for the whole text layer if needed
        addAnimation(to: textLayer, with: model.timeRange, duration: duration)
        return textLayer
    }
    
    func convertSize(_ size: CGSize, fromFrame frameSize1: CGSize, toFrame frameSize2: CGSize) -> (size: CGSize, ratio: Double) {
        print("📍 Converting size:")
        print("   Original size: \(size)")
        print("   From frame: \(frameSize1)")
        print("   To frame: \(frameSize2)")
        
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
        print("   Ratios: width=\(widthRatio), height=\(heightRatio), max=\(ratio)")
        print("   Scaled size: width=\(newSizeWidth), height=\(newSizeHeight)")
        print("   Final position: \(newSize)")
        
        return (CGSize(width: newSize.width, height: newSize.height), ratio)
    }
    
    private func addAnimation(to textLayer: CALayer, with timeRange: ClosedRange<Double>, duration: Double) {
        print("🎬 Adding animations for time range: \(timeRange)")
        
        if timeRange.lowerBound > 0{
            print("   Adding appearance animation at \(timeRange.lowerBound)")
            let appearance = CABasicAnimation(keyPath: "opacity")
            appearance.fromValue = 0
            appearance.toValue = 1
            appearance.duration = 0.05
            appearance.beginTime = timeRange.lowerBound
            appearance.fillMode = .forwards
            appearance.isRemovedOnCompletion = false
            textLayer.add(appearance, forKey: "Appearance")
            textLayer.opacity = 0
            print("   Set initial opacity to 0")
        }
        
        if timeRange.upperBound < duration{
            print("   Adding disappearance animation at \(timeRange.upperBound)")
            let disappearance = CABasicAnimation(keyPath: "opacity")
            disappearance.fromValue = 1
            disappearance.toValue = 0
            disappearance.beginTime = timeRange.upperBound
            disappearance.duration = 0.05
            disappearance.fillMode = .forwards
            disappearance.isRemovedOnCompletion = false
            textLayer.add(disappearance, forKey: "Disappearance")
        }
        
        if timeRange.lowerBound == 0 {
            print("   No appearance animation - text should be visible from start")
        }
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