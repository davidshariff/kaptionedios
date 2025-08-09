import SwiftUI
import UIKit

struct TextOnPlayerView: View {
    
    var currentTime: Double
    @ObservedObject var viewModel: TextEditorViewModel
    var originalVideoSize: CGSize
    var videoScale: CGFloat = 1.0
    @Binding var showEditSubtitlesMode: Bool
    @Environment(\.videoSize) private var videoSize
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                magnificationGestureView
                textBoxesView
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()

        }
    }
    
    @ViewBuilder
    private var magnificationGestureView: some View {
        Color.secondary.opacity(0.001)
            .simultaneousGesture(magnificationGesture)
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if let box = viewModel.selectedTextBox {
                    let lastFontSize = viewModel.textBoxes[getIndex(box.id)].lastFontSize
                    viewModel.textBoxes[getIndex(box.id)].fontSize = (value * 10) + lastFontSize
                }
            }
            .onEnded { value in
                if let box = viewModel.selectedTextBox {
                    viewModel.textBoxes[getIndex(box.id)].lastFontSize = value * 10
                }
            }
    }
    
    // find the textbox that is currently on screen
    @ViewBuilder
    private var textBoxesView: some View {
        ForEach(viewModel.textBoxes) { textBox in
            let isSelected = viewModel.isSelected(textBox.id)
            
            // Display only the textbox that is currently on screen
            // Use a more precise condition to avoid showing multiple text boxes
            let isInTimeRange = textBox.timeRange.lowerBound <= currentTime && currentTime < textBox.timeRange.upperBound
            if isInTimeRange {
                // Debug: Print current textbox on screen
                let _ = print("📝 Current TextBox: \(textBox) | Time: \(currentTime) | Selected: \(isSelected)")
                textBoxView(textBox: textBox, isSelected: isSelected)
            }
        }
    }
    
    @ViewBuilder
    private func textBoxView(textBox: TextBox, isSelected: Bool) -> some View {
        ZStack(alignment: .topLeading) {

            textContent(textBox: textBox, isSelected: isSelected)
            .overlay(alignment: .topLeading) {
                if isSelected {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 20, height: 20)
                                .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.purple)
                        }
                        .overlay(
                            Circle()
                                .stroke(Color.purple, lineWidth: 1.5)
                        )
                        Spacer(minLength: 0)
                    }
                    .offset(y: -16)
                }
            }

        }
        // Scale the content
        .scaleEffect(calculateScaleFactor())
        // Scale the position as well
        .offset(CGSize(
            width: textBox.offset.width * calculateScaleFactor(),
            height: textBox.offset.height * calculateScaleFactor()
        ))
        .simultaneousGesture(dragGesture(for: textBox, isSelected: isSelected))

    }
    
    private func calculateScaleFactor() -> CGFloat {
        // Simple approach: scale based on video size ratio
        if videoSize.width > 0 && videoSize.height > 0 && originalVideoSize.width > 0 && originalVideoSize.height > 0 {
            let scaleX = videoSize.width / originalVideoSize.width
            let scaleY = videoSize.height / originalVideoSize.height
            let scale = min(scaleX, scaleY) // Use the smaller scale to maintain aspect ratio
            
            return scale
        }
        return 1.0
    }
    
    private func getScaledFontSize(_ originalFontSize: CGFloat) -> CGFloat {
        return originalFontSize * calculateScaleFactor()
    }
    
    private func getScaledPadding(_ originalPadding: CGFloat) -> CGFloat {
        return originalPadding * calculateScaleFactor()
    }
    
    @ViewBuilder
    private func textContent(textBox: TextBox, isSelected: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: textBox.cornerRadius)
                .fill(textBox.bgColor)
            
            textOverlay(textBox: textBox, isSelected: isSelected)
        }
        .fixedSize()
                  .contentShape(Rectangle())
          .onTapGesture {
              if showEditSubtitlesMode {
                  editOrSelectTextBox(textBox, isSelected)
              }
              else {
                  showEditSubtitlesMode = true
                  viewModel.selectedTextBox = textBox
              }
          }
    }
    
    @ViewBuilder
    private func textOverlay(textBox: TextBox, isSelected: Bool) -> some View {

        if textBox.isKaraokePreset {
            if let wordTimings = textBox.wordTimings, 
               let karaokeType = textBox.karaokeType,
               let highlightColor = textBox.highlightColor,
               karaokeType == .letter {
                KaraokeTextByLetterHighlightOverlay(
                    text: textBox.text,
                    words: wordTimings,
                    fontSize: textBox.fontSize,
                    fontColor: textBox.fontColor,
                    highlightColor: highlightColor,
                    currentTime: currentTime
                )
                .padding(.horizontal, textBox.backgroundPadding)
                .padding(.vertical, textBox.backgroundPadding / 2)
            } 
            else if let wordTimings = textBox.wordTimings, 
                    let karaokeType = textBox.karaokeType,
                    let highlightColor = textBox.highlightColor,
                    karaokeType == .word {
                KaraokeTextByWordHighlightOverlay(
                    text: textBox.text,
                    words: wordTimings,
                    fontSize: textBox.fontSize,
                    fontColor: textBox.fontColor,
                    highlightColor: highlightColor,
                    strokeColor: textBox.strokeColor,
                    strokeWidth: textBox.strokeWidth,
                    shadowColor: textBox.shadowColor,
                    shadowRadius: textBox.shadowRadius,
                    shadowX: textBox.shadowX,
                    shadowY: textBox.shadowY,
                    shadowOpacity: textBox.shadowOpacity,
                    currentTime: currentTime
                )
                .padding(.horizontal, textBox.backgroundPadding)
                .padding(.vertical, textBox.backgroundPadding / 2)
            } 
            else if let wordTimings = textBox.wordTimings, 
                    let karaokeType = textBox.karaokeType,
                    let highlightColor = textBox.highlightColor,
                    let wordBGColor = textBox.wordBGColor,
                    karaokeType == .wordbg {
                KaraokeTextByWordBackgroundOverlay(
                    text: textBox.text,
                    words: wordTimings,
                    fontSize: textBox.fontSize,
                    fontColor: textBox.fontColor,
                    highlightColor: highlightColor,
                    wordBGColor: wordBGColor,
                    strokeColor: textBox.strokeColor,
                    strokeWidth: textBox.strokeWidth,
                    shadowColor: textBox.shadowColor,
                    shadowRadius: textBox.shadowRadius,
                    shadowX: textBox.shadowX,
                    shadowY: textBox.shadowY,
                    shadowOpacity: textBox.shadowOpacity,
                    currentTime: currentTime
                )
                .padding(.horizontal, textBox.backgroundPadding)
                .padding(.vertical, textBox.backgroundPadding / 2)
            } 
        }
        else {
            ZStack {
                // Stroke layer (background)
                if let strokeAttr = createStrokeAttr(textBox) {
                    AttributedTextOverlay(
                        attributedString: strokeAttr,
                        offset: .zero,
                        isSelected: false, // No selection border on stroke layer
                        bgColor: .clear,
                        cornerRadius: textBox.cornerRadius,
                        shadowColor: UIColor.clear, // No shadow on stroke layer
                        shadowRadius: 0,
                        shadowX: 0,
                        shadowY: 0
                    )
                }
                
                // Main text layer (foreground)
                AttributedTextOverlay(
                    attributedString: createNSAttr(textBox),
                    offset: .zero,
                    isSelected: isSelected,
                    bgColor: .clear,
                    cornerRadius: textBox.cornerRadius,
                    shadowColor: UIColor(textBox.shadowColor).withAlphaComponent(textBox.shadowOpacity),
                    shadowRadius: textBox.shadowRadius,
                    shadowX: textBox.shadowX,
                    shadowY: textBox.shadowY
                )
            }
            .padding(.horizontal, textBox.backgroundPadding)
            .padding(.vertical, textBox.backgroundPadding / 2)
        }
    }
    
    private func dragGesture(for textBox: TextBox, isSelected: Bool) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard isSelected else { return }
                let current = value.translation
                let lastOffset = textBox.lastOffset
                let newTranslation: CGSize = .init(width: current.width + lastOffset.width, height: current.height + lastOffset.height)
                
                DispatchQueue.main.async {
                    viewModel.textBoxes[getIndex(textBox.id)].offset = newTranslation
                }
            }
            .onEnded { value in
                guard isSelected else { return }
                DispatchQueue.main.async {
                    viewModel.textBoxes[getIndex(textBox.id)].lastOffset = CGSize(
                        width: textBox.offset.width,
                        height: textBox.offset.height
                    )
                }
            }
    }
    
}

    
private func createNSAttr(_ textBox: TextBox) -> NSAttributedString {
    let attrStr = NSMutableAttributedString(string: textBox.text)
    let range = NSRange(location: 0, length: attrStr.length)
    
    attrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: textBox.fontSize, weight: .medium), range: range)
    attrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(textBox.fontColor), range: range)
    attrStr.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor(textBox.bgColor), range: range)
    
    // Apply shadow if needed
    if textBox.shadowRadius > 0 && textBox.shadowOpacity > 0 {
        let shadow = NSShadow()
        shadow.shadowColor = UIColor(textBox.shadowColor).withAlphaComponent(textBox.shadowOpacity)
        shadow.shadowBlurRadius = textBox.shadowRadius
        shadow.shadowOffset = CGSize(width: textBox.shadowX, height: textBox.shadowY)
        attrStr.addAttribute(.shadow, value: shadow, range: range)
    }
    
    return attrStr
}

