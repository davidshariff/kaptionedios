//
//  WordTimelineSlider.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 19.04.2023.
//

import SwiftUI

struct WordTimelineSlider<T: View, A: View>: View {
    @State private var lastOffset: CGFloat = 0
    var bounds: ClosedRange<Double>
    var disableOffset: Bool
    @Binding var value: Double
    @State var isChange: Bool = false
    @State var offset: CGFloat = 0
    @State var gestureW: CGFloat = 0
    
    var timelineWidth: CGFloat = 65
    let frameWidth: CGFloat = 30
    let textBoxes: [TextBox]
    let duration: Double
    
    @ViewBuilder
    var frameView: () -> T
    @ViewBuilder
    var actionView: () -> A
    let onChange: () -> Void
    
    var body: some View {
        GeometryReader { proxy in
            let sliderViewYCenter = proxy.size.height / 2
            let sliderPositionX = proxy.size.width / 2 + timelineWidth / 2 + (disableOffset ? 0 : offset)
            ZStack{
                
                // Ruler background
                frameView()
                    .frame(width: timelineWidth, height: proxy.size.height - 5)
                    .position(x: sliderPositionX - frameWidth/2, y: sliderViewYCenter)
                    .border(.orange, width: 1)
                
                // Text box overlays
                ForEach(textBoxes, id: \.id) { textBox in
                    let textBoxStart = textBox.timeRange.lowerBound
                    let absoluteTextPosition = getAbsoluteWordPosition(start: textBoxStart, totalWidth: timelineWidth, duration: duration, sliderPositionX: sliderPositionX, frameWidth: frameWidth, textBoxText: textBox.text)
                    let isVisible = absoluteTextPosition >= -100 && absoluteTextPosition <= proxy.size.width + 100
                    
                    if isVisible {
                        Text(textBox.text)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.orange.opacity(0.8))
                            )
                            .position(x: absoluteTextPosition, y: sliderViewYCenter)
                            .opacity(0.9)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 120) // Limit width to prevent overflow
                    }
                }
                
                // Playhead indicator
                HStack(spacing: 0) {
                    Capsule()
                        .fill(Color.white)
                        // width of the vertical line
                        .frame(width: 2, height: proxy.size.height * 0.3)
                }
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 0)
                .opacity(disableOffset ? 0 : 1)
                .offset(x: -6, y: -proxy.size.height * 0.3)
                
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                        isChange = true
                        
                        let translationWidth = gesture.translation.width
                        let newOffset = lastOffset + translationWidth
                        
                        offset = min(0, max(newOffset, -timelineWidth))
                        
                        let newValue = (bounds.upperBound - bounds.lowerBound) * (offset / timelineWidth) - bounds.lowerBound
                        
                        value = abs(newValue)
                        
                        onChange()
                        
                    }
                    .onEnded { gesture in
                        isChange = false
                        lastOffset = offset
                    }
            )
            .onChange(of: value) { _ in
                if !disableOffset{
                    withAnimation(.easeInOut(duration: 0.15)) {
                        setOffset()
                    }
                }
            }
            .onAppear {
                // Set initial offset based on current value
                setOffset()
                lastOffset = offset
                
                print("🔤 WordTimelineSlider onAppear:")
                print("   - Bounds: \(bounds)")
                print("   - Current value: \(value)")
                print("   - Duration: \(duration)")
                print("   - Timeline width: \(timelineWidth)")
                print("   - Initial offset: \(offset)")
                print("   - Text boxes count: \(textBoxes.count)")
            }
        }
    }
}

extension WordTimelineSlider{
    
    private func setOffset(){
        if !isChange{
            offset = ((-value + bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * timelineWidth
        }
    }
    
    private func getWordPosition(word: KaraokeWord, totalWidth: CGFloat, duration: Double) -> CGFloat {
        let timeRatio = word.start / duration
        return timeRatio * totalWidth
    }
    
    private func getWordPosition(start: Double, totalWidth: CGFloat, duration: Double) -> CGFloat {
        let timeRatio = start / duration
        return timeRatio * totalWidth
    }
    

    
    private func getAbsoluteWordPosition(start: Double, totalWidth: CGFloat, duration: Double, sliderPositionX: CGFloat, frameWidth: CGFloat, textBoxText: String? = nil) -> CGFloat {
        // Use the same logic as RulerView: frameWidth / duration for positioning
        let pixelsPerSecond = totalWidth / duration
        let wordPosition = start * pixelsPerSecond
        
        // The ruler frame is positioned at sliderPositionX - frameWidth/2
        let rulerFramePosition = sliderPositionX - frameWidth/2
        // Position relative to the left edge of the green background
        // Calculate the spacing offset dynamically based on pixels per second
        let spacingOffset = 3.0 * (totalWidth / duration) // 3 seconds worth of pixels
        let centerOfFrameOffset = frameWidth/2
        let finalPosition = (rulerFramePosition - totalWidth/2 + wordPosition - spacingOffset) + centerOfFrameOffset
        
        print("🔤 Text box positioning:")
        print("   - Text box text: \(textBoxText ?? "nil")")
        print("   - Text start time: \(start)")
        print("   - Total width: \(totalWidth)")
        print("   - Duration: \(duration)")
        print("   - Pixels per second: \(pixelsPerSecond)")
        print("   - Word position: \(wordPosition)")
        print("   - Slider position X: \(sliderPositionX)")
        print("   - Action width: \(frameWidth)")
        print("   - Ruler frame position: \(rulerFramePosition)")
        print("   - Final position: \(finalPosition)")
        print("   - pixelsPerSecond: \(pixelsPerSecond)")
        print("   - spacingOffset: \(spacingOffset)")
        
        return finalPosition
    }
} 