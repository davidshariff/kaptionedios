//
//  TextEditorView.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 02.05.2023.
//

import SwiftUI

struct TextEditorView: View{
    @ObservedObject var viewModel: TextEditorViewModel
    @State private var textHeight: CGFloat = 100
    @State private var isFocused: Bool = true
    @State private var showBgColorSheet: Bool = false
    @State private var showStrokeSheet: Bool = false
    let onSave: ([TextBox]) -> Void
    var body: some View{
        Color.black.opacity(0.35)
                .ignoresSafeArea()
        VStack{
            Spacer()
            TextView(textBox: $viewModel.currentTextBox, isFirstResponder: $isFocused, minHeight: textHeight, calculatedHeight: $textHeight)
                .frame(maxHeight: textHeight)
            Spacer()
            
            Button {
                closeKeyboard()
                viewModel.saveTapped()
                onSave(viewModel.textBoxes)
            } label: {
                Text("Save")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .foregroundColor(.black)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
                    .opacity(viewModel.currentTextBox.text.isEmpty ? 0.5 : 1)
                    .disabled(viewModel.currentTextBox.text.isEmpty)
            }
            .hCenter()
            .overlay(alignment: .leading) {
                HStack {
                    Button{
                        closeKeyboard()
                        viewModel.cancelTextEditor()
                    } label: {
                        Image(systemName: "xmark")
                            .padding(12)
                            .foregroundColor(.white)
                            .background(Color.secondary, in: Circle())
                    }
                    
                    Spacer()
                    HStack(spacing: 20){
                        ColorPicker(selection: $viewModel.currentTextBox.fontColor, supportsOpacity: true) {
                        }.labelsHidden()

                        // Custom background color picker with 'no color' option
                        Button {
                            showBgColorSheet = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(viewModel.currentTextBox.bgColor == .clear ? Color.gray.opacity(0.2) : viewModel.currentTextBox.bgColor)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: 2)
                                    )
                                if viewModel.currentTextBox.bgColor == .clear {
                                    Image(systemName: "slash.circle")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Background color")
                        .sheet(isPresented: $showBgColorSheet) {
                            BgColorPickerSheet(selectedColor: $viewModel.currentTextBox.bgColor) {
                                showBgColorSheet = false
                            }
                        }
                        
                        // Custom stroke picker with 'no stroke' option
                        Button {
                            showStrokeSheet = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(viewModel.currentTextBox.strokeColor == .clear ? Color.gray.opacity(0.2) : viewModel.currentTextBox.strokeColor)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: 2)
                                    )
                                if viewModel.currentTextBox.strokeColor == .clear {
                                    Image(systemName: "slash.circle")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Stroke color")
                        .sheet(isPresented: $showStrokeSheet) {
                            StrokePickerSheet(
                                selectedColor: $viewModel.currentTextBox.strokeColor,
                                strokeWidth: $viewModel.currentTextBox.strokeWidth
                            ) {
                                showStrokeSheet = false
                            }
                        }
                    }
                }
            }
        }
        .padding(.bottom)
        .padding(.horizontal)
    }
    
    
    private func closeKeyboard(){
        isFocused = false
    }
}
struct TextEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorView(viewModel: TextEditorViewModel(), onSave: {_ in})
    }
}



struct TextView: UIViewRepresentable {
    
    @Binding var isFirstResponder: Bool
    @Binding var textBox: TextBox

    var minHeight: CGFloat
    @Binding var calculatedHeight: CGFloat

    init(textBox: Binding<TextBox>, isFirstResponder: Binding<Bool>, minHeight: CGFloat, calculatedHeight: Binding<CGFloat>) {
        self._textBox = textBox
        self._isFirstResponder = isFirstResponder
        self.minHeight = minHeight
        self._calculatedHeight = calculatedHeight
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator

        // Decrease priority of content resistance, so content would not push external layout set in SwiftUI
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.text = self.textBox.text
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.textAlignment = .center
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = UIColor.clear

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        
        focused(textView)
        recalculateHeight(view: textView)
        setTextAttrs(textView)
    
    }
    
