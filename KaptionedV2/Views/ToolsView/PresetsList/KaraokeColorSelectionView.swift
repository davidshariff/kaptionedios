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

    init(isPresented: Binding<Bool>, selectedPreset: SubtitleStyle, currentSubtitleText: String?, currentHighlightColor: Color? = nil, currentWordBGColor: Color? = nil, currentFontColor: Color? = nil, onConfirm: @escaping (Color, Color, Color) -> Void) {
        self._isPresented = isPresented
        self.selectedPreset = selectedPreset
        self.currentSubtitleText = currentSubtitleText
        self.onConfirm = onConfirm

        // Use current colors if provided, otherwise fall back to defaults based on preset type
        let defaultHighlightColor: Color
        let defaultWordBGColor: Color
        
        switch selectedPreset.name {
        case "Highlight by word":
            defaultHighlightColor = .blue // Use the updated default from KaraokePreset.word
            defaultWordBGColor = .clear
        case "Background by word":
            defaultHighlightColor = .yellow
            defaultWordBGColor = .blue
        default:
            defaultHighlightColor = .blue
            defaultWordBGColor = .clear
        }
        
        self._selectedHighlightColor = State(initialValue: currentHighlightColor ?? defaultHighlightColor)
        self._selectedWordBGColor = State(initialValue: currentWordBGColor ?? defaultWordBGColor)
        self._selectedFontColor = State(initialValue: currentFontColor ?? selectedPreset.fontColor)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [selectedPreset.bgColor.opacity(0.7), selectedPreset.fontColor.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 38, height: 38)
                        Image(systemName: "music.note.list")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Customize Animation Colors")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        HStack(spacing: 4) {
                            Text("Preset:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\"\(selectedPreset.name)\"")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedPreset.fontColor)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
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
                            
                            PresetPreviewView(
                                preset: selectedPreset,
                                previewText: previewText,
                                highlightColor: selectedHighlightColor,
                                wordBGColor: selectedWordBGColor,
                                fontColor: selectedFontColor,
                                animateKaraoke: true,
                                fontSize: 18
                            )
                            .onAppear {
                                print("DEBUG KaraokeColorSelectionView: PresetPreviewView appeared with highlightColor=\(selectedHighlightColor)")
                            }
                            .onChange(of: selectedHighlightColor) { newColor in
                                print("DEBUG KaraokeColorSelectionView: selectedHighlightColor changed to \(newColor)")
                            }
                            .frame(width: 200, height: 60)

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
                                        .frame(width: selectedHighlightColor == color ? 36 : 32, height: selectedHighlightColor == color ? 36 : 32)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedHighlightColor == color ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedHighlightColor == color ? 3 : 1)
                                        )
                                        .overlay(
                                            // Show diagonal line for clear color
                                            color == .clear ?
                                            Path { path in
                                                let size: CGFloat = selectedHighlightColor == color ? 36 : 32
                                                let offset: CGFloat = selectedHighlightColor == color ? 6 : 4
                                                let endOffset: CGFloat = selectedHighlightColor == color ? 30 : 28
                                                path.move(to: CGPoint(x: offset, y: size - offset))
                                                path.addLine(to: CGPoint(x: size - offset, y: offset))
                                            }
                                            .stroke(Color.red, lineWidth: 2)
                                            : nil
                                        )
                                        .scaleEffect(selectedHighlightColor == color ? 1.0 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: selectedHighlightColor)
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
                                            .frame(width: selectedWordBGColor == color ? 36 : 32, height: selectedWordBGColor == color ? 36 : 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedWordBGColor == color ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedWordBGColor == color ? 3 : 1)
                                            )
                                            .overlay(
                                                // Show diagonal line for clear color
                                                color == .clear ?
                                                Path { path in
                                                    let size: CGFloat = selectedWordBGColor == color ? 36 : 32
                                                    let offset: CGFloat = selectedWordBGColor == color ? 6 : 4
                                                    let endOffset: CGFloat = selectedWordBGColor == color ? 30 : 28
                                                    path.move(to: CGPoint(x: offset, y: size - offset))
                                                    path.addLine(to: CGPoint(x: size - offset, y: offset))
                                                }
                                                .stroke(Color.red, lineWidth: 2)
                                                : nil
                                            )
                                            .scaleEffect(selectedWordBGColor == color ? 1.0 : 1.0)
                                            .animation(.easeInOut(duration: 0.2), value: selectedWordBGColor)
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
                                        .frame(width: selectedFontColor == color ? 36 : 32, height: selectedFontColor == color ? 36 : 32)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedFontColor == color ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedFontColor == color ? 3 : 1)
                                        )
                                        .overlay(
                                            // Show diagonal line for clear color
                                            color == .clear ?
                                            Path { path in
                                                let size: CGFloat = selectedFontColor == color ? 36 : 32
                                                let offset: CGFloat = selectedFontColor == color ? 6 : 4
                                                let endOffset: CGFloat = selectedFontColor == color ? 30 : 28
                                                path.move(to: CGPoint(x: offset, y: size - offset))
                                                path.addLine(to: CGPoint(x: size - offset, y: offset))
                                            }
                                            .stroke(Color.red, lineWidth: 2)
                                            : nil
                                        )
                                        .scaleEffect(selectedFontColor == color ? 1.0 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: selectedFontColor)
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
}

#Preview {
    KaraokeColorSelectionView(
        isPresented: .constant(true),
        selectedPreset: SubtitleStyle.allPresets.first(where: { $0.name == "Highlight by word" })!,
        currentSubtitleText: "Sample text for preview",
        currentHighlightColor: .blue,
        currentWordBGColor: .clear,
        currentFontColor: .yellow,
        onConfirm: { _, _, _ in }
    )
}
