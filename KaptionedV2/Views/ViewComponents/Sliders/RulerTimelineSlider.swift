//
//  RulerTimelineSlider.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 19.04.2023.
//

import SwiftUI

struct RulerTimelineSlider<T: View, A: View>: View {
    
    // Bindings
    @Binding var value: Double
    
    // State
    @State private var lastOffset: CGFloat = 0
    @State private var viewWidth: CGFloat = 0
    @State var isChange: Bool = false
    @State var offset: CGFloat = 0
    @State var gestureW: CGFloat = 0
    
    // Configuration
    var bounds: ClosedRange<Double>
    var disableOffset: Bool
    var timelineWidth: CGFloat = 0
    var actualTimelineWidth: Binding<CGFloat>?
    var rulerStartInParentX: Binding<CGFloat>?
    
    // Constants
    let actionWidth: CGFloat = 30
    
    // Views & Actions
    @ViewBuilder var frameView: () -> T
    @ViewBuilder var actionView: () -> A
    let onChange: () -> Void
    
    var body: some View {

        GeometryReader { proxy in

            let sliderViewYCenter = proxy.size.height / 2
            let sliderPositionX = proxy.size.width / 2 + timelineWidth / 2 + (disableOffset ? 0 : offset)
            
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
                    .frame(width: timelineWidth, height: proxy.size.height - 5)
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
                            timelineWidth: timelineWidth,
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
                            timelineWidth: timelineWidth
                        )
                    }
                }
            }
        }
    }
}

// setOffset method moved to TimelineSliderUtils 