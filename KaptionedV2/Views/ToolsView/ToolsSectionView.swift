import SwiftUI
import AVKit

struct PrimaryToolbarView: View {
    
    @ObservedObject var videoPlayer: VideoPlayerManager
    @ObservedObject var editorVM: EditorViewModel
    @ObservedObject var textEditor: TextEditorViewModel

    @Binding var showEditSubtitlesMode: Bool
    @Binding var showPresetsBottomSheet: Bool
    @Binding var showPresetConfirm: Bool
    @Binding var pendingPreset: SubtitleStyle?
    private let columns = Array(repeating: GridItem(.fixed(90)), count: 3)
    @State private var selectedPreset: SubtitleStyle? = nil
    
    var body: some View {
        let mainContent = ZStack {
            toolGrid
                .padding()
        }
                return mainContent
            .confirmationDialog(
                "Apply preset to all subtitles?",
                isPresented: $showPresetConfirm,
                titleVisibility: .visible
            ) {
                Button("Apply", role: .destructive) {

                    if let style = pendingPreset {

                        print("DEBUG: Applying style: \(style.name)")
                        
                        if style.isKaraokePreset {

                            print("DEBUG: Generating karaoke subtitles")

                            // For karaoke presets, generate new subtitles
                            if let video = editorVM.currentVideo {

                                let karaokeType = getKaraokeType(for: style)
                                
                                print("DEBUG: Applying karaoke preset with custom colors - highlight: \(style.customHighlightColor?.description ?? "nil"), wordBG: \(style.customWordBGColor?.description ?? "nil"), font: \(style.customFontColor?.description ?? "nil")")

                                let subs = KaraokeSubsHelper.generateKaraokeSubs(
                                    for: video,
                                    karaokeType: karaokeType,
                                    textBoxes: textEditor.textBoxes,
                                    customHighlightColor: style.customHighlightColor,
                                    customWordBGColor: style.customWordBGColor,
                                    customFontColor: style.customFontColor
                                )

                                // Update the textBoxes in the textEditor and the editorVM
                                textEditor.textBoxes = subs
                                editorVM.setText(subs)
                            }

                        } 
                        else {
                            print("DEBUG: Applying regular preset")
                            // For regular presets, apply style to existing subtitles
                            textEditor.textBoxes = textEditor.textBoxes.map { box in
                                var newBox = style.apply(to: box)
                                // Get all property names from the style-applied box (these are the ones overridden by the style)
                                let styleMirror = Mirror(reflecting: newBox)
                                let stylePropertyNames = Set(styleMirror.children.compactMap { $0.label })
                                // Copy all other properties from the original box to the new one, except those set by the style or explicitly reset
                                let boxMirror = Mirror(reflecting: box)
                                for child in boxMirror.children {
                                    if let label = child.label {
                                        // Skip properties that are set by the style or need to be reset
                                        if stylePropertyNames.contains(label) ||
                                            ["isKaraokePreset", "karaokeType", "highlightColor", "wordBGColor"].contains(label) {
                                            continue
                                        }
                                        // Use KVC if available (NSObject), otherwise this is a no-op for structs
                                        (newBox as AnyObject).setValue(child.value, forKey: label)
                                    }
                                }
                                // Reset karaoke properties
                                newBox.isKaraokePreset = false
                                newBox.karaokeType = nil
                                newBox.highlightColor = nil
                                newBox.wordBGColor = nil
                                return newBox
                            }
                            editorVM.setText(textEditor.textBoxes)
                        }

                        selectedPreset = style // Track the selected preset
                    }
                    showPresetConfirm = false
                    pendingPreset = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showPresetsBottomSheet = false
                    }
                }
                Button("Cancel", role: .cancel) {
                    print("DEBUG: Cancel button tapped")
                    pendingPreset = nil
                }
            } message: {
                Text("This will replace the style of all subtitles with the selected preset.")
            }

        .onChange(of: editorVM.currentVideo){ newValue in
                    if let video = newValue{
            textEditor.textBoxes = video.textBoxes
        }
        }


    }

    private var toolGrid: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 8) {
            // Autogenerate button
            if let video = editorVM.currentVideo {
                VStack(spacing: 4) {
                    ToolButtonView(label: "Generate", image: "wand.and.stars", isChange: false) {
                        // Use the shared subtitle generation method with confirmation
                        editorVM.generateSubtitles(showConfirmation: true)
                    }
                    Text("Generate Captions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .frame(height: 32)
                        .multilineTextAlignment(.center)
                }
                
                // Edit Subtitles button
                VStack(spacing: 4) {
                    ToolButtonView(label: "Edit", image: "pencil", isChange: false) {
                        // Handle edit subtitles action
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEditSubtitlesMode = true
                            videoPlayer.pause()
                        }
                    }
                    Text("Edit Text & Styles")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .frame(height: 32)
                        .multilineTextAlignment(.center)
                }
            }
            // Presets button
            VStack(spacing: 4) {
                ToolButtonView(label: "Templates", image: "camera.filters", isChange: false) {
                    showPresetsBottomSheet = true
                }
                Text(selectedPreset?.name ?? "Pre-made Templates")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .frame(height: 32)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
    
private func getKaraokeType(for style: SubtitleStyle) -> KaraokeType {
    switch style.name {
        case "Highlight by word": return .word
        case "Background by word": return .wordbg
        case "Word & Scale": return .wordAndScale
        default: return .word
    }
}




