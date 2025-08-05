import SwiftUI

struct PresetsListView: View {
    @Binding var isPresented: Bool
    @Binding var pendingPreset: SubtitleStyle?
    var onSelect: (SubtitleStyle) -> Void
    var currentTextBox: TextBox? = nil
    
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
                            onSelect(style)
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
    }
    
    // Helper function to determine if a preset matches the current TextBox style
    private func isCurrentPreset(_ style: SubtitleStyle) -> Bool {
        guard let currentTextBox = currentTextBox else { 
            print("DEBUG: No currentTextBox provided to PresetsListView")
            return false 
        }
        
        print("DEBUG: Checking preset '\(style.name)' against currentTextBox.presetName: '\(currentTextBox.presetName ?? "nil")'")
        
        // Match based on preset name
        let isMatch = currentTextBox.presetName == style.name
        print("DEBUG: Match result for '\(style.name)': \(isMatch)")
        return isMatch
    }
} 