import SwiftUI

struct TextEditorView: View{
    
    @ObservedObject var viewModel: TextEditorViewModel
    @State private var textHeight: CGFloat = 100
    @FocusState private var isTextFieldFocused: Bool
    @State private var showDeleteConfirmation: Bool = false
    let onSave: ([TextBox]) -> Void
    
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

                // Background that fills the entire screen
                Color.black.opacity(0.5)
                    .ignoresSafeArea()

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
                                .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
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
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .focused($isTextFieldFocused)
                        .onAppear {
                            isTextFieldFocused = true
                        }
                        .padding(.horizontal, viewModel.currentTextBox.backgroundPadding)
                        .padding(.vertical, viewModel.currentTextBox.backgroundPadding / 2)
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
                        
    
    private func closeKeyboard(){
        isTextFieldFocused = false
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


