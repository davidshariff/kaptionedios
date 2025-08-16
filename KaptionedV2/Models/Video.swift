//
//  Video.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 19.04.2023.
//

import SwiftUI
import AVKit

struct Video: Identifiable{
    
    var id: UUID = UUID()
    var url: URL
    var asset: AVAsset
    let originalDuration: Double
    var thumbnailsImages = [ThumbnailImage]()
    var frameSize: CGSize = .zero
    var geometrySize: CGSize = .zero
    var toolsApplied = [Int]()


    var textBoxes: [TextBox] = []

    var totalDuration: Double{
        originalDuration
    }
    
    /// Returns the actual rendered rect of the video within its container
    /// Note: This uses the stored geometrySize. For dynamic sizing based on videoPlayerSize, 
    /// use the videoRect method in EditorViewModel instead.
    var videoRect: CGRect {
        guard frameSize.width > 0 && frameSize.height > 0,
              geometrySize.width > 0 && geometrySize.height > 0 else {
            return .zero
        }
        
        let videoWidth = frameSize.width
        let videoHeight = frameSize.height
        
        // Calculate aspect ratio and fit within container
        let aspectRatio = videoWidth / videoHeight
        var renderedWidth = geometrySize.width
        var renderedHeight = geometrySize.width / aspectRatio
        
        // If height exceeds container, scale down
        if renderedHeight > geometrySize.height {
            renderedHeight = geometrySize.height
            renderedWidth = geometrySize.height * aspectRatio
        }
        

        
        // Center the video in the container
        let x = (geometrySize.width - renderedWidth) / 2
        let y = (geometrySize.height - renderedHeight) / 2
        
        return CGRect(x: x, y: y, width: renderedWidth, height: renderedHeight)
    }
    
    init(url: URL){
        self.url = url
        self.asset = AVAsset(url: url)
        self.originalDuration = asset.videoDuration()
    }
    
    mutating func updateThumbnails(_ geo: GeometryProxy){
        let imagesCount = thumbnailCount(geo)
        
        var offset: Float64 = 0
        for i in 0..<imagesCount{
            let thumbnailImage = ThumbnailImage(image: asset.getImage(Int(offset)))
            offset = Double(i) * (originalDuration / Double(imagesCount))
            thumbnailsImages.append(thumbnailImage)
        }
    }
        

    

    

    

    

    

    

    
    
    private func thumbnailCount(_ geo: GeometryProxy) -> Int {
        
        let num = Double(geo.size.width - 32) / Double(70 / 1.5)
        
        return Int(ceil(num))
    }
    
    
    static var mock: Video = .init(url:URL(string: "https://www.google.com/")!)
}


extension Video: Equatable{
    
    static func == (lhs: Video, rhs: Video) -> Bool {
        lhs.id == rhs.id
    }
}

extension Double{
    func nextAngle() -> Double {
        var next = Int(self) + 90
        if next >= 360 {
            next = 0
        } else if next < 0 {
            next = 360 - abs(next % 360)
        }
        return Double(next)
    }
}



struct ThumbnailImage: Identifiable{
    var id: UUID = UUID()
    var image: UIImage?
    
    
    init(image: UIImage? = nil) {
        self.image = image?.resize(to: .init(width: 250, height: 350))
    }
}



