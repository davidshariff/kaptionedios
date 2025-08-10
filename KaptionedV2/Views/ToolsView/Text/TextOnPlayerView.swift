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
                // let _ = print("📝 Current TextBox: \(textBox) | Time: \(currentTime) | Selected: \(isSelected)")
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
        .if(!textBox.isKaraokePreset) { view in
            view.fixedSize()
        }
        .if(textBox.isKaraokePreset) { view in
            view.fixedSize() // Same as regular text - no auto-wrapping
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // set the current textbox to the selected textbox
            showEditSubtitlesMode = true
            viewModel.selectedTextBox = textBox
        }
    }
    
    @ViewBuilder
    private func textOverlay(textBox: TextBox, isSelected: Bool) -> some View {

        if textBox.isKaraokePreset {
            if let wordTimings = textBox.wordTimings, 
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
            else if let wordTimings = textBox.wordTimings, 
                    let karaokeType = textBox.karaokeType,
                    let highlightColor = textBox.highlightColor,
                    karaokeType == .wordAndScale {
                KaraokeTextWordAndScaleOverlay(
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
                    activeWordScale: textBox.activeWordScale,
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
    
    // get the index of the textbox in the textbox array
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
        
        // Check if text has explicit line breaks for center alignment
        let hasExplicitLineBreaks = attributedString.string.contains("\n")
        label.textAlignment = hasExplicitLineBreaks ? .center : .natural
        
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
        
        // Check if text has explicit line breaks for center alignment
        let hasExplicitLineBreaks = attributedString.string.contains("\n")
        uiView.textAlignment = hasExplicitLineBreaks ? .center : .natural
        
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
            uiView.layer.borderWidth = 0
            uiView.layer.cornerRadius = 8
            uiView.layer.masksToBounds = false
            
            // Create dashed border effect
            let borderLayer = CAShapeLayer()
            borderLayer.strokeColor = UIColor.purple.cgColor
            borderLayer.lineDashPattern = [6, 4]
            borderLayer.lineWidth = 2
            borderLayer.fillColor = nil
            borderLayer.path = UIBezierPath(roundedRect: uiView.bounds.insetBy(dx: -8, dy: -8), cornerRadius: 12).cgPath
            
            // Remove existing border layers
            uiView.layer.sublayers?.removeAll { $0 is CAShapeLayer }
            uiView.layer.addSublayer(borderLayer)
        } else {
            uiView.layer.borderWidth = 0
            uiView.layer.cornerRadius = 0
            // Remove border layers
            uiView.layer.sublayers?.removeAll { $0 is CAShapeLayer }
        }
        // Update shadow
        uiView.layer.shadowColor = shadowColor.cgColor
        uiView.layer.shadowRadius = shadowRadius
        uiView.layer.shadowOpacity = Float(shadowColor.cgColor.alpha)
        uiView.layer.shadowOffset = CGSize(width: shadowX, height: shadowY)
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
        KaraokeTextLayout(
            originalText: text,
            words: words,
            spacing: KaraokePreset.word.previewWordSpacing,
            lineSpacing: 2
        ) { word in
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
        KaraokeTextLayout(
            originalText: text,
            words: words,
            spacing: KaraokePreset.wordbg.previewWordSpacing,
            lineSpacing: 2
        ) { word in
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
                        .fill(wordBGColor)
                        .opacity(progress)
                )
                .opacity(progress)
                .animation(.linear(duration: 0.05), value: progress)
            }
        }
    }
}

struct KaraokeTextWordAndScaleOverlay: View {

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
    let activeWordScale: CGFloat
    let currentTime: Double