// Create stroke-only attributed string for the background layer
private func createStrokeAttr(_ textBox: TextBox) -> NSAttributedString? {
    guard textBox.strokeColor != .clear && textBox.strokeWidth > 0 else { return nil }
    
    let attrStr = NSMutableAttributedString(string: textBox.text)
    let range = NSRange(location: 0, length: attrStr.length)
    
    // Scale stroke width relative to font size for better proportions
    let scaledStrokeWidth = min(textBox.strokeWidth, textBox.fontSize * 0.15) // Max 15% of font size
    
    attrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: textBox.fontSize, weight: .medium), range: range)
    attrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear, range: range) // Transparent fill
    attrStr.addAttribute(NSAttributedString.Key.strokeColor, value: UIColor(textBox.strokeColor), range: range)
    attrStr.addAttribute(NSAttributedString.Key.strokeWidth, value: scaledStrokeWidth, range: range) // Positive for stroke-only
    
    return attrStr
}

extension TextOnPlayerView {
    
    private func textBoxButtons(_ textBox: TextBox) -> some View{
        HStack(spacing: 10){
            Button {
                viewModel.copy(textBox)
            } label: {
                Image(systemName: "doc.on.doc")
                    .imageScale(.small)
                    .padding(5)
                    .background(Color(.systemGray2), in: Circle())
            }
        }
        .foregroundColor(.white)
    }
    
