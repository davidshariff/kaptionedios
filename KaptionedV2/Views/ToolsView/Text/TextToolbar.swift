import SwiftUI

struct TextToolbar: View {
    @ObservedObject var textEditor: TextEditorViewModel
    @Binding var videoPlayerSize: MainEditorView.VideoPlayerSize
    @State private var toolbarOffset: CGFloat = 100
    
    var body: some View {
        VStack {
            Spacer()
            if textEditor.selectedTextBox != nil {
                HStack(spacing: 0) {
                    Button {
                        // Handle Edit Text action
                        if let selectedTextBox = textEditor.selectedTextBox {
                            textEditor.openTextEditor(isEdit: true, selectedTextBox, timeRange: selectedTextBox.timeRange)
                            // Resize video player to quarter size when editing text
                            //videoPlayerSize = .quarter
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.title2)
                                .frame(width: 24, height: 24)
                            Text("Edit Text")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(width: 80, height: 60)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                    }
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                        .frame(width: 20)
                    
                    Button {
                        // Handle Style action
                        print("Style button tapped")
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "paintbrush")
                                .font(.title2)
                                .frame(width: 24, height: 24)
                            Text("Style")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(width: 80, height: 60)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                    }
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 20)
                .offset(y: toolbarOffset)
            }
        }
        .onChange(of: textEditor.selectedTextBox) { newValue in
            if newValue != nil {
                // If switching between text boxes (not from nil), trigger animation
                if textEditor.selectedTextBox != nil {
                    // Slide down
                    withAnimation(.easeInOut(duration: 0.15)) {
                        toolbarOffset = 100
                    }
                    // Then slide up after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            toolbarOffset = 0
                        }
                    }
                } else {
                    // First time showing, just slide up
                    withAnimation(.easeInOut(duration: 0.3)) {
                        toolbarOffset = 0
                    }
                }
            } else {
                // Hiding toolbar, slide down
                withAnimation(.easeInOut(duration: 0.3)) {
                    toolbarOffset = 100
                }
            }
        }
    }
}

struct TextToolbar_Previews: PreviewProvider {
    static var previews: some View {
        TextToolbar(
            textEditor: TextEditorViewModel(),
            videoPlayerSize: .constant(.half)
        )
        .preferredColorScheme(.dark)
    }
} 