    var body: some View {
        KaraokeTextLayout(
            originalText: text,
            words: words,
            spacing: KaraokePreset.wordAndScale.previewWordSpacing,
            lineSpacing: 2
        ) { word in
            let isActive = currentTime >= word.start && currentTime < word.end
            let progress: CGFloat = isActive ? 1 : (currentTime >= word.end ? 1 : 0)
            
            // Calculate scale based on active state with smooth transitions
            let targetScale: CGFloat = isActive ? activeWordScale : 1.0
            
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
                .scaleEffect(targetScale)
                .animation(.easeInOut(duration: 0.15), value: targetScale)
                
                // Animated highlight text with stroke and shadow support
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
                .scaleEffect(targetScale)
                .opacity(progress)
                .animation(.easeInOut(duration: 0.15), value: targetScale)
                .animation(.linear(duration: 0.05), value: progress)
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

// Karaoke text layout that handles explicit line breaks and word wrapping
struct KaraokeTextLayout<Content: View>: View {
    let originalText: String
    let words: [WordWithTiming]
    let spacing: CGFloat
    let lineSpacing: CGFloat
    let content: (WordWithTiming) -> Content
    
    init(
        originalText: String,
        words: [WordWithTiming],
        spacing: CGFloat = 8,
        lineSpacing: CGFloat = 2,
        @ViewBuilder content: @escaping (WordWithTiming) -> Content
    ) {
        self.originalText = originalText
        self.words = words
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content
    }
    
    var body: some View {
        let lines = organizeWordsIntoLines()
        let hasMultipleLines = lines.count > 1
        
        VStack(alignment: hasMultipleLines ? .center : .leading, spacing: lineSpacing) {
            ForEach(0..<lines.count, id: \.self) { lineIndex in
                KaraokeLineLayout(
                    words: lines[lineIndex],
                    spacing: spacing,
                    content: content
                )
            }
        }
    }
    
    private func organizeWordsIntoLines() -> [[WordWithTiming]] {
        // Split original text into lines to detect explicit line breaks
        let textLines = originalText.components(separatedBy: .newlines)
        
        if textLines.count <= 1 {
            // No explicit line breaks, return all words as one line
            return [words]
        }
        
        // Map words to their corresponding text lines
        var result: [[WordWithTiming]] = []
        var wordIndex = 0
        
        for textLine in textLines {
            let lineWords = textLine.split { $0.isWhitespace }.map(String.init)
            var currentLineWords: [WordWithTiming] = []
            
            for _ in lineWords {
                if wordIndex < words.count {
                    currentLineWords.append(words[wordIndex])
                    wordIndex += 1
                }
            }
            
            if !currentLineWords.isEmpty {
                result.append(currentLineWords)
            }
        }
        
        // Add any remaining words to the last line (safety fallback)
        while wordIndex < words.count {
            if !result.isEmpty {
                result[result.count - 1].append(words[wordIndex])
            } else {
                result.append([words[wordIndex]])
            }
            wordIndex += 1
        }
        
        return result.isEmpty ? [words] : result
    }
}

// View for a single line of karaoke words with automatic wrapping
struct KaraokeLineLayout<Content: View>: View {
    let words: [WordWithTiming]
    let spacing: CGFloat
    let content: (WordWithTiming) -> Content
    
    var body: some View {
        KaraokeWrappingLayout(spacing: spacing, lineSpacing: 2) {
            ForEach(0..<words.count, id: \.self) { index in
                content(words[index])
            }
        }
    }
}

// Custom wrapping layout for karaoke words that supports line breaks
struct KaraokeWrappingLayout: Layout {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    
    init(spacing: CGFloat = 8, lineSpacing: CGFloat = 2) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentRowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        var maxOverallWidth: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            // Check if we need to wrap to next line due to width constraints
            let needsNewLine = index > 0 && (currentRowWidth + spacing + subviewSize.width > maxWidth)
            
            if needsNewLine {
                maxOverallWidth = max(maxOverallWidth, currentRowWidth)
                totalHeight += maxRowHeight + lineSpacing
                currentRowWidth = subviewSize.width
                maxRowHeight = subviewSize.height
            } else {
                if index > 0 {
                    currentRowWidth += spacing
                }
                currentRowWidth += subviewSize.width
                maxRowHeight = max(maxRowHeight, subviewSize.height)
            }
        }
        
        // Add the height of the last row
        totalHeight += maxRowHeight
        maxOverallWidth = max(maxOverallWidth, currentRowWidth)
        
        return CGSize(width: min(maxOverallWidth, maxWidth), height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var maxRowHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            // Check if we need to wrap to next line due to width constraints
            let needsNewLine = index > 0 && (currentX + subviewSize.width > bounds.maxX)
            
            if needsNewLine {
                // Move to next line
                currentY += maxRowHeight + lineSpacing
                currentX = bounds.minX
                maxRowHeight = 0
            }
            
            // Place the subview
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(subviewSize)
            )
            
            // Update position for next subview
            currentX += subviewSize.width + spacing
            maxRowHeight = max(maxRowHeight, subviewSize.height)
        }
    }
}

// Extension to conditionally apply view modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
} 