//
//  ToolsSectionView.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 18.04.2023.
//

import SwiftUI
import AVKit

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
                    pendingPreset = style
                    showPresetConfirm = true
                })
                .confirmationDialog(
                    "Apply preset to all subtitles?",
                    isPresented: $showPresetConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Apply", role: .destructive) {
                        if let style = pendingPreset {
                            textEditor.textBoxes = textEditor.textBoxes.map { style.apply(to: $0) }
                            editorVM.setText(textEditor.textBoxes)
                            selectedPreset = style // Track the selected preset
                        }
                        showPresetConfirm = false
                        pendingPreset = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showPresetsSheet = false
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        pendingPreset = nil
                    }
                } message: {
                    Text("This will replace the style of all subtitles with the selected preset.")
                }
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
                            let isKaraoke = (selectedPreset?.name ?? "") == "Karaoke Highlight"
                            let subs = isKaraoke ? Helpers.generateKaraokeSubs(for: video) : Helpers.generateTestSubs(for: video)
                            textEditor.textBoxes = subs
                            editorVM.setText(subs)
                        })
                        
                        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
                    }
                    Text("Test Subs")
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
            return "Select presets"
        case .cut:
            return "Trim video"
        }
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

