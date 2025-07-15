//
//  Helpers.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 27.04.2023.
//

import Foundation
import CoreImage
import SwiftUI

final class Helpers{
    
    static func createColorFilter(_ colorCorrection: ColorCorrection?) -> CIFilter?{
        guard  let colorCorrection else { return nil }
        let colorCorrectionFilter = CIFilter(name: "CIColorControls")
        colorCorrectionFilter?.setValue(colorCorrection.brightness, forKey: CorrectionType.brightness.key)
        colorCorrectionFilter?.setValue(colorCorrection.contrast + 1, forKey: CorrectionType.contrast.key)
        colorCorrectionFilter?.setValue(colorCorrection.saturation + 1, forKey: CorrectionType.saturation.key)
        return colorCorrectionFilter
    }
    
    
    static func createFilters(mainFilter: CIFilter?, _ colorCorrection: ColorCorrection?) -> [CIFilter]{
        var filters = [CIFilter]()
        
        if let mainFilter{
            filters.append(mainFilter)
        }
        
        if let colorFilter = createColorFilter(colorCorrection){
            filters.append(colorFilter)
        }
        
        return filters
    }
    
    static func generateTestSubs(for video: Video) -> [TextBox] {
        let w = video.frameSize.width
        let h = video.frameSize.height
        return [
            TextBox(
                text: "Welcome to the Editor 1",
                fontSize: 32,
                bgColor: .clear,
                fontColor: .white,
                strokeColor: .black,
                strokeWidth: 2,
                timeRange: 0.0...0.7,
                offset: CGSize(width: 0, height: (h/2) - 80),
                backgroundPadding: 8,
                cornerRadius: 8,
                shadowColor: .black,
                shadowRadius: 6,
                shadowX: 0,
                shadowY: 2,
                shadowOpacity: 0.7
            ),
            TextBox(
                text: "With a nice background!",
                fontSize: 28,
                bgColor: .black.opacity(0.6),
                fontColor: .white,
                strokeColor: .clear,
                strokeWidth: 0,
                timeRange: 0.3...0.9,
                offset: CGSize(width: 0, height: 0),
                backgroundPadding: 12,
                cornerRadius: 12,
                shadowColor: .clear,
                shadowRadius: 0,
                shadowX: 0,
                shadowY: 0,
                shadowOpacity: 0
            ),
            TextBox(
                text: "This is a yellow tip!",
                fontSize: 28,
                bgColor: .clear,
                fontColor: .yellow,
                strokeColor: .clear,
                strokeWidth: 0,
                timeRange: 0.7...1.3,
                offset: CGSize(width: -(w/2) + 120, height: -(h/2) + 60),
                backgroundPadding: 8,
                cornerRadius: 8,
                shadowColor: .clear,
                shadowRadius: 0,
                shadowX: 0,
                shadowY: 0,
                shadowOpacity: 0
            ),
            TextBox(
                text: "Red with blue shadow!",
                fontSize: 30,
                bgColor: .clear,
                fontColor: .red,
                strokeColor: .white,
                strokeWidth: 2,
                timeRange: 1.3...2.0,
                offset: CGSize(width: (w/2) - 120, height: (h/2) - 120),
                backgroundPadding: 8,
                cornerRadius: 8,
                shadowColor: .blue,
                shadowRadius: 8,
                shadowX: 4,
                shadowY: 4,
                shadowOpacity: 0.8
            )
        ]
    }
    
    static func generateKaraokeSubs(for video: Video, karaokeType: KaraokeType = .letter) -> [TextBox] {
        let w = video.frameSize.width
        let h = video.frameSize.height
        let lines = [
            "Welcome to the Editor 1",
            "With a nice background!",
            "This is a yellow tip!",
            "Red with blue shadow!"
        ]
        let fontSizes: [CGFloat] = [32, 28, 28, 30]
        let bgColors: [Color] = [.clear, .black.opacity(0.6), .clear, .clear]
        let fontColors: [Color] = [.white, .white, .yellow, .red]
        let strokeColors: [Color] = [.black, .clear, .clear, .white]
        let strokeWidths: [CGFloat] = [2, 0, 0, 2]
        let offsets: [CGSize] = [
            CGSize(width: 0, height: (h/2) - 80),
            CGSize(width: 0, height: 0),
            CGSize(width: -(w/2) + 120, height: -(h/2) + 60),
            CGSize(width: (w/2) - 120, height: (h/2) - 120)
        ]
        let backgroundPaddings: [CGFloat] = [8, 12, 8, 8]
        let cornerRadii: [CGFloat] = [8, 12, 8, 8]
        let shadowColors: [Color] = [.black, .clear, .clear, .blue]
        let shadowRadii: [CGFloat] = [6, 0, 0, 8]
        let shadowXs: [CGFloat] = [0, 0, 0, 4]
        let shadowYs: [CGFloat] = [2, 0, 0, 4]
        let shadowOpacities: [Double] = [0.7, 0, 0, 0.8]
        let lineDurations: [Double] = [0.7, 0.6, 0.6, 0.7]
        var startTime: Double = 0.0
        var boxes: [TextBox] = []
        for (i, line) in lines.enumerated() {
            let words = line.split(separator: " ").map(String.init)
            let wordDuration = lineDurations[i] / Double(words.count)
            var karaokeWords: [KaraokeWord] = []
            for (j, word) in words.enumerated() {
                let wordStart = startTime + Double(j) * wordDuration
                let wordEnd = wordStart + wordDuration
                karaokeWords.append(KaraokeWord(text: word, start: wordStart, end: wordEnd))
            }
            let box = TextBox(
                text: line,
                fontSize: fontSizes[i],
                bgColor: bgColors[i],
                fontColor: fontColors[i],
                strokeColor: strokeColors[i],
                strokeWidth: strokeWidths[i],
                timeRange: startTime...(startTime + lineDurations[i]),
                offset: offsets[i],
                backgroundPadding: backgroundPaddings[i],
                cornerRadius: cornerRadii[i],
                shadowColor: shadowColors[i],
                shadowRadius: shadowRadii[i],
                shadowX: shadowXs[i],
                shadowY: shadowYs[i],
                shadowOpacity: shadowOpacities[i],
                karaokeWords: karaokeWords,
                karaokeType: karaokeType
            )
            boxes.append(box)
            startTime += lineDurations[i]
        }
        return boxes
    }
}
