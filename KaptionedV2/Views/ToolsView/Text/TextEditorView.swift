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
    @FocusState private var isTextFieldFocused: Bool
    @State private var activeSheet: SheetType? = nil
    @State private var sheetOffset: CGFloat = 600 // Default screen height * 0.7
    @State private var showDeleteConfirmation: Bool = false
    let onSave: ([TextBox]) -> Void
    
    // MARK: - Sheet Types
    enum SheetType {
        case bgColor, stroke, fontSize, shadow
    }
    var body: some View{
        ZStack {
            
            if viewModel.showEditTextContent {

                // Show compact text field above toolbar when editing text content
                ScrollView {
                    VStack(alignment: .center, spacing: 0) {
                        VStack(spacing: 12) {
                            TextField("Enter text...", text: $viewModel.currentTextBox.text, axis: .vertical)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .focused($isTextFieldFocused)
                                .onAppear {
                                    isTextFieldFocused = true
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.5))
                                )
                                .frame(maxWidth: 300, maxHeight: 200)

                            // Close button for text-only mode
                            Button {
                                viewModel.closeEditTextContent()
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44)) // Larger icon
                                    .foregroundColor(.white)
                                    .padding(20)
                                    .background(Color.black.opacity(0.6), in: Circle())
                            }
                            
                        }
                        .padding(.top, 40) // Space from top, adjust as needed
                        .padding(.bottom, 100) // Extra padding to ensure button is visible above keyboard
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal)
                }
                .scrollDismissesKeyboard(.immediately)
            } 
            else {
                // Show full text editor when not editing text content
                VStack{
                    HStack(alignment: .center) {
                        Button{
                            closeKeyboard()
                            viewModel.cancelTextEditor()
                        } label: {
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                        }

                    Spacer()
                    
                    Button{
                        closeKeyboard()
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!viewModel.isEditMode)
                    
                    Button {
                        closeKeyboard()
                        viewModel.saveTapped()
                        onSave(viewModel.textBoxes)
                    } label: {
                        Image(systemName: "checkmark")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                                .foregroundColor(.white)
                                .background(Color.green.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                            .opacity(viewModel.currentTextBox.text.isEmpty ? 0.5 : 1)
                        }
                            .disabled(viewModel.currentTextBox.text.isEmpty)
                    }
                    .padding(.horizontal, 0)
                    .alert("Delete Subtitle", isPresented: $showDeleteConfirmation) {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteCurrentTextBox()
                            onSave(viewModel.textBoxes)
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Are you sure you want to delete this subtitle? This action cannot be undone.")
                    }

                    Spacer()
                    TextField("Enter text...", text: $viewModel.currentTextBox.text, axis: .vertical)
                        .font(.system(size: viewModel.currentTextBox.fontSize, weight: .medium))
                        .foregroundColor(viewModel.currentTextBox.fontColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .focused($isTextFieldFocused)
                        .onAppear {
                            isTextFieldFocused = true
                        }
                        .padding(.horizontal, viewModel.currentTextBox.backgroundPadding)
                        .padding(.vertical, viewModel.currentTextBox.backgroundPadding / 2)
                    Spacer()
                    HStack(spacing: 20) {
                        VStack {
                            ColorPicker(selection: $viewModel.currentTextBox.fontColor, supportsOpacity: true) {
                            }.labelsHidden()
                            Text("Text Color")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        VStack {
                            ToolButton(
                                color: viewModel.currentTextBox.bgColor,
                                accessibilityLabel: "Background color"
                            ) {
                                activeSheet = .bgColor
                            }
                            Text("Background")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        VStack {
                            ToolButton(
                                color: viewModel.currentTextBox.strokeColor,
                                accessibilityLabel: "Stroke color"
                            ) {
                                activeSheet = .stroke
                            }
                            Text("Stroke")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        VStack {
                            ToolButton(
                                color: .blue.opacity(0.8),
                                text: "\(Int(viewModel.currentTextBox.fontSize))",
                                accessibilityLabel: "Font size"
                            ) {
                                activeSheet = .fontSize
                            }
                            Text("Font Size")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        VStack {
                            ToolButton(
                                color: viewModel.currentTextBox.shadowColor.opacity(viewModel.currentTextBox.shadowOpacity),
                                accessibilityLabel: "Shadow"
                            ) {
                                activeSheet = .shadow
                            }
                            Text("Shadow")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.bottom)
                    .hCenter()
                }
                .padding(.horizontal)
            }

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
        isTextFieldFocused = false
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
        case .shadow:
            ShadowPickerSheet(
                shadowColor: $viewModel.currentTextBox.shadowColor,
                shadowRadius: $viewModel.currentTextBox.shadowRadius,
                shadowX: $viewModel.currentTextBox.shadowX,
                shadowY: $viewModel.currentTextBox.shadowY,
                shadowOpacity: $viewModel.currentTextBox.shadowOpacity,
                onCancel: dismissSheet
            )
        }
    }
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
                                sheetOffset = 600
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
            .frame(maxHeight: 600) // Changed from UIScreen.main.bounds.height * 0.7
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
        
        // Remove internal padding
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        
        // Ensure padding is removed
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        
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
        // Apply shadow
        if textBox.shadowRadius > 0 && textBox.shadowOpacity > 0 {
            let shadow = NSShadow()
            shadow.shadowColor = UIColor(textBox.shadowColor).withAlphaComponent(textBox.shadowOpacity)
            shadow.shadowBlurRadius = textBox.shadowRadius
            shadow.shadowOffset = CGSize(width: textBox.shadowX, height: textBox.shadowY)
            attrStr.addAttribute(.shadow, value: shadow, range: range)
        }
        textView.attributedText = attrStr
        textView.textAlignment = .center
    }

   private func recalculateHeight(view: UIView) {
        guard let textView = view as? UITextView else { return }
        
        // Calculate the actual text content height without UITextView's internal padding
        let textContainer = NSTextContainer(size: CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage(attributedString: textView.attributedText)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = 0
        
        let textRect = layoutManager.usedRect(for: textContainer)
        let actualTextHeight = textRect.height
        
        let newHeight = max(minHeight, actualTextHeight)
        
        if $calculatedHeight.wrappedValue != newHeight {
            DispatchQueue.main.async {
                self.$calculatedHeight.wrappedValue = newHeight
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
            ColorRowView(
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
            ColorRowView(
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

// MARK: - Shadow Picker Sheet
private struct ShadowPickerSheet: View {
    @Binding var shadowColor: Color
    @Binding var shadowRadius: CGFloat
    @Binding var shadowX: CGFloat
    @Binding var shadowY: CGFloat
    @Binding var shadowOpacity: Double
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SheetHeaderView(title: "Text Shadow", onCancel: onCancel)
            ColorRowView(
                colors: ColorPalette.colors,
                selectedColor: shadowColor,
                onColorSelected: { color in
                    shadowColor = color
                }
            )
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Blur: \(String(format: "%.1f", shadowRadius))")
                        .font(.subheadline)
                    Slider(value: $shadowRadius, in: 0...20, step: 0.5)
                }
                HStack {
                    Text("X Offset: \(String(format: "%.1f", shadowX))")
                        .font(.subheadline)
                    Slider(value: $shadowX, in: -20...20, step: 0.5)
                }
                HStack {
                    Text("Y Offset: \(String(format: "%.1f", shadowY))")
                        .font(.subheadline)
                    Slider(value: $shadowY, in: -20...20, step: 0.5)
                }
                HStack {
                    Text("Opacity: \(String(format: "%.2f", shadowOpacity))")
                        .font(.subheadline)
                    Slider(value: $shadowOpacity, in: 0...1, step: 0.01)
                }
            }
            .padding(.horizontal)
            Spacer()
        }
        .modifier(SheetStyleModifier())
    }
}


