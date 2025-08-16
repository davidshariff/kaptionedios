import SwiftUI

struct CheckeredBackground: View {
    let squareSize: CGFloat = 20
    
    var body: some View {
        Canvas { context, size in
            let rows = Int(size.height / squareSize) + 1
            let cols = Int(size.width / squareSize) + 1
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * squareSize
                    let y = CGFloat(row) * squareSize
                    
                    // Create dark squares in a checkered pattern
                    if (row + col) % 2 == 0 {
                        let rect = CGRect(x: x, y: y, width: squareSize, height: squareSize)
                        context.fill(Path(rect), with: .color(.gray.opacity(0.2)))
                    }
                }
            }
        }
    }
}

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
    
    @Binding var showEditSubtitlesMode: Bool

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
                        CheckeredBackground()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        playerStandardView
                    }
                }
            }
            .allFrame()
        }
        .onReceive(videoPlayer.$currentTime) { _ in
            guard videoPlayer.isPlaying, let _ = editorVM.currentVideo else { return }
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
                        Color.white
                        ZStack {
                            // this is the video player
                            PlayerView(
                                player: videoPlayer.videoPlayer
                            )
                            ZStack {
                                
                                // this is the text overlay player
                                TextOnPlayerView(
                                    currentTime: videoPlayer.currentTime,
                                    originalVideoSize: video.frameSize,
                                    viewModel: textEditor,
                                    showEditSubtitlesMode: $showEditSubtitlesMode,
                                    pauseVideo: {
                                        videoPlayer.pause()
                                    }
                                )
                                .environment(\.videoSize, CGSize(
                                    width: proxy.size.width,
                                    height: proxy.size.height
                                ))

                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            textEditor.deselectTextBox()
                        }
                        .scaleEffect(1.0)
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
            }
        }
    }

}

struct PlayerControl: View{

    @ObservedObject var editorVM: EditorViewModel
    @ObservedObject var videoPlayer: VideoPlayerManager
    @ObservedObject var textEditor: TextEditorViewModel

    var body: some View{
        VStack(spacing: 0) {
            timeLineControlSection
            controlsSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 5)
    }
    
    @ViewBuilder
    private var timeLineControlSection: some View{
        if let video = editorVM.currentVideo{
            RulerView(
                value: $videoPlayer.currentTime,
                bounds: 0...video.originalDuration,
                disableOffset: false,
                duration: video.originalDuration,
                currentTime: videoPlayer.currentTime,
                showMinorTicks: false,
                showPlayhead: true,
                customPixelsPerSecond: 40,
                onChange: {
                    videoPlayer.scrubState = .scrubEnded(videoPlayer.currentTime)
                },
                timeLabelYOffset: 18,
                tickYOffset: -10
            )
            .frame(width: 300)
        }
    }
    
    private var controlsSection: some View{
        
        ZStack {
            // Background HStack for time and mute button
            HStack {
                // Time / Duration on the left
                if let video = editorVM.currentVideo {
                    Text("\(videoPlayer.currentTime.formatterTimeString()) / \(video.totalDuration.formatterTimeString())")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Mute/Unmute button on the right
                Button {
                    videoPlayer.toggleMute()
                } label: {
                    Image(systemName: videoPlayer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            // Play button centered on top
            Button {
                if let video = editorVM.currentVideo{
                    videoPlayer.action(video)
                }
            } label: {
                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: videoPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.black)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(height: 70)
    }
}



