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
                            // this is the video player with grid
                            PlayerViewWithGrid(
                                player: videoPlayer.videoPlayer,
                                showGrid: true,
                                originalVideoSize: video.frameSize
                            )
                            ZStack {
                                // this is the text overlay player
                                TextPlayerView(
                                    currentTime: videoPlayer.currentTime,
                                    viewModel: textEditor,
                                    originalVideoSize: video.frameSize
                                )
                                .environment(\.videoSize, CGSize(
                                    width: proxy.size.width,
                                    height: proxy.size.height
                                ))
                                
                                // Rectangle()
                                //     .foregroundColor(.clear)
                                //     .border(Color.orange, width: 2)
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
            }
        }
    }

}


struct PlayerControl: View{

    @ObservedObject var recorderManager: AudioRecorderManager
    @ObservedObject var editorVM: EditorViewModel
    @ObservedObject var videoPlayer: VideoPlayerManager
    @ObservedObject var textEditor: TextEditorViewModel

    var body: some View{
        VStack(spacing: 0) {
            timeLineControlSection
            controlsSection
        }
        .border(Color.red.opacity(0.3), width: 1)
        .padding(.horizontal, 20)
        .padding(.top, 5)
    }
    
    @ViewBuilder
    private var timeLineControlSection: some View{
        if let video = editorVM.currentVideo{
            RulerTimelineSlider(
                bounds: video.rangeDuration,
                disableOffset: false,
                value: $videoPlayer.currentTime,
                frameWidth: 300
            ) {
                RulerView(duration: video.originalDuration, currentTime: videoPlayer.currentTime, frameWidth: 300, showPlayhead: false)
                    .frame(maxHeight: .infinity)
            } actionView: {
                recordButton
            }
            onChange: {
                videoPlayer.scrubState = .scrubEnded(videoPlayer.currentTime)
            }
            .frame(height: 60)
        }
    }
    
    private var recordButton: some View{
        Rectangle()
            .opacity(0)
    }
    
    private var controlsSection: some View{
        
        HStack(spacing: 0) {
            // Current time on the left
            if let video = editorVM.currentVideo {
                Text((videoPlayer.currentTime - video.rangeDuration.lowerBound).formatterTimeString())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Play button in the center
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
            
            // Total duration on the right
            if let video = editorVM.currentVideo {
                Text(video.totalDuration.formatterTimeString())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(height: 70)
    }
}
