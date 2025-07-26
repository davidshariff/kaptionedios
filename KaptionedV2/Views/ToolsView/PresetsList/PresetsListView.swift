import SwiftUI
// SubtitleStyle is defined in Models/TextBox.swift. Ensure this file is included in the build target so the type is available here.

struct PresetsListView: View {
    @Binding var showPresetConfirm: Bool
    @Binding var pendingPreset: SubtitleStyle?
    var onSelect: (SubtitleStyle) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select a Subtitle Style")
                .font(.headline)
                .padding(.bottom, 8)
            ForEach(SubtitleStyle.allPresets) { style in
                Button(action: {
                    onSelect(style)
                }) {
                    HStack {
                        Text(style.name)
                            .padding()
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
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.top, 16)
    }
} 