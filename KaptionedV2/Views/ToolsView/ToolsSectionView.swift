//
//  ToolsSectionView.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 18.04.2023.
//

import SwiftUI
import AVKit
import Foundation

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
    @Binding var showCustomSubslistSheet: Bool
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
                        showPresetsSheet = false
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
            case .subslist:
                // Trigger custom bottom sheet
                Color.clear.onAppear {
                    showCustomSubslistSheet = true
                    // Close the regular bottom sheet
                    DispatchQueue.main.async {
                        editorVM.selectedTools = nil
                    }
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

struct SubslistPlaceholderView: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "list.bullet")
                    .font(.system(size: 80))
                    .foregroundColor(.secondary)
                Text("Subslist Tool")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("This is a placeholder for the subslist functionality")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Add more content to make it taller
                VStack(spacing: 12) {
                    Text("Features coming soon:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Subtitle management")
                        }
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Timing adjustments")
                        }
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Style customization")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height / 2)
            .background(Color(.systemGray6))
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

struct CustomSubslistBottomSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var textEditor: TextEditorViewModel
    @ObservedObject var videoPlayer: VideoPlayerManager
    
    // Helper to get the total video duration
    var totalDuration: Double {
        // Use the max end time of all textBoxes, fallback to 1
        textEditor.textBoxes.map { $0.timeRange.upperBound }.max() ?? 1
    }
    
    // Timeline scale: pixels per second
    private let timelineScale: CGFloat = 40 // px per second

    // Computed property for total content height
    private var totalContentHeight: CGFloat {
        CGFloat(totalDuration) * timelineScale
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isPresented = false
                        }
                    }
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 20) {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 16)
                        }
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Color.gray)
                            .frame(width: 36, height: 5)
                            .padding(.top, -8)
                        VStack(spacing: 16) {
                            Text("Subtitles")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            if textEditor.textBoxes.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "text.bubble")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("No subtitles yet")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Text("Add subtitles using the Text tool")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 40)
                            } else {
                                // Shared vertical scroll view for scrubber and subtitles
                                ScrollViewReader { scrollProxy in
                                    ScrollView([.vertical], showsIndicators: true) {
                                        ZStack(alignment: .topLeading) {
                                            // Scrubber
                                            InteractiveVerticalScrubberAbsolute(
                                                textBoxes: textEditor.textBoxes,
                                                selectedTextBox: textEditor.selectedTextBox,
                                                totalDuration: totalDuration,
                                                timelineScale: timelineScale,
                                                currentTime: videoPlayer.currentTime,
                                                onTimeChanged: { newTime in
                                                    videoPlayer.currentTime = newTime
                                                }
                                            )
                                            .frame(width: 48, height: totalContentHeight)
                                            // Subtitle rows
                                            ForEach(Array(textEditor.textBoxes.enumerated()), id: \.offset) { index, textBox in
                                                let startY = CGFloat(textBox.timeRange.lowerBound) * timelineScale
                                                let endY = CGFloat(textBox.timeRange.upperBound) * timelineScale
                                                let rowHeight = endY - startY
                                                
                                                // Start boundary line (dashed)
                                                Rectangle()
                                                    .fill(Color.white.opacity(0.6))
                                                    .frame(width: geometry.size.width - 40, height: 1)
                                                    .position(x: (geometry.size.width - 40) / 2 + 20, y: startY)
                                                    .zIndex(500)
                                                
                                                // End boundary line (dashed)
                                                Rectangle()
                                                    .fill(Color.white.opacity(0.6))
                                                    .frame(width: geometry.size.width - 40, height: 1)
                                                    .position(x: (geometry.size.width - 40) / 2 + 20, y: endY)
                                                    .zIndex(500)
                                                
                                                SubtitleRowView(
                                                    index: index,
                                                    textBox: textBox,
                                                    isSelected: textEditor.selectedTextBox == textBox
                                                ) {
                                                    textEditor.selectTextBox(textBox)
                                                    withAnimation {
                                                        scrollProxy.scrollTo(index, anchor: .center)
                                                    }
                                                }
                                                .frame(height: rowHeight)
                                                .frame(maxWidth: .infinity)
                                                .background(Color.clear)
                                                .position(x: geometry.size.width / 2 + 4, y: startY + rowHeight / 2)
                                                .id(index)
                                            }
                                            // Current time indicator line
                                            Rectangle()
                                                .fill(Color.red)
                                                .frame(width: geometry.size.width - 40, height: 2)
                                                .position(x: (geometry.size.width - 40) / 2 + 20, y: CGFloat(videoPlayer.currentTime) * timelineScale)
                                                .shadow(color: Color.red.opacity(0.8), radius: 2)
                                                .zIndex(1000)
                                        }
                                        .frame(height: totalContentHeight)
                                    }
                                    .onChange(of: videoPlayer.currentTime) { newTime in
                                        // Auto-scroll to keep current time in view
                                        let y = CGFloat(newTime) * timelineScale
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            scrollProxy.scrollTo(textEditor.textBoxes.firstIndex(where: { newTime >= $0.timeRange.lowerBound && newTime <= $0.timeRange.upperBound }) ?? 0, anchor: .center)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: geometry.size.height / 2 - 20)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height / 2)
                    .background(Color(.systemBackground))
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                }
            }
            .ignoresSafeArea()
            .zIndex(1000)
        }
    }
}

// Preference key for scroll view content height
struct ScrollViewContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 1
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SubtitleRowView: View {
    let index: Int
    let textBox: TextBox
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
                    .offset(x: -4) // Move left to hide left side rounding
                Text(textBox.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .clipped() // Clip the left side
        // No vertical padding or internal height constraints
    }
}

// Extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

