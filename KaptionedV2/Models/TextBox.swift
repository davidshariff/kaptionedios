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
        text: String? = nil,
        fontSize: CGFloat? = nil,
        lastFontSize: CGFloat? = nil,
        bgColor: Color? = nil,
        fontColor: Color? = nil,
        strokeColor: Color? = nil,
        strokeWidth: CGFloat? = nil,
        timeRange: ClosedRange<Double>? = nil,
        offset: CGSize? = nil,
        lastOffset: CGSize? = nil,
        backgroundPadding: CGFloat? = nil,
        cornerRadius: CGFloat? = nil,
        shadowColor: Color? = nil,
        shadowRadius: CGFloat? = nil,
        shadowX: CGFloat? = nil,
        shadowY: CGFloat? = nil,
        shadowOpacity: Double? = nil,
        wordTimings: [WordWithTiming]? = nil,
        isKaraokePreset: Bool? = nil,
        karaokeType: KaraokeType? = nil,
        highlightColor: Color? = nil,
        wordBGColor: Color? = nil,
        activeWordScale: CGFloat? = nil,
        presetName: String? = nil
    ) {
        // If presetName is provided, use the preset values if they are not provided,
        // otherwise use the provided values
        if let presetName = presetName, let preset = SubtitleStyle.availablePresets.first(where: { $0.name == presetName }) {

            self.text = text ?? ""
            self.fontSize = (fontSize != nil && fontSize != 0) ? fontSize! : preset.fontSize
            self.lastFontSize = lastFontSize ?? .zero
            self.bgColor = (bgColor != nil && bgColor != .clear) ? bgColor! : preset.bgColor
            self.fontColor = (fontColor != nil && fontColor != .clear) ? fontColor! : preset.fontColor
            self.strokeColor = (strokeColor != nil && strokeColor != .clear) ? strokeColor! : preset.strokeColor
            self.strokeWidth = (strokeWidth != nil && strokeWidth != 0) ? strokeWidth! : preset.strokeWidth
            self.timeRange = timeRange ?? 0...3
            self.offset = offset ?? .zero
            self.lastOffset = lastOffset ?? .zero
            self.backgroundPadding = (backgroundPadding != nil && backgroundPadding != 0) ? backgroundPadding! : preset.backgroundPadding
            self.cornerRadius = (cornerRadius != nil && cornerRadius != 0) ? cornerRadius! : preset.cornerRadius
            self.shadowColor = (shadowColor != nil && shadowColor != .clear) ? shadowColor! : preset.shadowColor
            self.shadowRadius = (shadowRadius != nil && shadowRadius != 0) ? shadowRadius! : preset.shadowRadius
            self.shadowX = (shadowX != nil && shadowX != 0) ? shadowX! : preset.shadowX
            self.shadowY = (shadowY != nil && shadowY != 0) ? shadowY! : preset.shadowY
            self.shadowOpacity = (shadowOpacity != nil && shadowOpacity != 0) ? shadowOpacity! : preset.shadowOpacity
            self.wordTimings = wordTimings
            
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

            self.activeWordScale = activeWordScale ?? 1.2
            self.presetName = presetName
            
        } else {
            print("DEBUG: No presetName provided during TextBox initialization 🟡")
            // Use provided values (default behavior)
            self.text = text ?? ""
            self.fontSize = fontSize ?? 20
            self.lastFontSize = lastFontSize ?? .zero
            self.bgColor = bgColor ?? .white
            self.fontColor = fontColor ?? .black
            self.strokeColor = strokeColor ?? .clear
            self.strokeWidth = strokeWidth ?? 0
            self.timeRange = timeRange ?? 0...3
            self.offset = offset ?? .zero
            self.lastOffset = lastOffset ?? .zero
            self.backgroundPadding = backgroundPadding ?? 8
            self.cornerRadius = cornerRadius ?? 0
            self.shadowColor = shadowColor ?? .black
            self.shadowRadius = shadowRadius ?? 0
            self.shadowX = shadowX ?? 0
            self.shadowY = shadowY ?? 0
            self.shadowOpacity = shadowOpacity ?? 0.5
            self.wordTimings = wordTimings
            self.isKaraokePreset = isKaraokePreset ?? false
            if isKaraokePreset == true {
                self.karaokeType = karaokeType
                self.highlightColor = highlightColor
                self.wordBGColor = wordBGColor
            }
            self.activeWordScale = activeWordScale ?? 1.2
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

    // Convert remote preset to local SubtitleStyle
    static func fromRemote(_ remote: RemoteSubtitleStyle) -> SubtitleStyle {
        return SubtitleStyle(
            name: remote.name,
            fontSize: CGFloat(remote.fontSize),
            bgColor: Color(hex: remote.bgColor),
            fontColor: Color(hex: remote.fontColor),
            strokeColor: Color(hex: remote.strokeColor),
            strokeWidth: CGFloat(remote.strokeWidth),
            backgroundPadding: CGFloat(remote.backgroundPadding),
            cornerRadius: CGFloat(remote.cornerRadius),
            shadowColor: Color(hex: remote.shadowColor),
            shadowRadius: CGFloat(remote.shadowRadius),
            shadowX: CGFloat(remote.shadowX),
            shadowY: CGFloat(remote.shadowY),
            shadowOpacity: remote.shadowOpacity,
            isKaraokePreset: remote.isKaraokePreset
        )
    }
    
    // Get all available presets (merged built-in + remote, minus excluded)
    static var availablePresets: [SubtitleStyle] {
        let configManager = ConfigurationManager.shared
        var presets: [SubtitleStyle] = []
        
        // Start with built-in presets
        presets = allPresets
        
        // Add remote presets if available
        if let remotePresets = configManager.getRemotePresets() {
            let remoteStyles = remotePresets.map { SubtitleStyle.fromRemote($0) }
            
            // Merge remote presets (replace existing ones with same name, add new ones)
            for remoteStyle in remoteStyles {
                if let existingIndex = presets.firstIndex(where: { $0.name == remoteStyle.name }) {
                    // Replace existing preset with remote version
                    presets[existingIndex] = remoteStyle
                    print("[SubtitleStyle] Replaced built-in preset '\(remoteStyle.name)' with remote version")
                } else {
                    // Add new remote preset
                    presets.append(remoteStyle)
                    print("[SubtitleStyle] Added new remote preset '\(remoteStyle.name)'")
                }
            }
        }
        
        // Remove excluded presets
        let excludedPresets = configManager.getExcludedPresets()
        if !excludedPresets.isEmpty {
            presets = presets.filter { !excludedPresets.contains($0.name) }
            print("[SubtitleStyle] Excluded \(excludedPresets.count) presets: \(excludedPresets.joined(separator: ", "))")
        }
        
        return presets
    }
    
    static let allPresets: [SubtitleStyle] = [

        // Karaoke presets - see below struct KaraokePreset for more info
        SubtitleStyle(
            name: "Highlight by word", // confirmed style: https://www.tiktok.com/@healthy.tips15/video/7520399199410588950?is_from_webapp=1&sender_device=pc
            fontSize: 24,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .black,
            strokeWidth: 5,
            backgroundPadding: 0,
            cornerRadius: 0,
            shadowColor: .black,
            shadowRadius: 2,
            shadowX: 2,
            shadowY: 2,
            shadowOpacity: 1,
            isKaraokePreset: true
        ),
        SubtitleStyle(
            name: "Background by word", // confirmed style: https://www.tiktok.com/t/ZT6aERhMF/
            fontSize: 24,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .black,
            strokeWidth: 5,
            backgroundPadding: 8,
            cornerRadius: 8,
            shadowColor: .black,
            shadowRadius: 2,
            shadowX: 2,
            shadowY: 2,
            shadowOpacity: 1,
            isKaraokePreset: true
        ),
        SubtitleStyle(
            name: "Word & Scale", // confirmed style.
            fontSize: 24,
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
            name: "Modern White", // confirmed style
            fontSize: 24,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .black,
            strokeWidth: 2,
            backgroundPadding: 8,
            cornerRadius: 8,
            shadowColor: .black,
            shadowRadius: 2,
            shadowX: 2,
            shadowY: 2,
            shadowOpacity: 0.7,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Outlined", // confirmed style
            fontSize: 24,
            bgColor: .clear,
            fontColor: .yellow,
            strokeColor: .black,
            strokeWidth: 4,
            backgroundPadding: 0,
            cornerRadius: 0,
            shadowColor: .clear,
            shadowRadius: 0,
            shadowX: 0,
            shadowY: 0,
            shadowOpacity: 0,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Minimalist", // confirmed style
            fontSize: 24,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .clear,
            strokeWidth: 0,
            backgroundPadding: 0,
            cornerRadius: 0,
            shadowColor: .clear,
            shadowRadius: 0,
            shadowX: 0,
            shadowY: 0,
            shadowOpacity: 0,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Bold Shadow Pop", // confirmed style: https://www.tiktok.com/@debatedigest5/video/7515131366774803754?is_from_webapp=1&sender_device=pc
            fontSize: 24,
            bgColor: .clear,
            fontColor: .white,
            strokeColor: .black,
            strokeWidth: 6,
            backgroundPadding: 0,
            cornerRadius: 0,
            shadowColor: .black,
            shadowRadius: 2,
            shadowX: -3,
            shadowY: 3,
            shadowOpacity: 0.8,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Pop Art Bold", // confirmed style: https://www.tiktok.com/@mattpaige68/video/7530643035198065934?is_from_webapp=1&sender_device=pc
            fontSize: 24,
            bgColor: .clear,
            fontColor: .yellow,
            strokeColor: .black,
            strokeWidth: 10,
            backgroundPadding: 0,
            cornerRadius: 0,
            shadowColor: Color(red: 1.0, green: 0.3, blue: 0.0),
            shadowRadius: 1,
            shadowX: 1,
            shadowY: 2,
            shadowOpacity: 0.8,
            isKaraokePreset: false
        ),
        
        // New modern social media styles
        SubtitleStyle(
            name: "Neon Glow",
            fontSize: 24,
            bgColor: .clear,
            fontColor: Color(red: 0.0, green: 1.0, blue: 0.8), // Cyan
            strokeColor: Color(red: 0.0, green: 0.8, blue: 1.0), // Light blue
            strokeWidth: 3,
            backgroundPadding: 0,
            cornerRadius: 0,
            shadowColor: Color(red: 0.0, green: 1.0, blue: 0.8),
            shadowRadius: 8,
            shadowX: 0,
            shadowY: 0,
            shadowOpacity: 0.9,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Retro Wave", // confirmed style
            fontSize: 24,
            bgColor: Color(red: 0.8, green: 0.2, blue: 0.8), // Purple
            fontColor: Color(red: 1.0, green: 0.8, blue: 0.0), // Gold
            strokeColor: .black,
            strokeWidth: 2,
            backgroundPadding: 10,
            cornerRadius: 12,
            shadowColor: Color(red: 0.6, green: 0.0, blue: 0.8),
            shadowRadius: 4,
            shadowX: 2,
            shadowY: 2,
            shadowOpacity: 0.8,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Minimal Dark", // confirmed style
            fontSize: 24,
            bgColor: Color.black.opacity(1),
            fontColor: .white,
            strokeColor: .clear,
            strokeWidth: 0,
            backgroundPadding: 16,
            cornerRadius: 20,
            shadowColor: .black,
            shadowRadius: 6,
            shadowX: 0,
            shadowY: 3,
            shadowOpacity: 0.4,
            isKaraokePreset: false
        ),
        SubtitleStyle(
            name: "Bubble Pop", // confirmed style
            fontSize: 24,
            bgColor: Color(red: 1.0, green: 0.4, blue: 0.6), // Pink
            fontColor: .white,
            strokeColor: Color(red: 0.8, green: 0.2, blue: 0.4), // Darker pink
            strokeWidth: 1,
            backgroundPadding: 14,
            cornerRadius: 25,
            shadowColor: Color(red: 0.6, green: 0.1, blue: 0.3),
            shadowRadius: 8,
            shadowX: 0,
            shadowY: 4,
            shadowOpacity: 0.6,
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
        highlightColor: .yellow,
        wordBGColor: .clear,
        presetName: "Highlight by word",
        previewWordSpacing: 8,
        exportWordSpacing: 16
    )
    static let wordbg = KaraokePreset(
        karaokeType: .wordbg,
        highlightColor: Color.white,
        wordBGColor: .pink,
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
        exportWordSpacing: 10
    )
}
