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

            // Timeline container, contains the playhead and the text boxes
            // everything is aligned to the left
            ZStack(alignment: .leading) {
                
                ZStack(alignment: .leading) {
                    // Playhead indicator
                    Capsule()
                        .fill(Color.white)
                        // width of the vertical line
                        .frame(width: 2, height: proxy.size.height * 0.3)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 0)
                        .opacity(disableOffset ? 0 : 1)
                        .position(x: (proxy.size.width / 2) - 2, y: (proxy.size.height * 0.3) / 2)
                }
                
                // Text box overlays with absolute positioning
                ForEach(textBoxes, id: \.id) { textBox in

                    let textBoxStart = textBox.timeRange.lowerBound
                    let textBoxEnd = textBox.timeRange.upperBound
                    let pixelsPerSecond = timelineWidth / duration
                    let boxDuration = textBoxEnd - textBoxStart
                    let boxWidth = boxDuration * pixelsPerSecond
                    let absoluteTextPosition = getAbsoluteWordPosition(start: textBoxStart, end: textBoxEnd, timelineWidth: timelineWidth, duration: duration, sliderPositionX: sliderPositionX, frameWidth: frameWidth, textBoxText: textBox.text, boxWidth: boxWidth)
                    let isVisible = absoluteTextPosition >= -100 && absoluteTextPosition <= proxy.size.width + 100
                    
                    if isVisible {
                        Text(textBox.text)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(width: boxWidth, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(Color.orange.opacity(0.8))
                            )
                            .border(.red, width: 1)
                            .position(x: absoluteTextPosition, y: 20)
                            .opacity(0.9)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                // Half-width container view
                .frame(width: proxy.size.width / 2)
                .background(Color.green.opacity(0.1))
                // move it to the middle of the screen
                .offset(x: proxy.size.width / 2, y: 0)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .border(Color.red, width: 1)
            
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
                print("📏 WordTimelineSlider - frameWidth: \(frameWidth), timelineWidth: \(timelineWidth)")
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
    

    
    private func getAbsoluteWordPosition(start: Double, end: Double, timelineWidth: CGFloat, duration: Double, sliderPositionX: CGFloat, frameWidth: CGFloat, textBoxText: String? = nil, boxWidth: CGFloat) -> CGFloat {

        // The timeline is positioned at sliderPositionX, which is 475.0
        // The timeline content starts at sliderPositionX - timelineWidth/2
        let timelineStartPosition = sliderPositionX - timelineWidth/2
        
        // The ruler content inside the frame view has an offset of 20 pixels
        let rulerOffset: CGFloat = 20
        
        // The actual timeline content starts at the timeline start position plus the ruler offset
        let actualTimelineStart = timelineStartPosition + rulerOffset
        
        // Calculate pixels per second based on the actual ruler width
        let pixelsPerSecond = timelineWidth / duration
        
        // Calculate the word position within the timeline (from the start of the timeline)
        let wordPosition = start * pixelsPerSecond
        
        // Calculate the absolute position by adding the word position to the actual timeline start
        let textBoxStartPosition = actualTimelineStart + wordPosition
        let finalPosition = textBoxStartPosition + boxWidth/2
        
        // Debug info (can be removed in production)
        print("🔤 Text box: \(textBoxText ?? "nil") at \(start)s")
        print("   - Timeline start position: \(timelineStartPosition)")
        print("   - Ruler offset: \(rulerOffset)")
        print("   - Offset: \( abs(offset))")
        print("   - Actual timeline start: \(actualTimelineStart)")
        print("   - Word position within timeline: \(wordPosition)")
        print("   - Text box start position: \(textBoxStartPosition)")
        print("   - Box width: \(boxWidth)")
        print("   - Final center position: \(finalPosition)")
        print("   - Slider position X: \(sliderPositionX)")
        print("   - Timeline width: \(timelineWidth)")
        print("   - Frame width: \(frameWidth)")
        print("   - Pixels per second: \(pixelsPerSecond)")

        // wordPosition is the position of the word within the timeline
        // offset is to move it as the slider moves
        // boxWidth/2 is to shift it left of center
        return (wordPosition - abs(offset)) + boxWidth/2
    }
} 