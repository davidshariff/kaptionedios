import SwiftUI

struct KaraokeSubsHelper {
    static func generateKaraokeSubs(
        for video: Video,
        karaokeType: KaraokeType = .word,
        textBoxes: [TextBox] = [],
        customHighlightColor: Color? = nil,
        customWordBGColor: Color? = nil,
        customFontColor: Color? = nil
    ) -> [TextBox] {
        print("DEBUG: KaraokeSubsHelper - received custom colors - highlight: \(customHighlightColor?.description ?? "nil"), wordBG: \(customWordBGColor?.description ?? "nil"), font: \(customFontColor?.description ?? "nil")")
        
        // Get the appropriate karaoke preset based on the type
        let preset: KaraokePreset
        switch karaokeType {
        case .word:
            preset = KaraokePreset.word
        case .wordbg:
            preset = KaraokePreset.wordbg
        }
        var boxes: [TextBox] = []
        for textBox in textBoxes {
            let words = textBox.text.split(separator: " ").map(String.init)
            let lineDuration = textBox.timeRange.upperBound - textBox.timeRange.lowerBound
            let wordDuration = lineDuration / Double(words.count)
            var wordTimings: [WordWithTiming] = []
            for (j, word) in words.enumerated() {
                let wordStart = textBox.timeRange.lowerBound + Double(j) * wordDuration
                let wordEnd = wordStart + wordDuration
                wordTimings.append(WordWithTiming(text: word, start: wordStart, end: wordEnd))
            }
            let box = TextBox(
                text: textBox.text,
                fontSize: textBox.fontSize,
                lastFontSize: textBox.lastFontSize,
                bgColor: textBox.bgColor,
                fontColor: customFontColor ?? textBox.fontColor,
                strokeColor: textBox.strokeColor,
                strokeWidth: textBox.strokeWidth,
                timeRange: textBox.timeRange,
                offset: textBox.offset,
                lastOffset: textBox.lastOffset,
                backgroundPadding: textBox.backgroundPadding,
                cornerRadius: textBox.cornerRadius,
                shadowColor: textBox.shadowColor,
                shadowRadius: textBox.shadowRadius,
                shadowX: textBox.shadowX,
                shadowY: textBox.shadowY,
                shadowOpacity: textBox.shadowOpacity,
                wordTimings: wordTimings,
                isKaraokePreset: true,
                karaokeType: karaokeType,
                highlightColor: customHighlightColor ?? preset.highlightColor,
                wordBGColor: customWordBGColor ?? preset.wordBGColor,
                presetName: preset.presetName
            )
            boxes.append(box)
        }
        return boxes
    }
} 