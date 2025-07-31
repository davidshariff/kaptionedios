//
//  RulerTimelineSlider.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 19.04.2023.
//

import SwiftUI

struct RulerTimelineSlider<T: View, A: View>: View {
    @State private var lastOffset: CGFloat = 0
    @State private var viewWidth: CGFloat = 0
    var bounds: ClosedRange<Double>
    var disableOffset: Bool
    @Binding var value: Double
    @State var isChange: Bool = false
    @State var offset: CGFloat = 0
    @State var gestureW: CGFloat = 0
    var frameWidth: CGFloat = 65
    // width of the capsule container
    let actionWidth: CGFloat = 30
    @ViewBuilder
    var frameView: () -> T
    @ViewBuilder
    var actionView: () -> A
    let onChange: () -> Void
    
    var body: some View {

        GeometryReader { proxy in

            let sliderViewYCenter = proxy.size.height / 2
            let sliderPositionX = proxy.size.width / 2 + frameWidth / 2 + (disableOffset ? 0 : offset)
            
            // Store the view width for use in setOffset
            let _ = DispatchQueue.main.async {
                viewWidth = proxy.size.width
            }

            ZStack{

                // Background gesture area that covers the full width
                Rectangle()
                    .fill(Color.black.opacity(0.001)) // Nearly transparent but still captures gestures as SwiftUI does not capture gestures on transparent views
                    .frame(width: proxy.size.width, height: proxy.size.height)
                
                frameView()
                    .frame(width: frameWidth, height: proxy.size.height - 5)
                    .position(x: sliderPositionX - actionWidth/2, y: sliderViewYCenter)
                
                // Playhead indicator
                PlayheadView(height: proxy.size.height * 0.3)
                    .opacity(disableOffset ? 0 : 1)
                    .position(x: proxy.size.width / 2, y: (proxy.size.height * 0.3) / 2)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                        TimelineSliderUtils.handleDragChanged(
                            gesture: gesture,
                            isChange: $isChange,
                            lastOffset: $lastOffset,
                            offset: $offset,
                            timelineWidth: frameWidth,
                            bounds: bounds,
                            value: $value,
                            onChange: onChange
                        )
                    }
                    .onEnded { gesture in
                        print("🎯 RulerTimelineSlider gesture ended")
                        TimelineSliderUtils.handleDragEnded(
                            gesture: gesture,
                            isChange: $isChange,
                            lastOffset: $lastOffset,
                            offset: $offset
                        )
                    }
            )
            .onChange(of: value) { _ in
                if !disableOffset{
                    withAnimation(.easeInOut(duration: 0.15)) {
                        TimelineSliderUtils.setOffset(
                            value: value,
                            offset: $offset,
                            isChange: isChange,
                            bounds: bounds,
                            timelineWidth: frameWidth
                        )
                    }
                }
            }
        }
    }
}

// setOffset method moved to TimelineSliderUtils

struct RulerView: View {

    let duration: Double
    let currentTime: Double
    let frameWidth: CGFloat
    let showMinorTicks: Bool
    let showPlayhead: Bool
    let showMajorTicks: Bool
    let showTimelabel: Bool
    let tickHeight: CGFloat
    
    init(
        duration: Double, 
        currentTime: Double, 
        frameWidth: CGFloat, 
        showMinorTicks: Bool = false,
        showPlayhead: Bool = false,
        showMajorTicks: Bool = true,
        showTimelabel: Bool = true,
        tickHeight: CGFloat = 20
    ) {
        self.duration = duration
        self.currentTime = currentTime
        self.frameWidth = frameWidth
        self.showMinorTicks = showMinorTicks
        self.showPlayhead = showPlayhead
        self.showMajorTicks = showMajorTicks
        self.showTimelabel = showTimelabel
        self.tickHeight = tickHeight
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                // Ruler ticks - static time scale
                HStack(spacing: 0) {
                    ForEach(0..<Int(duration) + 1, id: \.self) { second in
                        VStack(spacing: 0) {

                            if showMajorTicks {
                            Rectangle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 1, height: showMinorTicks ? 12 : tickHeight)
                            }
                            
                            if showTimelabel {
                                Text("\(second)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                                    .frame(height: 12)
                                    .padding(.top, 4)
                            }
                            // Minor tick - fills bottom portion (optional)
                            if showMinorTicks {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 1, height: 12)
                            }
                        }
                        .frame(width: geometry.size.width / duration, alignment: .leading) // Use full available width
                        //.border(.red, width: 1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                //.border(.yellow, width: 1)
                .offset(x: 20)
                
                // Playhead indicator (optional)
                if showPlayhead {
                    PlayheadView(height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
                // // Pixel count markers (every 50 pixels)
                // HStack(spacing: 0) {
                //     ForEach(0..<Int(frameWidth / 50) + 1, id: \.self) { pixelIndex in
                //         let pixelPosition = pixelIndex * 50
                //         VStack(spacing: 0) {
                //             Text("\(pixelPosition)")
                //                 .font(.system(size: 8))
                //                 .foregroundColor(.red)
                //                 .frame(height: 0)
                //         }
                //         .frame(width: 50, alignment: .leading)
                //     }
                // }
                // .frame(maxWidth: .infinity, alignment: .leading)
                // .offset(x: 20)
                // .offset(y: 20) // Move down to avoid overlapping with time labels
            }
        }
    }
} 