    private func editOrSelectTextBox(_ textBox: TextBox, _ isSelected: Bool){
        // Always open text editor directly when tapping text
        viewModel.openTextEditor(isEdit: true, textBox)
    }
    
    private func getIndex(_ id: UUID) -> Int{
        let index = viewModel.textBoxes.firstIndex(where: {$0.id == id})
        return index ?? 0
    }
}

// UIViewRepresentable for NSAttributedString rendering
struct AttributedTextOverlay: UIViewRepresentable {
    let attributedString: NSAttributedString
    let offset: CGSize
    let isSelected: Bool
    let bgColor: UIColor
    let cornerRadius: CGFloat
    let shadowColor: UIColor
    let shadowRadius: CGFloat
    let shadowX: CGFloat
    let shadowY: CGFloat

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = bgColor
        label.layer.cornerRadius = cornerRadius
        label.layer.masksToBounds = true
        
        // Enable high-quality text rendering for smooth strokes
        label.layer.shouldRasterize = false
        label.layer.contentsScale = UIScreen.main.scale
        label.layer.allowsEdgeAntialiasing = true
        
        // Apply shadow
        label.layer.shadowColor = shadowColor.cgColor
        label.layer.shadowRadius = shadowRadius
        label.layer.shadowOpacity = Float(shadowColor.cgColor.alpha)
        label.layer.shadowOffset = CGSize(width: shadowX, height: shadowY)
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedString
        uiView.sizeToFit()
        uiView.frame = CGRect(origin: .zero, size: uiView.intrinsicContentSize)
        uiView.backgroundColor = bgColor
        uiView.layer.cornerRadius = cornerRadius
        uiView.layer.masksToBounds = true
        
