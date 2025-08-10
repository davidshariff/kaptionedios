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

            ZStack {
                Text("Select a Subtitle Style")
                    .font(.system(size: UIFont.preferredFont(forTextStyle: .title2).pointSize, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue)
                    .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    )
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.gray.opacity(0.7))
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                    .shadow(color: Color.black.opacity(0.10), radius: 2, x: 0, y: 1)
                            )
                    }
                    .padding(.trailing, 20)
                }
            }
            .padding(.top, 12)
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 12) {
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
                            VStack(spacing: 6) {
                                // Prominent preview - takes most of the space
                                PresetPreviewView(
                                    preset: style,
                                    previewText: getCurrentSubtitleText() ?? "Sample Text",
                                    animateKaraoke: style.isKaraokePreset
                                )
                                .frame(height: 40)
                                
                                // Compact title only
                                Text(style.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(height: 24) // Fixed height for consistency
                            }
                            .padding(8)
                            .frame(height: 80) // Fixed total height for all presets
                            .background(isCurrentPreset(style) ? Color.blue.opacity(0.3) : Color(.systemGray5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isCurrentPreset(style) ? Color.blue : Color.clear, lineWidth: 2)
                            )
                            .cornerRadius(8)
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
        
        // Find the textbox that contains the current time
        for textBox in allTextBoxes {
            if textBox.timeRange.contains(currentTime) {
                return textBox.text
            }
        }
        
        // Fallback to currentTextBox if no time-based match
        if let currentText = currentTextBox?.text, !currentText.isEmpty {
            return currentText
        }
        
        return nil
    }
    
    // Helper function to get karaoke type based on preset name
    private func getKaraokeType(for presetName: String) -> KaraokeType {
        switch presetName {
        case "Highlight by word":
            return .word
        case "Background by word":
            return .wordbg
        default:
            return .word
        }
    }
}