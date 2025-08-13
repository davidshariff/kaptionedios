import SwiftUI
import Foundation

struct PresetPreviewView: View {
    let preset: SubtitleStyle
    let previewText: String
    let highlightColor: Color?
    let wordBGColor: Color?
    let fontColor: Color?
    let animateKaraoke: Bool
    let fontSize: CGFloat
    
    @State private var animationIndex: Int = 0
    @State private var animationTimer: Timer?
    
    private var previewWords: [String] {
        return previewText.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    init(preset: SubtitleStyle, previewText: String = "Sample Text", highlightColor: Color? = nil, wordBGColor: Color? = nil, fontColor: Color? = nil, animateKaraoke: Bool = false, fontSize: CGFloat = 12) {
        self.preset = preset
        self.previewText = previewText
        self.highlightColor = highlightColor
        self.wordBGColor = wordBGColor
        self.fontColor = fontColor
        self.animateKaraoke = animateKaraoke
        self.fontSize = fontSize
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: preset.cornerRadius)
            .fill(preset.bgColor)
            .frame(height: 32)
            .overlay(
                HStack(spacing: 4) {
                    if preset.isKaraokePreset && previewWords.count > 1 {
                        // Karaoke preview with word-by-word animation
                        ForEach(Array(previewWords.enumerated()), id: \.offset) { index, word in
                            Text(word)
                                .font(.system(size: fontSize))
                                .foregroundColor(getWordColor(for: index))
                                .lineLimit(1)
                                .background(
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(getWordBackground(for: index))
                                        .padding(.horizontal, -2)
                                        .padding(.vertical, -1)
                                        .opacity(getWordBackground(for: index) == .clear ? 0 : 1)
                                )
                                .animation(.easeInOut(duration: 0.3), value: animationIndex)
                        }
                    } else {
                        // Regular preview
                        Text(previewText.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.system(size: fontSize))
                            .foregroundColor(fontColor ?? preset.fontColor)
                            .lineLimit(1)
                            .shadow(color: preset.shadowColor.opacity(preset.shadowOpacity), radius: preset.shadowRadius, x: preset.shadowX, y: preset.shadowY)
                    }
                }
            )
            .onAppear {
                if animateKaraoke && preset.isKaraokePreset {
                    startAnimation()
                }
            }
            .onDisappear {
                stopAnimation()
            }
    }
    
    // Animation helper functions
    private func getWordColor(for index: Int) -> Color {
        
        if preset.name == "Background by word" {
            // For background by word, use highlight color for active word text, font color for inactive
            let activeHighlightColor = highlightColor ?? getDefaultHighlightColor()
            let inactiveFontColor = fontColor ?? preset.fontColor
            let result = index == animationIndex ? activeHighlightColor : inactiveFontColor
            return result
        } else if preset.name == "Highlight by word" {
            // For highlight by word, use highlight color for active word, font color for inactive
            let activeHighlightColor = highlightColor ?? getDefaultHighlightColor()
            let inactiveFontColor = fontColor ?? preset.fontColor
            let result = index == animationIndex ? activeHighlightColor : inactiveFontColor
            return result
        } else {
            // For other presets, just use font color
            let result = fontColor ?? preset.fontColor
            return result
        }
    }
    
    private func getWordBackground(for index: Int) -> Color {
        if preset.name == "Background by word" && index == animationIndex {
            // For background by word, use wordBGColor for the background
            return wordBGColor ?? getDefaultWordBGColor()
        }
        return .clear
    }
    
    private func getDefaultHighlightColor() -> Color {
        switch preset.name {
            case "Highlight by word":
                return KaraokePreset.word.highlightColor
            case "Background by word":
                return KaraokePreset.wordbg.highlightColor
            default:
                return .white
        }
    }
    
    private func getDefaultWordBGColor() -> Color {
        switch preset.name {
            case "Background by word":
                return KaraokePreset.wordbg.wordBGColor
            default:
                return .clear
        }
    }
    
    private func startAnimation() {
        guard previewWords.count > 1 else { return }
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                animationIndex = (animationIndex + 1) % previewWords.count
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

#Preview {
    VStack(spacing: 20) {
        PresetPreviewView(
            preset: SubtitleStyle.allPresets.first(where: { $0.name == "Basic" })!,
            previewText: "Sample Text"
        )
        
        PresetPreviewView(
            preset: SubtitleStyle.allPresets.first(where: { $0.name == "Highlight by word" })!,
            previewText: "Animated Karaoke Text",
            highlightColor: .orange,
            animateKaraoke: true
        )
        
        PresetPreviewView(
            preset: SubtitleStyle.allPresets.first(where: { $0.name == "Background by word" })!,
            previewText: "Background Karaoke",
            wordBGColor: .blue,
            fontColor: .white,
            animateKaraoke: true
        )
    }
    .padding()
}
