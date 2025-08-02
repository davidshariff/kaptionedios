import SwiftUI

struct PresetsBottomSheetView: View {
    @Binding var isPresented: Bool
    @Binding var showPresetConfirm: Bool
    @Binding var pendingPreset: SubtitleStyle?
    var onSelect: (SubtitleStyle) -> Void
    
    var body: some View {
        SheetView(isPresented: $isPresented, bgOpacity: 0.3) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select a Subtitle Style")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
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
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Invisible spacer element to provide extra scroll space
                        Color.clear
                            .frame(height: 100)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
            }
            .frame(height: getRect().height / 1.8) // Fixed height to maintain half screen size
        }
    }
} 