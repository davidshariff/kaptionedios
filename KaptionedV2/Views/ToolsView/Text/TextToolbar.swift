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
    let onSeek: (Double) -> Void
    let currentTime: Double
    @State private var toolbarOffset: CGFloat = 100
    @State private var isStyleMode: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    // MARK: - Helper Functions
    private func seekToSelectedTextBox() {
        if let selectedTextBox = textEditor.selectedTextBox {
            onSeek(selectedTextBox.timeRange.lowerBound)
            print("🎬 Seeking to text box start time: \(selectedTextBox.timeRange.lowerBound)")
        }
    }
    

    
    // MARK: - Computed Properties
    private var styleOptions: [StyleOption] {
        [
            StyleOption(title: "Text\nColor", iconName: "paintpalette") {
                seekToSelectedTextBox()
                textEditor.selectedStyleOptionToEdit = "Text\nColor"
                print("Text Color tapped")
            },
            StyleOption(title: "Background", iconName: "rectangle.fill") {
                seekToSelectedTextBox()
                textEditor.selectedStyleOptionToEdit = "Background"
                print("Background tapped")
            },
            StyleOption(title: "Stroke", iconName: "circle.dashed") {
                seekToSelectedTextBox()
                textEditor.selectedStyleOptionToEdit = "Stroke"
                print("Stroke tapped")
            },
            StyleOption(title: "Font\nSize", iconName: "textformat.size") {
                seekToSelectedTextBox()
                textEditor.selectedStyleOptionToEdit = "Font\nSize"
                print("Font Size tapped")
            },
            StyleOption(title: "Shadow", iconName: "shadow") {
                seekToSelectedTextBox()
                textEditor.selectedStyleOptionToEdit = "Shadow"
                print("Shadow tapped")
            }
        ]
    }
    
    var body: some View {
        VStack {
            
            // Style mode toolbar
            if textEditor.selectedTextBox != nil && !textEditor.showEditTextContent && isStyleMode {

                Spacer()

                // Back button
                HStack {
                    Spacer()
                    Button {
                        isStyleMode = false
                        videoPlayerSize = .half
                        showWordTimeline = true
                        textEditor.selectedStyleOptionToEdit = nil
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                            Text("Back")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.7), in: Capsule())
                    }
                }
                .padding(.horizontal, 10)

                VStack(spacing: 0) {
                    // Style options centered horizontally
                    HStack(spacing: 4) {
                        ForEach(styleOptions, id: \.title) { option in
                            StyleButton(
                                option: option,
                                isSelected: textEditor.selectedStyleOptionToEdit == option.title
                            )
                        }
                    }
                    .padding(.vertical, 4)
                    
                }
                .offset(y: toolbarOffset)
            }
            // Normal toolbar at the bottom
            else if textEditor.selectedTextBox != nil && !textEditor.showEditTextContent && !isStyleMode {

                Spacer()

                HStack(spacing: 0) {
                    Button {
                        // Handle Edit Text action
                        if textEditor.selectedTextBox != nil {
                            // Seek to the start of the selected text box
                            seekToSelectedTextBox()
                            
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
                        seekToSelectedTextBox()
                        isStyleMode = true
                        videoPlayerSize = .half
                        showWordTimeline = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "paintbrush")
                                .font(.title2)
                                .frame(width: 24, height: 24)
                            Text("Edit Style")
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
                .onAppear {
                    // Force animation when toolbar appears and text box is selected
                    if textEditor.selectedTextBox != nil {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            toolbarOffset = 0
                        }
                    }
                }
            }
        }
        .onChange(of: textEditor.selectedTextBox?.id) { newValue in
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

        if textEditor.selectedTextBox == nil {
            VStack {
                Spacer()
                
                // Textbox-style container for "Tap text to edit"
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.tap")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("tap text above to edit")
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    Text("or")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.vertical, 4)
                }
                
                Button {
                    // Add new caption action with current time
                    let timeRange = currentTime...(currentTime + 1) // 1 second duration
                    textEditor.openTextEditor(isEdit: false, nil, timeRange: timeRange)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("add new text")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(8)
                }
                .padding(.bottom, 20)
            }
        }

    }
}