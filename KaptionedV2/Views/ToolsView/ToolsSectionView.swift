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
                    print("DEBUG: Apply button tapped")
                    if let style = pendingPreset {
                        print("DEBUG: Applying style: \(style.name)")
                        if isKaraokePreset(style) {
                            print("DEBUG: Generating karaoke subtitles")
                            // For karaoke presets, generate new subtitles
                            if let video = editorVM.currentVideo {
                                let karaokeType = getKaraokeType(for: style)
                                // Convert current textBoxes to lines format
                                let lines = textEditor.textBoxes.map { textBox in
                                    (text: textBox.text, start: textBox.timeRange.lowerBound, end: textBox.timeRange.upperBound)
                                }
                                let subs = KaraokeSubsHelper.generateKaraokeSubs(
                                    for: video,
                                    karaokeType: karaokeType,
                                    lines: lines
                                )
                                textEditor.textBoxes = subs
                                editorVM.setText(subs)
                            }
                        } else {
                            print("DEBUG: Applying regular preset")
                            // For regular presets, apply style to existing subtitles
                            textEditor.textBoxes = textEditor.textBoxes.map { style.apply(to: $0) }
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
                        let alert = UIAlertController(title: "Generate Subtitles?", 
                            message: "This will replace any existing subtitles. Continue?",
                            preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        
                        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
                            editorVM.isLoading = true
                            TranscriptionHelper.shared.transcribeVideo(fileURL: video.url) { result in
                                DispatchQueue.main.async {
                                    editorVM.isLoading = false
                                    switch result {
                                    case .success(let subs):
                                        textEditor.textBoxes = subs
                                        editorVM.setText(subs)
                                    case .failure(let error):
                                        editorVM.errorMessage = "Failed to generate subtitles: \(error.localizedDescription)"
                                        editorVM.showErrorAlert = true
                                    }
                                }
                            }
                        })
                        
                        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
                    }
                    Text("Generate Subs")
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
                        showEditSubtitlesMode = true
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
    
    private func isKaraokePreset(_ style: SubtitleStyle) -> Bool {
        return style.name == "Highlight by letter" || 
               style.name == "Highlight by word" || 
               style.name == "Background by word"
    }
    
    private func getKaraokeType(for style: SubtitleStyle) -> KaraokeType {
        switch style.name {
        case "Highlight by letter": return .letter
        case "Highlight by word": return .word
        case "Background by word": return .wordbg
        default: return .word
        }
    }


}



