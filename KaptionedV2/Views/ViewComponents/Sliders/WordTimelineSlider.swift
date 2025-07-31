//
//  WordTimelineSlider.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 19.04.2023.
//

import SwiftUI

struct TimelineTextBox: View {
    let textBox: TextBox
    let timelineWidth: CGFloat
    let duration: Double
    let offset: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let textBoxStart = textBox.timeRange.lowerBound
            let textBoxEnd = textBox.timeRange.upperBound
            let pixelsPerSecond = timelineWidth / duration
            let boxDuration = textBoxEnd - textBoxStart
            let boxWidth = boxDuration * pixelsPerSecond
            let wordPosition = textBoxStart * pixelsPerSecond
            
            // wordPosition is the position of the word within the timeline
            // offset is to move it as the slider moves
            // boxWidth/2 is to shift it left of center
            let absoluteTextPosition = (wordPosition - abs(offset)) + boxWidth/2

            // TODO: fix this, especially if a lot of text boxes are present and performance is an issue
            // let isVisible = wordPosition > 0
            let isVisible = true
            
            if isVisible {
                Text(textBox.text)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(width: boxWidth, height: 50, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.7))
                            
                    )
                    .border(isSelected ? .white : .clear, width: 1)
                    .position(x: absoluteTextPosition, y: geometry.size.height / 2)
                    .opacity(0.9)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .onTapGesture {
                        onTap()
                        print("📝 TimelineTextBox tapped - Text: '\(textBox.text)', Time Range: \(textBox.timeRange.lowerBound)...\(textBox.timeRange.upperBound)")
                    }
            }
        }
    }
}

//  Main Word Timeline Slider
struct WordTimelineSlider<T: View, A: View>: View {
    @State private var lastOffset: CGFloat = 0
    @State private var selectedTextBoxId: UUID?
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
    @Binding var selectedTextBox: TextBox? // New binding for selected text box
    
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

                // Background gesture area that covers the full width
                Rectangle()
                    .fill(Color.black.opacity(0.001)) // Nearly transparent but still captures gestures as SwiftUI does not capture gestures on transparent views
                    .frame(width: proxy.size.width, height: proxy.size.height)
                
                ZStack(alignment: .leading) {
                    // Ruler view (frameView) - this displays the ticks
                    frameView()
                        .frame(width: timelineWidth, height: proxy.size.height)
                        .position(x: sliderPositionX - frameWidth/2, y: sliderViewYCenter)
                    
                    // Playhead indicator
                    PlayheadView(height: proxy.size.height * 0.3)
                        .opacity(disableOffset ? 0 : 1)
                        .position(x: (proxy.size.width / 2), y: (proxy.size.height * 0.3) / 2)
                }
                
                // Text box overlays with absolute positioning
                ForEach(textBoxes, id: \.id) { textBox in
                    TimelineTextBox(
                        textBox: textBox,
                        timelineWidth: timelineWidth,
                        duration: duration,
                        offset: offset,
                        isSelected: selectedTextBoxId == textBox.id,
                        onTap: {
                            selectedTextBoxId = textBox.id
                            selectedTextBox = textBox // Set the selected text box
                        }
                    )
                }
                // Half-width container view, needed to place the text boxes from the middle of the screen
                .frame(width: proxy.size.width / 2)
                // move it to the middle of the screen
                .offset(x: proxy.size.width / 2, y: 0)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .border(Color.red, width: 1)
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                        print("📝 WordTimelineSlider gesture triggered")
                        isChange = true
                        
                        let translationWidth = gesture.translation.width
                        let newOffset = lastOffset + translationWidth
                        
                        offset = min(0, max(newOffset, -timelineWidth))
                        
                        let newValue = (bounds.upperBound - bounds.lowerBound) * (offset / timelineWidth) - bounds.lowerBound
                        
                        print("📝 Translation: \(translationWidth), Offset: \(offset), NewValue: \(newValue)")
                        
                        value = abs(newValue)
                        
                        onChange()
                        
                    }
                    .onEnded { gesture in
                        print("📝 WordTimelineSlider gesture ended")
                        isChange = false
                        lastOffset = offset
                    }
            )
            .onChange(of: value) { newValue in
                print("📝 WordTimelineSlider value changed to: \(newValue)")
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
            let progress = (value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
            offset = -progress * timelineWidth
            print("📝 WordTimelineSlider setOffset - value: \(value), progress: \(progress), offset: \(offset)")
        }
    }
    
} 