        // Ensure high-quality rendering is maintained
        uiView.layer.shouldRasterize = false
        uiView.layer.contentsScale = UIScreen.main.scale
        uiView.layer.allowsEdgeAntialiasing = true
        
        // Selection border
        if isSelected {
            uiView.layer.borderColor = UIColor.cyan.cgColor
            uiView.layer.borderWidth = 1
        } else {
            uiView.layer.borderWidth = 0
        }
        // Update shadow
        uiView.layer.shadowColor = shadowColor.cgColor
        uiView.layer.shadowRadius = shadowRadius
        uiView.layer.shadowOpacity = Float(shadowColor.cgColor.alpha)
        uiView.layer.shadowOffset = CGSize(width: shadowX, height: shadowY)
    }
} 

// KaraokeTextOverlay SwiftUI view
struct KaraokeTextByLetterHighlightOverlay: View {

    let text: String
    let words: [WordWithTiming]
    let fontSize: CGFloat
    let fontColor: Color
    let highlightColor: Color
    let currentTime: Double

    var body: some View {
        // Letter-by-letter highlighting
        HStack(spacing: 2) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                let letterStart = getLetterStartTime(for: index)
                let letterEnd = getLetterEndTime(for: index)
                let isActive = currentTime >= letterStart && currentTime < letterEnd
                let progress: CGFloat = isActive ? CGFloat((currentTime - letterStart) / (letterEnd - letterStart)) : (currentTime >= letterEnd ? 1 : 0)
                
                ZStack(alignment: .leading) {
                    // Base text (entire string)
                    Text(String(character))
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(fontColor)
                    // Animated text
                    Text(String(character))
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(highlightColor)
                        .mask(
                            GeometryReader { geo in
                                let width = geo.size.width * progress
                                Rectangle()
                                    .frame(width: width, height: geo.size.height)
                                    .animation(.linear(duration: 0.05), value: progress)
                            }
                        )
                }
            }
        }
    }
    
    private func getLetterStartTime(for index: Int) -> Double {
        let totalLetters = text.count
        let totalDuration = words.last?.end ?? 0
        let letterDuration = totalDuration / Double(totalLetters)
        return Double(index) * letterDuration
    }
    
    private func getLetterEndTime(for index: Int) -> Double {
        let totalLetters = text.count
        let totalDuration = words.last?.end ?? 0
        let letterDuration = totalDuration / Double(totalLetters)
        return Double(index + 1) * letterDuration
    }
}

struct KaraokeTextByWordHighlightOverlay: View {

    let text: String
    let words: [WordWithTiming]
    let fontSize: CGFloat
    let fontColor: Color
    let highlightColor: Color
    let strokeColor: Color
    let strokeWidth: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowX: CGFloat
    let shadowY: CGFloat
    let shadowOpacity: Double
    let currentTime: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(words) { word in
                let isActive = currentTime >= word.start && currentTime < word.end
                let progress: CGFloat = isActive ? 1 : (currentTime >= word.end ? 1 : 0)
                
                ZStack(alignment: .leading) {
                    // Base text with stroke and shadow support
                    StrokeText(
                        text: word.text,
                        fontSize: fontSize,
                        fontColor: fontColor,
                        strokeColor: strokeColor,
                        strokeWidth: strokeWidth,
                        shadowColor: shadowColor,
                        shadowRadius: shadowRadius,
                        shadowX: shadowX,
                        shadowY: shadowY,
                        shadowOpacity: shadowOpacity
                    )
                    // Animated text with stroke and shadow support
                    StrokeText(
                        text: word.text,
                        fontSize: fontSize,
                        fontColor: highlightColor,
                        strokeColor: strokeColor,
                        strokeWidth: strokeWidth,
                        shadowColor: shadowColor,
                        shadowRadius: shadowRadius,
                        shadowX: shadowX,
                        shadowY: shadowY,
                        shadowOpacity: shadowOpacity
                    )
                    .opacity(progress)
                    .animation(.linear(duration: 0.05), value: progress)
                }
            }
        }
    }
} 

struct KaraokeTextByWordBackgroundOverlay: View {

