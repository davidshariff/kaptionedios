//
//  AVAssets+Ext.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 16.04.2023.
//

import Foundation
import AVKit
import SwiftUI

extension AVAsset {
    
    struct TrimError: Error {
        let description: String
        let underlyingError: Error?
        
        init(_ description: String, underlyingError: Error? = nil) {
            self.description = "TrimVideo: " + description
            self.underlyingError = underlyingError
        }
    }
    

    
    
    func videoDuration() -> Double{
        
        self.duration.seconds

    }
    
    func generateThumbnail() -> UIImage? {
        let imgGenerator = AVAssetImageGenerator(asset: self)
        imgGenerator.appliesPreferredTrackTransform = true
        
        // Try to get thumbnail from the middle of the video
        let duration = self.duration.seconds
        let middleTime = CMTime(seconds: duration / 2, preferredTimescale: 1)
        
        guard let cgImage = try? imgGenerator.copyCGImage(at: middleTime, actualTime: nil) else { 
            return nil 
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        // Generate thumbnail that matches the grid cell aspect ratio
        // Grid cells have fixed height of 150 and adaptive width (roughly square-ish)
        let targetSize = CGSize(width: 150, height: 150) // Square aspect ratio to match grid cells
        return uiImage.resize(to: targetSize)
    }
    
//    guard let duration = try? await self.load(.duration) else { return nil }
//
//    return duration.seconds
    
    func naturalSize() async -> CGSize? {
        guard let tracks = try? await loadTracks(withMediaType: .video) else { return nil }
        guard let track = tracks.first else { return nil }
        guard let size = try? await track.load(.naturalSize) else { return nil }
        return size
    }
    
    
    func adjustVideoSize(to viewSize: CGSize) async -> CGSize? {
        
        
        guard let assetSize = await self.naturalSize() else { return nil }
        
        let videoRatio = assetSize.width / assetSize.height
        let isPortrait = assetSize.height > assetSize.width
        var videoSize = viewSize
        if isPortrait {
            videoSize = CGSize(width: videoSize.height * videoRatio, height: videoSize.height)
        } else {
            videoSize = CGSize(width: videoSize.width, height: videoSize.width / videoRatio)
        }
        return videoSize
    }

}


