import SwiftUI

struct PresetsListView: View {
    @Binding var isPresented: Bool
    @Binding var pendingPreset: SubtitleStyle?
    var onSelect: (SubtitleStyle) -> Void
    
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
                            .background(Color(.systemGray5))
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
    }
} 