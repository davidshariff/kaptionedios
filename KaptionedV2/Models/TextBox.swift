import Foundation
import SwiftUI


struct WordWithTiming: Identifiable, Equatable, Codable {
    let id = UUID()
    let text: String
    let start: Double
    let end: Double
}

enum KaraokeType: String, CaseIterable, Codable {
    case word = "Word"
    case wordbg = "WordBG"
    case wordAndScale = "WordAndScale"
}

struct TextBox: Identifiable{
    
    var id: UUID = UUID()
    var text: String = ""
    var fontSize: CGFloat = 20
    var lastFontSize: CGFloat = .zero
    var bgColor: Color = .white
    var fontColor: Color = .black
    var strokeColor: Color = .clear
    var strokeWidth: CGFloat = 0
    var timeRange: ClosedRange<Double> = 0...3
    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    var backgroundPadding: CGFloat = 8
    var cornerRadius: CGFloat = 0
    
    // Shadow properties
    var shadowColor: Color = .black
    var shadowRadius: CGFloat = 0
    var shadowX: CGFloat = 0
    var shadowY: CGFloat = 0
    var shadowOpacity: Double = 0.5

    var wordTimings: [WordWithTiming]? = nil

    // Karaoke properties
    var isKaraokePreset: Bool = false
    var karaokeType: KaraokeType? = nil
    var highlightColor: Color? = nil
    var wordBGColor: Color? = nil
    
    // TikTok karaoke scaling properties
    var activeWordScale: CGFloat = 1.2 // Scale factor for the active word (default 20% bigger)
    
    // Preset tracking
    var presetName: String? = nil
    
    init(
        text: String = "",
        fontSize: CGFloat = 20,
        lastFontSize: CGFloat = .zero,
        bgColor: Color = .white,
        fontColor: Color = .black,
        strokeColor: Color = .clear,
        strokeWidth: CGFloat = 0,
        timeRange: ClosedRange<Double> = 0...3,
        offset: CGSize = .zero,
        lastOffset: CGSize = .zero,
        backgroundPadding: CGFloat = 8,
        cornerRadius: CGFloat = 0,
        shadowColor: Color = .black,
        shadowRadius: CGFloat = 0,
        shadowX: CGFloat = 0,
        shadowY: CGFloat = 0,
        shadowOpacity: Double = 0.5,
        wordTimings: [WordWithTiming]? = nil,
        isKaraokePreset: Bool = false,
        karaokeType: KaraokeType? = nil,
        highlightColor: Color? = nil,
        wordBGColor: Color? = nil,
        activeWordScale: CGFloat = 1.2,
        presetName: String? = nil
    ) {
        // If presetName is provided, find and apply the preset values
        if let presetName = presetName, let preset = SubtitleStyle.allPresets.first(where: { $0.name == presetName }) {
            self.text = text
            self.fontSize = preset.fontSize
            self.lastFontSize = lastFontSize
            self.bgColor = preset.bgColor
            self.fontColor = preset.fontColor // Use preset's fontColor
            self.strokeColor = preset.strokeColor
            self.strokeWidth = preset.strokeWidth
            self.timeRange = timeRange
            self.offset = offset
            self.lastOffset = lastOffset
            self.backgroundPadding = preset.backgroundPadding
            self.cornerRadius = preset.cornerRadius
            self.shadowColor = preset.shadowColor
            self.shadowRadius = preset.shadowRadius
            self.shadowX = preset.shadowX
            self.shadowY = preset.shadowY
            self.shadowOpacity = preset.shadowOpacity
            self.wordTimings = wordTimings
            self.isKaraokePreset = isKaraokePreset
            if isKaraokePreset {
                self.karaokeType = karaokeType
                self.highlightColor = highlightColor
                self.wordBGColor = wordBGColor
            }
            
            // If this is a karaoke preset, set the karaoke colors from the preset
            if preset.isKaraokePreset {
                let karaokePreset: KaraokePreset
                switch preset.name {
                case "Highlight by word":
                    karaokePreset = .word
                case "Background by word":
                    karaokePreset = .wordbg
                case "Word & Scale":
                    karaokePreset = .wordAndScale
                default:
                    karaokePreset = .word
                }
                self.isKaraokePreset = true
                self.karaokeType = karaokePreset.karaokeType
                // Only set karaoke colors if they weren't explicitly provided
                if self.highlightColor == nil {
                    self.highlightColor = karaokePreset.highlightColor
                }
                if self.wordBGColor == nil {
                    self.wordBGColor = karaokePreset.wordBGColor
                }
            }
            self.activeWordScale = activeWordScale
            self.presetName = presetName
        } else {
            print("DEBUG: No presetName provided during TextBox initialization 🟡")
            // Use provided values (default behavior)
            self.text = text
            self.fontSize = fontSize
            self.lastFontSize = lastFontSize
            self.bgColor = bgColor
            self.fontColor = fontColor
            self.strokeColor = strokeColor
            self.strokeWidth = strokeWidth
            self.timeRange = timeRange
            self.offset = offset
            self.lastOffset = lastOffset
            self.backgroundPadding = backgroundPadding
            self.cornerRadius = cornerRadius
            self.shadowColor = shadowColor
            self.shadowRadius = shadowRadius
            self.shadowX = shadowX
            self.shadowY = shadowY
            self.shadowOpacity = shadowOpacity
            self.wordTimings = wordTimings
            self.isKaraokePreset = isKaraokePreset
            if isKaraokePreset {
                self.karaokeType = karaokeType
                self.highlightColor = highlightColor
                self.wordBGColor = wordBGColor
            }
            self.activeWordScale = activeWordScale
            self.presetName = presetName
        }
    }
    
    
}

