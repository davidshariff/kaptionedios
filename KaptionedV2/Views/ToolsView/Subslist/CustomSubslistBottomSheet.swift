import SwiftUI

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
                                            ZStack {
                                                Rectangle()
                                                    .fill(Color.red)
                                                    .frame(width: geometry.size.width - 40, height: 2)
                                                    .shadow(color: Color.red.opacity(0.8), radius: 2)
                                                
                                                // Current time text
                                                Text(videoPlayer.currentTime.formatterTimeString())
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.red)
                                                    .cornerRadius(4)
                                                    .offset(y: -12)
                                            }
                                            .position(x: (geometry.size.width - 40) / 2 + 20, y: CGFloat(videoPlayer.currentTime) * timelineScale)
                                            .zIndex(1000)
                                        }
                                        .frame(height: totalContentHeight)
                                    }
                                    .onChange(of: videoPlayer.currentTime) { newTime in
                                        // Auto-scroll to keep current time in view
                                        let y = CGFloat(newTime) * timelineScale
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            scrollProxy.scrollTo(y, anchor: .center)
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