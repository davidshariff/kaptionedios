import SwiftUI
import AVKit

struct ToolsSectionView: View {

    @StateObject var filtersVM = FiltersViewModel()
    @ObservedObject var videoPlayer: VideoPlayerManager
    @ObservedObject var editorVM: EditorViewModel
    @ObservedObject var textEditor: TextEditorViewModel
    @Binding var showCustomSubslistSheet: Bool
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
                .opacity(editorVM.selectedTools != nil ? 0 : 1)
            if let toolState = editorVM.selectedTools, let video = editorVM.currentVideo {
                bottomSheet(toolState, video)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
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
            .animation(.easeIn(duration: 0.15), value: editorVM.selectedTools)
        .onChange(of: editorVM.currentVideo){ newValue in
            if let video = newValue, let image = video.thumbnailsImages.first?.image{
                filtersVM.loadFilters(for: image)
                filtersVM.colorCorrection = video.colorCorrection
                textEditor.textBoxes = video.textBoxes
            }
        }
        .onChange(of: textEditor.selectedTextBox) { box in
            if box != nil{
                // Text selection is no longer handled through tools
            }else{
                editorVM.selectedTools = nil
            }
        }
        .onChange(of: editorVM.selectedTools) { newValue in
            
            if newValue == nil{
                editorVM.setText(textEditor.textBoxes)
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
                    ToolButtonView(label: "Edit", image: "list.bullet", isChange: false) {
                        // Handle edit subtitles action
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEditSubtitlesMode = true
                        }
                    }
                    Text("Edit Subtitles")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .frame(height: 32)
                        .multilineTextAlignment(.center)
                }
            }
            ForEach(Array(ToolEnum.allCases.filter { $0 != .subslist }.enumerated()), id: \.element) { index, tool in
                VStack(spacing: 4) {
                    ToolButtonView(label: tool.title, image: tool.image, isChange: editorVM.currentVideo?.isAppliedTool(for: tool) ?? false) {
                        editorVM.selectedTools = tool
                    }
                    Text(toolLabel(for: tool))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .frame(height: 32)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct ToolsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        MainEditorView(selectedVideoURl: Video.mock.url)
    }
}


extension ToolsSectionView{
    
    @ViewBuilder
    private func bottomSheet(_ tool: ToolEnum, _ video: Video) -> some View{
        
        VStack(spacing: 16){
            
            sheetHeader(tool)
            switch tool {
            case .subslist:
                // Trigger custom bottom sheet
                Color.clear.onAppear {
                    showCustomSubslistSheet = true
                    // Close the regular bottom sheet
                    DispatchQueue.main.async {
                        editorVM.selectedTools = nil
                    }
                }
            case .presets:
                // Open the custom bottom sheet and close the bottom sheet
                Color.clear.onAppear {
                    showPresetsBottomSheet = true
                    // Close the bottom sheet
                    DispatchQueue.main.async {
                        editorVM.selectedTools = nil
                    }
                }
            }
            Spacer()
        }
        .padding([.horizontal, .top])
        .background(Color(.systemGray6))
    }
}

extension ToolsSectionView{
    
    private func sheetHeader(_ tool: ToolEnum) -> some View{
        HStack {
            Button {
                editorVM.selectedTools = nil
            } label: {
                Image(systemName: "chevron.down")
                    .imageScale(.small)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 5))
            }
            Spacer()
            Button {
                editorVM.reset()
            } label: {
                Text("Reset")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
        .overlay {
            Text(tool.title)
                .font(.headline)
        }
    }
    
}

extension ToolsSectionView {

    private func toolLabel(for tool: ToolEnum) -> String {
        switch tool {
        case .presets:
            return selectedPreset?.name ?? "Select Template"
        case .subslist:
            return "Subtitle list"
        }
    }
    
    private func getKaraokeType(for style: SubtitleStyle) -> KaraokeType {
        switch style.name {
        case "Highlight by word": return .word
        case "Background by word": return .wordbg
        default: return .word
        }
    }

}



