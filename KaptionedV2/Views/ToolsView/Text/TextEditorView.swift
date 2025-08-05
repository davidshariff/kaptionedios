import SwiftUI

struct TextEditorView: View{
    
    @ObservedObject var viewModel: TextEditorViewModel
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


