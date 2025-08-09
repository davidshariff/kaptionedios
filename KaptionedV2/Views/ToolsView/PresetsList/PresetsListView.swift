import SwiftUI

struct PresetsListView: View {
    @Binding var isPresented: Bool
    @Binding var pendingPreset: SubtitleStyle?
    var onSelect: (SubtitleStyle) -> Void
    var currentTextBox: TextBox? = nil
    var allTextBoxes: [TextBox] = []
    var currentTime: Double = 0
    
    @State private var selectedKaraokePreset: SubtitleStyle? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()
                Text("Select a Subtitle Style")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                }
            }
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(SubtitleStyle.allPresets) { style in
                        Button(action: {
                            if style.isKaraokePreset {
                                print("DEBUG: Selected karaoke preset: \(style.name)")
                                selectedKaraokePreset = style
                                print("DEBUG: selectedKaraokePreset set to: \(selectedKaraokePreset?.name ?? "nil")")
                            } else {
                                onSelect(style)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(style.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Font: \(Int(style.fontSize))pt")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                RoundedRectangle(cornerRadius: style.cornerRadius)
                                    .fill(style.bgColor)
                                    .frame(width: 60, height: 24)
                                    .overlay(
                                        Text("Aa")
                                            .font(.system(size: style.fontSize * 0.5))
                                            .foregroundColor(style.fontColor)
                                            .shadow(color: style.shadowColor.opacity(style.shadowOpacity), radius: style.shadowRadius, x: style.shadowX, y: style.shadowY)
                                    )
                            }
                            .padding()
                            .background(isCurrentPreset(style) ? Color.blue.opacity(0.3) : Color(.systemGray5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isCurrentPreset(style) ? Color.blue : Color.clear, lineWidth: 3)
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            print("DEBUG: PresetsListView appeared")
            if let currentTextBox = currentTextBox {
                print("DEBUG: currentTextBox provided with presetName: '\(currentTextBox.presetName ?? "nil")'")
            } else {
                print("DEBUG: No currentTextBox provided")
            }
        }
        .sheet(item: $selectedKaraokePreset) { karaokePreset in
            KaraokeColorSelectionView(
                isPresented: Binding(
                    get: { selectedKaraokePreset != nil },
                    set: { newValue in
                        if !newValue {
                            selectedKaraokePreset = nil
                        }
                    }
                ),
                selectedPreset: karaokePreset,
                currentSubtitleText: getCurrentSubtitleText(),
                onConfirm: { highlightColor, wordBGColor, fontColor in
                    handleKaraokePresetSelection(karaokePreset, highlightColor: highlightColor, wordBGColor: wordBGColor, fontColor: fontColor)
                    selectedKaraokePreset = nil // Close the sheet
                }
            )
        }
    }
    
    // Helper function to determine if a preset matches the current TextBox style
    private func isCurrentPreset(_ style: SubtitleStyle) -> Bool {
        guard let currentTextBox = currentTextBox else { 
            print("DEBUG: No currentTextBox provided to PresetsListView")
            return false 
        }
        
        // Match based on preset name
        return currentTextBox.presetName == style.name
    }
    
    // Helper function to handle karaoke preset selection with custom colors
    private func handleKaraokePresetSelection(_ preset: SubtitleStyle, highlightColor: Color, wordBGColor: Color, fontColor: Color) {
        print("DEBUG: Handling karaoke preset selection for '\(preset.name)' with highlight: \(highlightColor), wordBG: \(wordBGColor), font: \(fontColor)")
        
        // Create a custom SubtitleStyle with the selected karaoke colors
        var customizedPreset = SubtitleStyle(
            name: preset.name,
            fontSize: preset.fontSize,
            bgColor: preset.bgColor,
            fontColor: preset.fontColor,
            strokeColor: preset.strokeColor,
            strokeWidth: preset.strokeWidth,
            backgroundPadding: preset.backgroundPadding,
            cornerRadius: preset.cornerRadius,
            shadowColor: preset.shadowColor,
            shadowRadius: preset.shadowRadius,
            shadowX: preset.shadowX,
            shadowY: preset.shadowY,
            shadowOpacity: preset.shadowOpacity,
            isKaraokePreset: true
        )
        
        // Store the custom colors in the customized preset
        customizedPreset.customHighlightColor = highlightColor
        customizedPreset.customWordBGColor = wordBGColor
        customizedPreset.customFontColor = fontColor
        
        print("DEBUG: Created customized preset with custom colors - highlight: \(customizedPreset.customHighlightColor?.description ?? "nil"), wordBG: \(customizedPreset.customWordBGColor?.description ?? "nil"), font: \(customizedPreset.customFontColor?.description ?? "nil")")
        
        // Call the original onSelect with the customized preset
        onSelect(customizedPreset)
        
        // Close the main presets view
        isPresented = false
    }
    
    // Helper function to get the subtitle text that should be showing at current time
    private func getCurrentSubtitleText() -> String? {
        print("DEBUG: PresetsListView - Finding subtitle for currentTime: \(currentTime)")
        
        // Find the textbox that contains the current time
        for textBox in allTextBoxes {
            if textBox.timeRange.contains(currentTime) {
                print("DEBUG: PresetsListView - Found active subtitle: '\(textBox.text)'")
                return textBox.text
            }
        }
        
        // Fallback to currentTextBox if no time-based match
        if let currentText = currentTextBox?.text, !currentText.isEmpty {
            print("DEBUG: PresetsListView - Using currentTextBox: '\(currentText)'")
            return currentText
        }
        
        print("DEBUG: PresetsListView - No subtitle found, using nil")
        return nil
    }
    
    // Helper function to get karaoke type based on preset name
    private func getKaraokeType(for presetName: String) -> KaraokeType {
        switch presetName {
        case "Highlight by letter":
            return .letter
        case "Highlight by word":
            return .word
        case "Background by word":
            return .wordbg
        default:
            return .letter
        }
    }
}