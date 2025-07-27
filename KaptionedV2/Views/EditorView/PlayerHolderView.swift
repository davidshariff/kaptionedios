//
//  PlayerHolderView.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 18.04.2023.
//

import SwiftUI

// Custom environment key for video size
private struct VideoSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
    var videoSize: CGSize {
        get { self[VideoSizeKey.self] }
        set { self[VideoSizeKey.self] = newValue }
    }
}

struct PlayerHolderView: View{

    @Binding var availableHeight: CGFloat

    @ObservedObject var editorVM: EditorViewModel
    @ObservedObject var videoPlayer: VideoPlayerManager
    @ObservedObject var textEditor: TextEditorViewModel

    var body: some View{
        VStack(spacing: 6) {
            ZStack(alignment: .bottom){
                switch videoPlayer.loadState{
                case .loading:
                    ProgressView()
                case .unknown:
                    Text("Add new video")
                case .failed:
                    Text("Failed to open video")
                case .loaded:
                    ZStack(alignment: .top) {
                        playerStandardView
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .border(Color.red, width: 2)
                    }
                }
            }
            .allFrame()
        }
        .onReceive(videoPlayer.$currentTime) { _ in
            guard videoPlayer.isPlaying, let video = editorVM.currentVideo else { return }
            debugPlayerInfo(video: video)
        }
    }
    
    private func debugPlayerInfo(video: Video) {
        
        // Debug text boxes currently on screen
        let currentTextBoxes = textEditor.textBoxes.filter { textBox in
            textBox.timeRange.contains(videoPlayer.currentTime)
        }
        
        print("[DEBUG] TextBoxes on screen: \(currentTextBoxes.count)")
        for (index, textBox) in currentTextBoxes.enumerated() {
            print("  [DEBUG] TextBox \(index + 1):")
            print("    - Text: '\(textBox.text)'")
            print("    - Font Size: \(textBox.fontSize)")
            print("    - Position: \(textBox.offset)")
            print("    - Time Range: \(textBox.timeRange.lowerBound) - \(textBox.timeRange.upperBound)")
            print("    - Is Selected: \(textEditor.isSelected(textBox.id))")
        }
    }
}

struct PlayerHolderView_Previews: PreviewProvider {
    static var previews: some View {
        MainEditorView()
            .preferredColorScheme(.dark)
    }
}

extension PlayerHolderView{

    private var playerStandardView: some View {
        Group {
            if let video = editorVM.currentVideo {
                GeometryReader { proxy in
                    ZStack {
                        editorVM.frames.frameColor
                        ZStack {
                            // this is the video player
                            PlayerView(player: videoPlayer.videoPlayer)
                            // this is the text overlay player
                            ZStack {
                                TextPlayerView(
                                    currentTime: videoPlayer.currentTime,
                                    viewModel: textEditor,
                                    originalVideoSize: video.frameSize
                                )
                                .environment(\.videoSize, CGSize(
                                    width: proxy.size.width,
                                    height: proxy.size.height
                                ))
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .border(Color.orange, width: 2)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            textEditor.deselectTextBox()
                        }
                        .scaleEffect(editorVM.frames.scale)
                    }
                    .frame(
                        width: min(proxy.size.width, proxy.size.height * (video.frameSize.width / video.frameSize.height)),
                        height: min(proxy.size.height, proxy.size.width * (video.frameSize.height / video.frameSize.width))
                    )
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .onAppear {
                        Task {
                            guard let size = await video.asset.adjustVideoSize(to: proxy.size) else { return }
                            editorVM.currentVideo?.frameSize = size
                            editorVM.currentVideo?.geometrySize = proxy.size
                        }
                    }
                }
                timelineLabel
            }
        }
    }

}

extension PlayerHolderView{
    
    @ViewBuilder
    private var timelineLabel: some View{
        if let video = editorVM.currentVideo{
            HStack{
                Text((videoPlayer.currentTime - video.rangeDuration.lowerBound)  .formatterTimeString()) +
                Text(" / ") +
                Text(video.totalDuration.formatterTimeString())
            }
            .font(.caption2)
            .foregroundColor(.white)
            .frame(width: 80)
            .padding(5)
            .background(Color(.black).opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
            .padding()
        }
    }
}


struct PlayerControl: View{
    @ObservedObject var recorderManager: AudioRecorderManager
    @ObservedObject var editorVM: EditorViewModel
    @ObservedObject var videoPlayer: VideoPlayerManager
    @ObservedObject var textEditor: TextEditorViewModel
    var body: some View{
        VStack(spacing: 6) {
            playSection
            timeLineControlSection
        }
    }
    
    
    @ViewBuilder
    private var timeLineControlSection: some View{
        if let video = editorVM.currentVideo{
            TimeLineView(
                recorderManager: recorderManager,
                currentTime: $videoPlayer.currentTime,
                isSelectedTrack: $editorVM.isSelectVideo,
                viewState: editorVM.selectedTools?.timeState ?? .empty,
                video: video, textInterval: textEditor.selectedTextBox?.timeRange) {
                    videoPlayer.scrubState = .scrubEnded(videoPlayer.currentTime)
                } onChangeTextTime: { textTime in
                    textEditor.setTime(textTime)
                } onSetAudio: { audio in
                    editorVM.setAudio(audio)
                    videoPlayer.setAudio(audio.url)
                }
        }
    }
    
    private var playSection: some View{
        Button {
            if let video = editorVM.currentVideo{
                videoPlayer.action(video)
            }
        } label: {
            Image(systemName: videoPlayer.isPlaying ? "pause.fill" : "play.fill")
                .imageScale(.large)
                .font(.title2)
        }
        .buttonStyle(.plain)
        .hCenter()
        .frame(height: 50)
        .padding(.horizontal)
    }
}