extension TextBox: Equatable{}

struct SubtitleStyle: Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var fontSize: CGFloat
    var bgColor: Color
    var fontColor: Color
    var strokeColor: Color
    var strokeWidth: CGFloat
    var backgroundPadding: CGFloat
    var cornerRadius: CGFloat
    var shadowColor: Color
    var shadowRadius: CGFloat
    var shadowX: CGFloat
    var shadowY: CGFloat
    var shadowOpacity: Double
    var wordTimings: [WordWithTiming]? = nil
    var isKaraokePreset: Bool = false
    
    // Custom karaoke colors (used when user customizes karaoke presets)
    var customHighlightColor: Color? = nil
    var customWordBGColor: Color? = nil
    var customFontColor: Color? = nil
    
    // Optionally, provide a method to apply this style to a TextBox
    func apply(to textBox: TextBox) -> TextBox {
        print("DEBUG: Applying preset '\(name)' to TextBox")
        var box = textBox
        box.fontSize = fontSize
        box.bgColor = bgColor
        box.fontColor = customFontColor ?? fontColor
        box.strokeColor = strokeColor
        box.strokeWidth = strokeWidth
        box.backgroundPadding = backgroundPadding
        box.cornerRadius = cornerRadius
        box.shadowColor = shadowColor
        box.shadowRadius = shadowRadius
        box.shadowX = shadowX
        box.shadowY = shadowY
        box.shadowOpacity = shadowOpacity

        box.wordTimings = wordTimings
        
        if isKaraokePreset {
            // Get the correct karaoke preset based on the style name
            let karaokePreset: KaraokePreset
            switch name {
            case "Highlight by word":
                karaokePreset = .word
            case "Background by word":
                karaokePreset = .wordbg
            case "Word & Scale":
                karaokePreset = .wordAndScale
            default:
                karaokePreset = .word
            }
            box.isKaraokePreset = true
            box.karaokeType = karaokePreset.karaokeType
            
            // Use custom colors if available, otherwise use default preset colors
            box.highlightColor = customHighlightColor ?? karaokePreset.highlightColor
            box.wordBGColor = customWordBGColor ?? karaokePreset.wordBGColor
        }
        
        // Set the preset name
        box.presetName = name
        
        return box
    }

    static let allPresets: [SubtitleStyle] = [
        // Karaoke presets - see below struct KaraokePreset for more info
        SubtitleStyle(
            name: "Highlight by word",
            fontSize: 32,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .black,
            strokeWidth: 2,
            backgroundPadding: 8,
            cornerRadius: 8,
            shadowColor: .black,
            shadowRadius: 6,
            shadowX: 0,
            shadowY: 2,
            shadowOpacity: 0.7,
            isKaraokePreset: true
        ),
        SubtitleStyle(
            name: "Background by word",
            fontSize: 32,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .clear,
            strokeWidth: 0,
            backgroundPadding: 8,
            cornerRadius: 8,
            shadowColor: .clear,
            shadowRadius: 0,
            shadowX: 0,
            shadowY: 0,
            shadowOpacity: 0,
            isKaraokePreset: true
        ),
        SubtitleStyle(
            name: "Word & Scale",
            fontSize: 32,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .black,
            strokeWidth: 2,
            backgroundPadding: 8,
            cornerRadius: 8,
            shadowColor: .black,
            shadowRadius: 6,
            shadowX: 0,
            shadowY: 2,
            shadowOpacity: 0.7,
            isKaraokePreset: true
        ),
        // Non-karaoke presets
        SubtitleStyle(
            name: "Classic Yellow",
            fontSize: 32,
            bgColor: .clear,
            fontColor: .yellow,
            strokeColor: .black,
            strokeWidth: 2,
            backgroundPadding: 8,
            cornerRadius: 8,
            shadowColor: .black,
            shadowRadius: 6,
            shadowX: 0,
            shadowY: 2,
            shadowOpacity: 0.7,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Modern White",
            fontSize: 32,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .black,
            strokeWidth: 2,
            backgroundPadding: 8,
            cornerRadius: 8,
            shadowColor: .black,
            shadowRadius: 6,
            shadowX: 0,
            shadowY: 2,
            shadowOpacity: 0.7,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Bold Black",
            fontSize: 32,
            bgColor: .clear,
            fontColor: .black,
            strokeColor: .white,
            strokeWidth: 2,
            backgroundPadding: 8,
            cornerRadius: 8,
            shadowColor: .white,
            shadowRadius: 6,
            shadowX: 0,
            shadowY: 2,
            shadowOpacity: 0.7,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Shadowed",
            fontSize: 32,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .clear,
            strokeWidth: 0,
            backgroundPadding: 8,
            cornerRadius: 8,
            shadowColor: .black,
            shadowRadius: 8,
            shadowX: 2,
            shadowY: 2,
            shadowOpacity: 0.8,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Large Font",
            fontSize: 40,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .black,
            strokeWidth: 2,
            backgroundPadding: 8,
            cornerRadius: 8,
            shadowColor: .black,
            shadowRadius: 6,
            shadowX: 0,
            shadowY: 2,
            shadowOpacity: 0.7,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Outlined",
            fontSize: 32,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .black,
            strokeWidth: 4,
            backgroundPadding: 8,
            cornerRadius: 8,
            shadowColor: .clear,
            shadowRadius: 0,
            shadowX: 0,
            shadowY: 0,
            shadowOpacity: 0,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Minimalist",
            fontSize: 28,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .clear,
            strokeWidth: 0,
            backgroundPadding: 4,
            cornerRadius: 4,
            shadowColor: .clear,
            shadowRadius: 0,
            shadowX: 0,
            shadowY: 0,
            shadowOpacity: 0,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Retro",
            fontSize: 32,
            bgColor: .clear,
            fontColor: .orange,
            strokeColor: .brown,
            strokeWidth: 2,
            backgroundPadding: 8,
            cornerRadius: 8,
            shadowColor: .brown,
            shadowRadius: 6,
            shadowX: 2,
            shadowY: 2,
            shadowOpacity: 0.7,
            isKaraokePreset: false
        )
    ]
}