    let text: String
    let words: [WordWithTiming]
    let fontSize: CGFloat
    let fontColor: Color
    let highlightColor: Color
    let wordBGColor: Color
    let strokeColor: Color
    let strokeWidth: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowX: CGFloat
    let shadowY: CGFloat
    let shadowOpacity: Double
    let currentTime: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(words) { word in
                let isActive = currentTime >= word.start && currentTime < word.end
                let progress: CGFloat = isActive ? 1 : (currentTime >= word.end ? 1 : 0)
                
                ZStack(alignment: .leading) {
                    // Base text with stroke and shadow support
                    StrokeText(
                        text: word.text,
                        fontSize: fontSize,
                        fontColor: fontColor,
                        strokeColor: strokeColor,
                        strokeWidth: strokeWidth,
                        shadowColor: shadowColor,
                        shadowRadius: shadowRadius,
                        shadowX: shadowX,
                        shadowY: shadowY,
                        shadowOpacity: shadowOpacity
                    )
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.clear)
                    )
                    // Animated text with stroke and shadow support
                    StrokeText(
                        text: word.text,
                        fontSize: fontSize,
                        fontColor: highlightColor,
                        strokeColor: strokeColor,
                        strokeWidth: strokeWidth,
                        shadowColor: shadowColor,
                        shadowRadius: shadowRadius,
                        shadowX: shadowX,
                        shadowY: shadowY,
                        shadowOpacity: shadowOpacity
                    )
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(wordBGColor.opacity(0.5))
                            .opacity(progress)
                    )
                    .opacity(progress)
                    .animation(.linear(duration: 0.05), value: progress)
                }
            }
        }
    }
}

// Custom view for text with stroke support using the same approach as regular text
struct StrokeText: View {
    let text: String
    let fontSize: CGFloat
    let fontColor: Color
    let strokeColor: Color
    let strokeWidth: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowX: CGFloat
    let shadowY: CGFloat
    let shadowOpacity: Double
    
    var body: some View {
        ZStack {
            // Stroke layer (background) - Apply shadow here when stroke is enabled
            if let strokeAttr = createKaraokeStrokeAttr() {
                AttributedTextOverlay(
                    attributedString: strokeAttr,
                    offset: .zero,
                    isSelected: false,
                    bgColor: .clear,
                    cornerRadius: 0,
                    shadowColor: UIColor(shadowColor).withAlphaComponent(shadowOpacity),
                    shadowRadius: shadowRadius,
                    shadowX: shadowX,
                    shadowY: shadowY
                )
            }
            
            // Main text layer (foreground) - Only apply shadow if no stroke
            AttributedTextOverlay(
                attributedString: createKaraokeFillAttr(),
                offset: .zero,
                isSelected: false,
                bgColor: .clear,
                cornerRadius: 0,
                shadowColor: strokeColor == .clear ? UIColor(shadowColor).withAlphaComponent(shadowOpacity) : UIColor.clear,
                shadowRadius: strokeColor == .clear ? shadowRadius : 0,
                shadowX: strokeColor == .clear ? shadowX : 0,
                shadowY: strokeColor == .clear ? shadowY : 0
            )
        }
    }
    
    // Create stroke-only attributed string
    private func createKaraokeStrokeAttr() -> NSAttributedString? {
        guard strokeColor != .clear && strokeWidth > 0 else { return nil }
        
        let attrStr = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: attrStr.length)
        
        // Scale stroke width relative to font size for better proportions
        let scaledStrokeWidth = min(strokeWidth, fontSize * 0.15) // Max 15% of font size
        
        attrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: fontSize, weight: .bold), range: range)
        attrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear, range: range) // Transparent fill
        attrStr.addAttribute(NSAttributedString.Key.strokeColor, value: UIColor(strokeColor), range: range)
        attrStr.addAttribute(NSAttributedString.Key.strokeWidth, value: scaledStrokeWidth, range: range) // Positive for stroke-only
        
        return attrStr
    }
    
    // Create fill-only attributed string
    private func createKaraokeFillAttr() -> NSAttributedString {
        let attrStr = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: attrStr.length)
        
        attrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: fontSize, weight: .bold), range: range)
        attrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(fontColor), range: range)
        
        return attrStr
    }
} 