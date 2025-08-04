import SwiftUI

// MARK: - Style Option Model
struct StyleOption {
    let title: String
    let iconName: String
    let action: () -> Void
}

// MARK: - Reusable Style Button Component
struct StyleButton: View {
    let option: StyleOption
    let isSelected: Bool
    
    var body: some View {
        Button(action: option.action) {
            VStack(spacing: 4) {
                Image(systemName: option.iconName)
                    .font(.title3)
                    .frame(width: 20, height: 20)
                Text(option.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(isSelected ? .black : .white)
            .frame(width: 65, height: 55)
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
        .background(isSelected ? Color.white : Color.gray.opacity(0.2))
        .cornerRadius(10)
        .shadow(color: .white.opacity(0.3), radius: 3, x: 0, y: 1)
    }
}

struct TextToolbar: View {
    @ObservedObject var textEditor: TextEditorViewModel
    @Binding var videoPlayerSize: VideoPlayerSize
    @Binding var showWordTimeline: Bool
    @State private var toolbarOffset: CGFloat = 100
    @State private var isStyleMode: Bool = false
    @State private var selectedStyleOption: String? = nil
    
    // MARK: - Computed Properties
    private var styleOptions: [StyleOption] {
        [
            StyleOption(title: "Text\nColor", iconName: "paintpalette") {
                selectedStyleOption = "Text\nColor"
                print("Text Color tapped")
            },
            StyleOption(title: "Background", iconName: "rectangle.fill") {
                selectedStyleOption = "Background"
                print("Background tapped")
            },
            StyleOption(title: "Stroke", iconName: "circle.dashed") {
                selectedStyleOption = "Stroke"
                print("Stroke tapped")
            },
            StyleOption(title: "Font\nSize", iconName: "textformat.size") {
                selectedStyleOption = "Font\nSize"
                print("Font Size tapped")
            },
            StyleOption(title: "Shadow", iconName: "shadow") {
                selectedStyleOption = "Shadow"
                print("Shadow tapped")
            }
        ]
    }
    
    var body: some View {
        VStack {
            // Style mode toolbar at the top
            if textEditor.selectedTextBox != nil && !textEditor.showEditTextContent && isStyleMode {
                VStack(spacing: 0) {
                    // Top bar with close button
                    HStack {
                        Spacer()
                        Button {
                            isStyleMode = false
                            videoPlayerSize = .half
                            showWordTimeline = true
                            selectedStyleOption = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.7), in: Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Style options centered horizontally
                    HStack(spacing: 4) {
                        ForEach(styleOptions, id: \.title) { option in
                            StyleButton(
                                option: option,
                                isSelected: selectedStyleOption == option.title
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
                .offset(y: toolbarOffset)
            }
            
            Spacer()
            
            // Normal toolbar at the bottom
            if textEditor.selectedTextBox != nil && !textEditor.showEditTextContent && !isStyleMode {
                HStack(spacing: 0) {
                    Button {
                        // Handle Edit Text action
                        if let selectedTextBox = textEditor.selectedTextBox {

                           // textEditor.openTextEditor(isEdit: true, selectedTextBox, timeRange: selectedTextBox.timeRange)
                            
                            // Resize video player to quarter size when editing text
                            videoPlayerSize = .quarter
                            
                            textEditor.openEditTextContent()

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
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .shadow(color: .white.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                        .frame(width: 20)
                    
                    Button {
                        // Handle Style action
                        isStyleMode = true
                        videoPlayerSize = .quarter
                        showWordTimeline = false
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
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .shadow(color: .white.opacity(0.3), radius: 4, x: 0, y: 2)
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
            videoPlayerSize: .constant(.half),
            showWordTimeline: .constant(true)
        )
        .preferredColorScheme(.dark)
    }
} 