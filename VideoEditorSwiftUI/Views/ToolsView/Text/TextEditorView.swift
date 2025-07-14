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
    @State private var activeSheet: SheetType? = nil
    @State private var sheetOffset: CGFloat = UIScreen.main.bounds.height * 0.7
    let onSave: ([TextBox]) -> Void
    
    // MARK: - Sheet Types
    enum SheetType {
        case bgColor, stroke, fontSize
    }
    var body: some View{
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            VStack{
                HStack {
                    Button{
                        closeKeyboard()
                        viewModel.cancelTextEditor()
                    } label: {
                        Text("Cancel")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.secondary, in: RoundedRectangle(cornerRadius: 20))
                    }

                    Spacer()

                    Button {
                        closeKeyboard()
                        viewModel.saveTapped()
                        onSave(viewModel.textBoxes)
                    } label: {
                        Text("Save")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .foregroundColor(.white)
                            .background(Color.green, in: RoundedRectangle(cornerRadius: 20))
                            .opacity(viewModel.currentTextBox.text.isEmpty ? 0.5 : 1)
                    }
                    .disabled(viewModel.currentTextBox.text.isEmpty)
                }
                .padding(.horizontal)

                Spacer()
                TextView(textBox: $viewModel.currentTextBox, isFirstResponder: $isFocused, minHeight: textHeight, calculatedHeight: $textHeight)
                    .frame(maxHeight: textHeight)
                    .padding(.horizontal, viewModel.currentTextBox.backgroundPadding)
                    .padding(.vertical, viewModel.currentTextBox.backgroundPadding / 2)
                    .background(
                        RoundedRectangle(cornerRadius: viewModel.currentTextBox.cornerRadius)
                            .fill(viewModel.currentTextBox.bgColor)
                    )
                Spacer()
                HStack(spacing: 20){
                    ColorPicker(selection: $viewModel.currentTextBox.fontColor, supportsOpacity: true) {
                    }.labelsHidden()

                    // Tool buttons
                    ToolButton(
                        color: viewModel.currentTextBox.bgColor,
                        accessibilityLabel: "Background color"
                    ) {
                        activeSheet = .bgColor
                    }
                    
                    ToolButton(
                        color: viewModel.currentTextBox.strokeColor,
                        accessibilityLabel: "Stroke color"
                    ) {
                        activeSheet = .stroke
                    }
                    
                    ToolButton(
                        color: .blue.opacity(0.8),
                        text: "\(Int(viewModel.currentTextBox.fontSize))",
                        accessibilityLabel: "Font size"
                    ) {
                        activeSheet = .fontSize
                    }
                }
                .padding(.bottom)
            }
            .padding(.horizontal)

            // Custom overlays for pickers, anchored to bottom
            if let activeSheet = activeSheet {
                AnimatedSheetOverlay(
                    isPresented: Binding(
                        get: { activeSheet != nil },
                        set: { if !$0 { self.activeSheet = nil } }
                    ),
                    sheetOffset: $sheetOffset
                ) { dismissSheet in
                    sheetContent(for: activeSheet, dismissSheet: dismissSheet)
                }
            }
        }
        .animation(.easeInOut, value: activeSheet != nil)
    }
    
    
    private func closeKeyboard(){
        isFocused = false
    }
    
    // MARK: - Helper Functions
    @ViewBuilder
    private func sheetContent(for sheetType: SheetType, dismissSheet: @escaping () -> Void) -> some View {
        switch sheetType {
        case .bgColor:
            BgColorPickerSheet(
                selectedColor: $viewModel.currentTextBox.bgColor,
                backgroundPadding: $viewModel.currentTextBox.backgroundPadding,
                cornerRadius: $viewModel.currentTextBox.cornerRadius,
                onCancel: dismissSheet
            )
        case .stroke:
            StrokePickerSheet(
                selectedColor: $viewModel.currentTextBox.strokeColor,
                strokeWidth: $viewModel.currentTextBox.strokeWidth,
                onCancel: dismissSheet
            )
        case .fontSize:
            FontSizePickerSheet(
                fontSize: $viewModel.currentTextBox.fontSize,
                onCancel: dismissSheet
            )
        }
    }
}

