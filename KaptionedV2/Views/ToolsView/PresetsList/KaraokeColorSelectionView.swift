import SwiftUI
import Foundation

struct KaraokeColorSelectionView: View {
    @Binding var isPresented: Bool
    let selectedPreset: SubtitleStyle
    let onConfirm: (Color, Color, Color) -> Void
    let currentSubtitleText: String?

    @State private var selectedHighlightColor: Color
    @State private var selectedWordBGColor: Color
    @State private var selectedFontColor: Color

    private let colorOptions: [Color] = [
        .blue, .red, .green, .orange, .yellow, .purple, .pink, .cyan,
        .mint, .teal, .indigo, .brown, .gray, .black, .white, .clear
    ]

    init(isPresented: Binding<Bool>, selectedPreset: SubtitleStyle, currentSubtitleText: String?, onConfirm: @escaping (Color, Color, Color) -> Void) {
        self._isPresented = isPresented
        self.selectedPreset = selectedPreset
        self.currentSubtitleText = currentSubtitleText
        self.onConfirm = onConfirm

        // Initialize with default colors based on preset type
        switch selectedPreset.name {
        case "Highlight by letter":
            self._selectedHighlightColor = State(initialValue: .blue)
            self._selectedWordBGColor = State(initialValue: .clear)
            self._selectedFontColor = State(initialValue: selectedPreset.fontColor)
        case "Highlight by word":
            self._selectedHighlightColor = State(initialValue: .orange)
            self._selectedWordBGColor = State(initialValue: .clear)
            self._selectedFontColor = State(initialValue: selectedPreset.fontColor)
        case "Background by word":
            self._selectedHighlightColor = State(initialValue: .yellow)
            self._selectedWordBGColor = State(initialValue: .blue)
            self._selectedFontColor = State(initialValue: selectedPreset.fontColor)
        default:
            self._selectedHighlightColor = State(initialValue: .blue)
            self._selectedWordBGColor = State(initialValue: .clear)
            self._selectedFontColor = State(initialValue: selectedPreset.fontColor)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Customize Animation Colors")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("for \"\(selectedPreset.name)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

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
            .padding(.horizontal)
            .padding(.top)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack {
                            Spacer()

                            RoundedRectangle(cornerRadius: selectedPreset.cornerRadius)
                                .fill(selectedPreset.bgColor)
                                .frame(width: 120, height: 40)
                                .overlay(
                                    HStack(spacing: 2) {
                                        if previewWords.count >= 1 {
                                            Text(previewWords[0])
                                                .font(.system(size: selectedPreset.fontSize * 0.4))
                                                .foregroundColor(getPreviewHighlightColor())
                                                .padding(.horizontal, getPreviewWordBGColor() != .clear ? 4 : 0)
                                                .padding(.vertical, getPreviewWordBGColor() != .clear ? 2 : 0)
                                                .background(getPreviewWordBGColor())
                                                .cornerRadius(2)
                                        }
                                        if previewWords.count >= 2 {
                                            Text(previewWords[1])
                                                .font(.system(size: selectedPreset.fontSize * 0.4))
                                                .foregroundColor(selectedFontColor)
                                        } else if previewWords.count == 1 && previewWords[0].count > 3 {
                                            // If only one word, show part of it as unhighlighted
                                            Text(String(previewWords[0].dropFirst(min(3, previewWords[0].count))))
                                                .font(.system(size: selectedPreset.fontSize * 0.4))
                                                .foregroundColor(selectedFontColor)
                                        }
                                    }
                                )

                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    // Highlight Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Highlight Color")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Color of the active word.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                            ForEach(colorOptions, id: \.self) { color in
                                Button(action: {
                                    selectedHighlightColor = color
                                }) {
                                    Circle()
                                        .fill(color == .clear ? Color.white : color)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedHighlightColor == color ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedHighlightColor == color ? 3 : 1)
                                        )
                                        .overlay(
                                            // Show diagonal line for clear color
                                            color == .clear ?
                                            Path { path in
                                                path.move(to: CGPoint(x: 4, y: 28))
                                                path.addLine(to: CGPoint(x: 28, y: 4))
                                            }
                                            .stroke(Color.red, lineWidth: 2)
                                            : nil
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    // Word Background Color Selection (only for wordbg type)
                    if selectedPreset.name == "Background by word" {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Word Background Color")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Background color of the active word.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                                ForEach(colorOptions, id: \.self) { color in
                                    Button(action: {
                                        selectedWordBGColor = color
                                    }) {
                                        Circle()
                                            .fill(color == .clear ? Color.white : color)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedWordBGColor == color ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedWordBGColor == color ? 3 : 1)
                                            )
                                            .overlay(
                                                // Show diagonal line for clear color
                                                color == .clear ?
                                                Path { path in
                                                    path.move(to: CGPoint(x: 4, y: 28))
                                                    path.addLine(to: CGPoint(x: 28, y: 4))
                                                }
                                                .stroke(Color.red, lineWidth: 2)
                                                : nil
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }

                    // Font Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Font Color")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Color of words not highlighted.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                            ForEach(colorOptions, id: \.self) { color in
                                Button(action: {
                                    selectedFontColor = color
                                }) {
                                    Circle()
                                        .fill(color == .clear ? Color.white : color)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedFontColor == color ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedFontColor == color ? 3 : 1)
                                        )
                                        .overlay(
                                            // Show diagonal line for clear color
                                            color == .clear ?
                                            Path { path in
                                                path.move(to: CGPoint(x: 4, y: 28))
                                                path.addLine(to: CGPoint(x: 28, y: 4))
                                            }
                                            .stroke(Color.red, lineWidth: 2)
                                            : nil
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    // Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            print("DEBUG: Cancel button tapped")
                            isPresented = false
                        }) {
                            Text("Cancel")
                                .foregroundColor(.primary)
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            print("DEBUG: Apply button tapped")
                            onConfirm(selectedHighlightColor, selectedWordBGColor, selectedFontColor)
                            isPresented = false
                        }) {
                            Text("Apply")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

        private var previewText: String {
        print("DEBUG: KaraokeColorSelectionView - currentSubtitleText: '\(currentSubtitleText ?? "nil")'")
        return currentSubtitleText?.isEmpty == false ? currentSubtitleText! : "Your Subtitle"
    }
    
    private var previewWords: [String] {
        return previewText.split(separator: " ").map(String.init)
    }
    
    private func getPreviewHighlightColor() -> Color {
        return selectedHighlightColor
    }

    private func getPreviewWordBGColor() -> Color {
        switch selectedPreset.name {
        case "Background by word":
            return selectedWordBGColor
        default:
            return .clear
        }
    }
}

#Preview {
    KaraokeColorSelectionView(
        isPresented: .constant(true),
        selectedPreset: SubtitleStyle.allPresets.first(where: { $0.name == "Highlight by word" })!,
        currentSubtitleText: "Sample text for preview",
        onConfirm: { _, _, _ in }
    )
}