struct KaraokePreset {
    let karaokeType: KaraokeType
    let highlightColor: Color
    let wordBGColor: Color
    let presetName: String
    let previewWordSpacing: CGFloat
    let exportWordSpacing: CGFloat
    
    /// Calibrated export spacing that compensates for Core Animation vs SwiftUI rendering differences
    var calibratedExportSpacing: CGFloat {
        // Core Animation text rendering is typically more compact than SwiftUI
        // Apply a calibration multiplier based on empirical testing
        switch karaokeType {
        case .wordbg:
            // Background style: 1.5x multiplier (4pt preview → 6pt export)
            return previewWordSpacing * 1.5
        case .word, .wordAndScale:
            // Highlight styles: 3.0x multiplier (8pt preview → 24pt export) 
            return previewWordSpacing * 3.0
        }
    }

    static let word = KaraokePreset(
        karaokeType: .word,
        highlightColor: .blue,
        wordBGColor: .clear,
        presetName: "Highlight by word",
        previewWordSpacing: 8,
        exportWordSpacing: 16
    )
    static let wordbg = KaraokePreset(
        karaokeType: .wordbg,
        highlightColor: .yellow,
        wordBGColor: .blue,
        presetName: "Background by word",
        previewWordSpacing: 4,
        exportWordSpacing: 6
    )
    static let wordAndScale = KaraokePreset(
        karaokeType: .wordAndScale,
        highlightColor: .yellow,
        wordBGColor: .clear,
        presetName: "Word & Scale",
        previewWordSpacing: 8,
        exportWordSpacing: 16
    )
}