// MARK: - Shared Color Palette
struct ColorPalette {
    static let colors: [Color] = [
        .clear, .white, .black, .red, .orange, .yellow, .green, .blue, .purple, .pink, .gray
    ]
}

// MARK: - Reusable Tool Button
struct ToolButton: View {
    let color: Color
    let text: String?
    let accessibilityLabel: String
    let action: () -> Void
    
    init(color: Color, text: String? = nil, accessibilityLabel: String, action: @escaping () -> Void) {
        self.color = color
        self.text = text
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color == .clear ? Color.gray.opacity(0.2) : color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
                if color == .clear {
                    Image(systemName: "slash.circle")
                        .foregroundColor(.white)
                } else if let text = text {
                    Text(text)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Reusable Sheet Overlay Component
struct AnimatedSheetOverlay<Content: View>: View {
    @Binding var isPresented: Bool
    @Binding var sheetOffset: CGFloat
    let content: (@escaping () -> Void) -> Content
    
    init(isPresented: Binding<Bool>, sheetOffset: Binding<CGFloat>, @ViewBuilder content: @escaping (@escaping () -> Void) -> Content) {
        self._isPresented = isPresented
        self._sheetOffset = sheetOffset
        self.content = content
    }
    
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .transition(.opacity)
            .onTapGesture {
                dismissSheet()
            }
        VStack {
            Spacer()
            content(dismissSheet)
                .offset(y: sheetOffset)
                .animation(.spring(), value: sheetOffset)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring()) {
                sheetOffset = 0
            }
        }
    }
    
    private func dismissSheet() {
        withAnimation(.spring()) {
            sheetOffset = UIScreen.main.bounds.height * 0.7
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPresented = false
            }
        }
    }
}

// MARK: - Reusable Sheet Styling
struct SheetStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: 420)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Reusable Sheet Header
struct SheetHeaderView: View {
    let title: String
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color(.systemGray3).opacity(0.8), in: Circle())
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 8)
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .padding(.top, 8)
            .padding(.bottom, 20)
    }
}

// MARK: - Reusable Color Grid
struct ColorGridView: View {
    let colors: [Color]
    let selectedColor: Color
    let onColorSelected: (Color) -> Void
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(colors, id: \.self) { color in
                    Button {
                        onColorSelected(color)
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
    @Binding var backgroundPadding: CGFloat
    @Binding var cornerRadius: CGFloat
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SheetHeaderView(title: "Background Color", onCancel: onCancel)
            ColorGridView(
                colors: ColorPalette.colors,
                selectedColor: selectedColor,
                onColorSelected: { color in
                    selectedColor = color
                    onCancel()
                }
            )
            VStack(alignment: .leading) {
                Text("Background Padding: \(Int(backgroundPadding))")
                    .font(.subheadline)
                Slider(value: $backgroundPadding, in: 0...40, step: 1)
                Text("Corner Radius: \(Int(cornerRadius))")
                    .font(.subheadline)
                Slider(value: $cornerRadius, in: 0...20, step: 1)
            }
            .padding(.horizontal)
            Spacer()
        }
        .modifier(SheetStyleModifier())
    }
}

private struct StrokePickerSheet: View {
    @Binding var selectedColor: Color
    @Binding var strokeWidth: CGFloat
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SheetHeaderView(title: "Stroke Outline", onCancel: onCancel)
            
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
            ColorGridView(
                colors: ColorPalette.colors,
                selectedColor: selectedColor,
                onColorSelected: { color in
                    selectedColor = color
                    if color == .clear {
                        strokeWidth = 0
                    } else if strokeWidth == 0 {
                        strokeWidth = 2
                    }
                    onCancel()
                }
            )
            Spacer()
        }
        .modifier(SheetStyleModifier())
    }
}

private struct FontSizePickerSheet: View {
    @Binding var fontSize: CGFloat
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SheetHeaderView(title: "Font Size", onCancel: onCancel)
            
            // Font size slider
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Size: \(Int(fontSize))")
                        .font(.subheadline)
                    Spacer()
                    Text("Sample")
                        .font(.system(size: fontSize, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black)
                }
                
                Slider(value: $fontSize, in: 8...100, step: 1)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .modifier(SheetStyleModifier())
    }
}


