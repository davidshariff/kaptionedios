//
//  ToolsSectionView.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 18.04.2023.
//

import SwiftUI
import AVKit

struct TranscriptionWord: Codable {
    let word: String
    let start: Double
    let end: Double
    let probability: Double
}

struct TranscriptionSegment: Codable {
    let sentence: String
    let words: [TranscriptionWord]
}

struct TranscriptionResponse: Codable {
    let segments: [TranscriptionSegment]
}

struct ToolsSectionView: View {
    @StateObject var filtersVM = FiltersViewModel()
    @ObservedObject var videoPlayer: VideoPlayerManager
    @ObservedObject var editorVM: EditorViewModel
    @ObservedObject var textEditor: TextEditorViewModel
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)
    @State private var showPresetAlert = false
    @State private var selectedPresetName: String? = nil
    @State private var showPresetsSheet = false
    @State private var showPresetConfirm = false
    @State private var pendingPreset: SubtitleStyle? = nil
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
            .sheet(isPresented: $showPresetsSheet) {
                PresetsListView(showPresetConfirm: $showPresetConfirm, pendingPreset: $pendingPreset, onSelect: { style in
                    print("DEBUG: Preset selected: \(style.name)")
                    pendingPreset = style
                    showPresetConfirm = true
                    print("DEBUG: showPresetConfirm set to: \(showPresetConfirm)")
                })
            }
            .confirmationDialog(
                isKaraokePreset(pendingPreset ?? SubtitleStyle.allPresets[0]) ? 
                    "⚠️ Generate Karaoke Subtitles?" : 
                    "Apply preset to all subtitles?",
                isPresented: $showPresetConfirm,
                titleVisibility: .visible
            ) {
                Button(isKaraokePreset(pendingPreset ?? SubtitleStyle.allPresets[0]) ? 
                       "🗑️ Clear & Generate" : 
                       "Apply", role: .destructive) {
                    print("DEBUG: Apply button tapped")
                    if let style = pendingPreset {
                        print("DEBUG: Applying style: \(style.name)")
                        if isKaraokePreset(style) {
                            print("DEBUG: Generating karaoke subtitles")
                            // For karaoke presets, generate new subtitles
                            if let video = editorVM.currentVideo {
                                let karaokeType = getKaraokeType(for: style)
                                let subs = Helpers.generateKaraokeSubs(for: video, karaokeType: karaokeType)
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
                        showPresetsSheet = false
                    }
                }
                Button("Cancel", role: .cancel) {
                    print("DEBUG: Cancel button tapped")
                    pendingPreset = nil
                }
            } message: {
                Text(isKaraokePreset(pendingPreset ?? SubtitleStyle.allPresets[0]) ? 
                     "🚨 This will DELETE all existing subtitles and generate new karaoke subtitles. This action cannot be undone." :
                     "This will replace the style of all subtitles with the selected preset.")
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
                if editorVM.selectedTools != .text{
                    editorVM.selectedTools = .text
                }
            }else{
                editorVM.selectedTools = nil
            }
        }
        .onChange(of: editorVM.selectedTools) { newValue in
            
            if newValue == .text, textEditor.textBoxes.isEmpty{
                textEditor.openTextEditor(isEdit: false, timeRange: editorVM.currentVideo?.rangeDuration)
            }
            
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
                            transcribeVideo(fileURL: video.url) { result in
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
            }
            ForEach(Array(ToolEnum.allCases.enumerated()), id: \.element) { index, tool in
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
        
        let isAppliedTool = video.isAppliedTool(for: tool)
        
        VStack(spacing: 16){
            
            sheetHeader(tool)
            switch tool {
            case .cut:
                ThumbnailsSliderView(curretTime: $videoPlayer.currentTime, video: $editorVM.currentVideo, isChangeState: isAppliedTool) {
                    videoPlayer.scrubState = .scrubEnded(videoPlayer.currentTime)
                    editorVM.setTools()
                }
            //case .speed:
            //    VideoSpeedSlider(value: Double(video.rate), isChangeState: isAppliedTool) {rate in
            //        videoPlayer.pause()
            //        editorVM.updateRate(rate: rate)
            //    }
            //case .crop:
            //    CropSheetView(editorVM: editorVM)
            //case .audio:
            //    AudioSheetView(videoPlayer: videoPlayer, editorVM: editorVM)
            case .text:
                TextToolsView(video: video, editor: textEditor)
            // case .filters:
            //     FiltersView(selectedFilterName: video.filterName, viewModel: filtersVM) { filterName in
            //         if let filterName{
            //             videoPlayer.setFilters(mainFilter: CIFilter(name: filterName), colorCorrection: filtersVM.colorCorrection)
            //         }else{
            //             videoPlayer.removeFilter()
            //         }
            //         editorVM.setFilter(filterName)
            //     }
            // case .corrections:
            //     CorrectionsToolView(correction: $filtersVM.colorCorrection) { corrections in
            //         videoPlayer.setFilters(mainFilter: CIFilter(name: video.filterName ?? ""), colorCorrection: corrections)
            //         editorVM.setCorrections(corrections)
            //     }
            //case .frames:
            //    FramesToolView(selectedColor: $editorVM.frames.frameColor, scaleValue: $editorVM.frames.scaleValue, onChange: editorVM.setFrames)
            case .presets:
                // Open the custom sheet and close the bottom sheet
                Color.clear.onAppear {
                    showPresetsSheet = true
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
            if tool != .text{
                Button {
                    editorVM.reset()
                } label: {
                    Text("Reset")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
            else if !editorVM.isSelectVideo{
                Button {
                    videoPlayer.pause()
                    editorVM.removeAudio()
                } label: {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                }
            }
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
        case .text:
            return "Add text overlays"
        case .presets:
            return selectedPreset?.name ?? "Select presets"
        case .cut:
            return "Trim video"
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

    private func transcribeVideo(
        fileURL: URL,
        completion: @escaping (Result<[TextBox], Error>) -> Void
    ) {
        let url = URL(string: "http://127.0.0.1:8000/transcribe")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        var data = Data()
        // Add file
        let filename = fileURL.lastPathComponent
        let mimetype = "video/quicktime"
        guard let fileData = try? Data(contentsOf: fileURL) else {
            completion(.failure(NSError(domain: "File error", code: 0)))
            return
        }
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        // Add primary_lang
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"primary_lang\"\r\n\r\n".data(using: .utf8)!)
        data.append("en\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        let task = URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let responseData = responseData else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(TranscriptionResponse.self, from: responseData)
                let textBoxes = result.segments.map { segment in
                    let start = segment.words.first?.start ?? 0
                    let end = segment.words.last?.end ?? (start + 1)
                    let karaokeWords = segment.words.map { w in
                        KaraokeWord(text: w.word, start: w.start, end: w.end)
                    }
                    return TextBox(
                        text: segment.sentence,
                        timeRange: start...end,
                        karaokeWords: karaokeWords,
                        karaokeType: .word
                    )
                }
                completion(.success(textBoxes))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

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

