import SwiftUI
import UIKit

struct TextOnPlayerView: View {
    
    var currentTime: Double
    @ObservedObject var viewModel: TextEditorViewModel
    var originalVideoSize: CGSize
    var videoScale: CGFloat = 1.0
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
    
    @ViewBuilder
    private var textBoxesView: some View {
        ForEach(viewModel.textBoxes) { textBox in
            let isSelected = viewModel.isSelected(textBox.id)
            
            // Display only the textbox that is currently on screen
            if textBox.timeRange.contains(currentTime) {
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
            
            if isSelected {
                textBoxButtons(textBox)
                    .offset(x: textBox.offset.width, y: textBox.offset.height - 30)
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
            editOrSelectTextBox(textBox, isSelected)
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
                    currentTime: currentTime
                )
                .padding(.horizontal, textBox.backgroundPadding)
                .padding(.vertical, textBox.backgroundPadding / 2)
            } 
        }
        else {
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
    
    private func createAttr(_ textBox: TextBox) -> AttributedString{
        var result = AttributedString(textBox.text)
        result.font = .systemFont(ofSize: textBox.fontSize, weight: .medium)
        result.foregroundColor = UIColor(textBox.fontColor)
        result.backgroundColor = UIColor(textBox.bgColor)
        
        // Apply stroke if stroke color is not clear and stroke width is greater than 0
        if textBox.strokeColor != .clear && textBox.strokeWidth > 0 {
            result.strokeColor = UIColor(textBox.strokeColor)
            result.strokeWidth = -textBox.strokeWidth
        }
        
        return result
    }
}

    
private func createNSAttr(_ textBox: TextBox) -> NSAttributedString {
    let attrStr = NSMutableAttributedString(string: textBox.text)
    let range = NSRange(location: 0, length: attrStr.length)
    
    attrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: textBox.fontSize, weight: .medium), range: range)
    attrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(textBox.fontColor), range: range)
    attrStr.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor(textBox.bgColor), range: range)
    
    // Apply stroke if stroke color is not clear and stroke width is greater than 0
    if textBox.strokeColor != .clear && textBox.strokeWidth > 0 {
        attrStr.addAttribute(NSAttributedString.Key.strokeColor, value: UIColor(textBox.strokeColor), range: range)
        attrStr.addAttribute(NSAttributedString.Key.strokeWidth, value: -textBox.strokeWidth, range: range)
    }
    
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

extension TextOnPlayerView {
    
    private func textBoxButtons(_ textBox: TextBox) -> some View{
        HStack(spacing: 10){
            TrashButtonWithConfirmation(onDelete: { viewModel.removeTextBox() })
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

struct TrashButtonWithConfirmation: View {
    @State private var showAlert = false
    let onDelete: () -> Void
    var body: some View {
        Button {
            showAlert = true
        } label: {
            Image(systemName: "trash")
                .padding(5)
                .background(Color(.systemGray2), in: Circle())
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Are you sure?"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    onDelete()
                },
                secondaryButton: .cancel()
            )
        }
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
    let currentTime: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(words) { word in
                let isActive = currentTime >= word.start && currentTime < word.end
                let progress: CGFloat = isActive ? 1 : (currentTime >= word.end ? 1 : 0)
                
                ZStack(alignment: .leading) {
                    // Base text (entire string)
                    Text(word.text)
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(fontColor)
                    // Animated text
                    Text(word.text)
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(highlightColor)
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
    let currentTime: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(words) { word in
                let isActive = currentTime >= word.start && currentTime < word.end
                let progress: CGFloat = isActive ? 1 : (currentTime >= word.end ? 1 : 0)
                
                ZStack(alignment: .leading) {
                    // Base text (entire string)
                    Text(word.text)
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(fontColor)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.clear)
                        )
                    // Animated text
                    Text(word.text)
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(highlightColor)
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