    private func setTextAttrs(_ textView: UITextView){
        
        let attrStr = NSMutableAttributedString(string: textView.text)
        let range = NSRange(location: 0, length: attrStr.length)
        
        attrStr.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor(textBox.bgColor), range: range)
        attrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: textBox.fontSize, weight: .medium), range: range)
        attrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(textBox.fontColor), range: range)
        
        // Apply stroke if stroke color is not clear and stroke width is greater than 0
        if textBox.strokeColor != .clear && textBox.strokeWidth > 0 {
            attrStr.addAttribute(NSAttributedString.Key.strokeColor, value: UIColor(textBox.strokeColor), range: range)
            attrStr.addAttribute(NSAttributedString.Key.strokeWidth, value: -textBox.strokeWidth, range: range)
        }
        
        textView.attributedText = attrStr
        textView.textAlignment = .center
    }

   private func recalculateHeight(view: UIView) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        if minHeight < newSize.height && $calculatedHeight.wrappedValue != newSize.height {
            DispatchQueue.main.async {
                self.$calculatedHeight.wrappedValue = newSize.height // !! must be called asynchronously
            }
        } else if minHeight >= newSize.height && $calculatedHeight.wrappedValue != minHeight {
            DispatchQueue.main.async {
                self.$calculatedHeight.wrappedValue = self.minHeight // !! must be called asynchronously
            }
        }
    }
    
    private func focused(_ textView: UITextView){
        DispatchQueue.main.async {
            switch isFirstResponder {
            case true: textView.becomeFirstResponder()
            case false: textView.resignFirstResponder()
            }
        }
    }

    class Coordinator : NSObject, UITextViewDelegate {

        var parent: TextView

        init(_ uiTextView: TextView) {
            self.parent = uiTextView
        }

        func textViewDidChange(_ textView: UITextView) {
            if textView.markedTextRange == nil {
                parent.textBox.text = textView.text ?? String()
                parent.recalculateHeight(view: textView)
            }
        }
        
//        func textViewDidBeginEditing(_ textView: UITextView) {
//            parent.isFirstResponder = true
//        }
    }
}

private struct BgColorPickerSheet: View {
    @Binding var selectedColor: Color
    let onSelect: () -> Void
    let colors: [Color] = [
        .clear, .white, .black, .red, .orange, .yellow, .green, .blue, .purple, .pink, .gray
    ]
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        VStack(spacing: 20) {
            Text("Background Color")
                .font(.headline)
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            selectedColor = color
                            onSelect()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(color == .clear ? Color.gray.opacity(0.2) : color)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 1)
                                    )
                                if color == .clear {
                                    Image(systemName: "slash.circle")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .frame(maxHeight: 220)
            Spacer()
        }
        .padding()
        .frame(maxWidth: 350)
    }
}

private struct StrokePickerSheet: View {
    @Binding var selectedColor: Color
    @Binding var strokeWidth: CGFloat
    let onSelect: () -> Void
    let colors: [Color] = [
        .clear, .white, .black, .red, .orange, .yellow, .green, .blue, .purple, .pink, .gray
    ]
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Stroke Outline")
                .font(.headline)
            
            // Stroke width slider
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Width: \(Int(strokeWidth))")
                        .font(.subheadline)
                    Spacer()
                    if selectedColor != .clear {
                        Text("Sample")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedColor)
                            .overlay(
                                Text("Sample")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(selectedColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(selectedColor, lineWidth: strokeWidth)
                                    )
                            )
                    }
                }
                
                Slider(value: $strokeWidth, in: 0...10, step: 0.5)
                    .disabled(selectedColor == .clear)
            }
            .padding(.horizontal)
            
            // Color picker
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            selectedColor = color
                            if color == .clear {
                                strokeWidth = 0
                            } else if strokeWidth == 0 {
                                strokeWidth = 2
                            }
                            onSelect()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(color == .clear ? Color.gray.opacity(0.2) : color)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 1)
                                    )
                                if color == .clear {
                                    Image(systemName: "slash.circle")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .frame(maxHeight: 220)
            Spacer()
        }
        .padding()
        .frame(maxWidth: 350)
    }
}
