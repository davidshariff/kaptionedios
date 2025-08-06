import SwiftUI

struct KaraokeSubsHelper {
    static func generateKaraokeSubs(
        for video: Video,
        karaokeType: KaraokeType = .letter,
        lines: [(text: String, start: Double, end: Double)] = []
    ) -> [TextBox] {
        let w = video.frameSize.width
        let h = video.frameSize.height
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
        let preset: KaraokePreset
        switch karaokeType {
        case .letter:
            preset = KaraokePreset.letter
        case .word:
            preset = KaraokePreset.word
        case .wordbg:
            preset = KaraokePreset.wordbg
        }
        var boxes: [TextBox] = []
        for (i, lineData) in lines.enumerated() {
            let words = lineData.text.split(separator: " ").map(String.init)
            let lineDuration = lineData.end - lineData.start
            let wordDuration = lineDuration / Double(words.count)
            var wordTimings: [WordWithTiming] = []
            for (j, word) in words.enumerated() {
                let wordStart = lineData.start + Double(j) * wordDuration
                let wordEnd = wordStart + wordDuration
                wordTimings.append(WordWithTiming(text: word, start: wordStart, end: wordEnd))
            }
            let box = TextBox(
                text: lineData.text,
                fontSize: fontSizes[i % fontSizes.count],
                bgColor: bgColors[i % bgColors.count],
                fontColor: fontColors[i % fontColors.count],
                strokeColor: strokeColors[i % strokeColors.count],
                strokeWidth: strokeWidths[i % strokeWidths.count],
                timeRange: lineData.start...lineData.end,
                offset: offsets[i % offsets.count],
                backgroundPadding: backgroundPaddings[i % backgroundPaddings.count],
                cornerRadius: cornerRadii[i % cornerRadii.count],
                shadowColor: shadowColors[i % shadowColors.count],
                shadowRadius: shadowRadii[i % shadowRadii.count],
                shadowX: shadowXs[i % shadowXs.count],
                shadowY: shadowYs[i % shadowYs.count],
                shadowOpacity: shadowOpacities[i % shadowOpacities.count],
                wordTimings: wordTimings,
                karaokeType: karaokeType,
                highlightColor: preset.highlightColor,
                wordBGColor: preset.wordBGColor
            )
            boxes.append(box)
        }
        return boxes
    }
} 