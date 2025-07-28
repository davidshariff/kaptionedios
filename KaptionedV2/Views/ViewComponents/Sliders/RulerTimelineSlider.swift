//
//  RulerTimelineSlider.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 19.04.2023.
//

import SwiftUI

struct RulerTimelineSlider<T: View, A: View>: View {
    @State private var lastOffset: CGFloat = 0
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

            ZStack{
                frameView()
                    .frame(width: frameWidth, height: proxy.size.height - 5)
                    .position(x: sliderPositionX - actionWidth/2, y: sliderViewYCenter)
                // HStack(spacing: 0) {
                //     Capsule()
                //         .fill(Color.white)
                //         // width of the vertical line
                //         .frame(width: 4, height: proxy.size.height)
                // }
                // .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 0)
                // .opacity(disableOffset ? 0 : 1)
            }
            .frame(width: proxy.size.width, height: proxy.size.height) // fills the whole width of the parent view
            
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                        isChange = true
                        
                        let translationWidth = gesture.translation.width
                        let newOffset = lastOffset + translationWidth
                        
                        offset = min(0, max(newOffset, -frameWidth))
                        
                        let newValue = (bounds.upperBound - bounds.lowerBound) * (offset / frameWidth) - bounds.lowerBound
                        
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
        }
    }
}

extension RulerTimelineSlider{
    
    private func setOffset(){
        if !isChange{
            offset = ((-value + bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * frameWidth
        }
    }
}

struct RulerView: View {
    let duration: Double
    let currentTime: Double
    let frameWidth: CGFloat
    let showMinorTicks: Bool
    
    init(duration: Double, currentTime: Double, frameWidth: CGFloat, showMinorTicks: Bool = false) {
        self.duration = duration
        self.currentTime = currentTime
        self.frameWidth = frameWidth
        self.showMinorTicks = showMinorTicks
        print("📏 RulerView - frameWidth: \(frameWidth)")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                // Ruler ticks - static time scale
                HStack(spacing: 0) {
                    ForEach(0..<Int(duration) + 1, id: \.self) { second in
                        VStack(spacing: 0) {



                            // // Major tick (every second)
                            // Rectangle()
                            //     .fill(Color.gray.opacity(0.6))
                            //     .frame(width: 1, height: showMinorTicks ? 12 : 20)
                            //     .padding(.top, 4)
                            
                            // Time label (every 5 seconds)
                            //if second % 5 == 0 {

                                Rectangle()
                                    .fill(Color.gray.opacity(0.6))
                                    .frame(width: 1, height: showMinorTicks ? 12 : 20)
                                    .padding(.top, 4)
                            
                                Text("\(second)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                                    .frame(height: 12)
                                    .padding(.top, 4)
                                    
                            // } else {
                            //     // Rectangle()
                            //     //     .fill(Color.clear)
                            //     //     .frame(height: 12)
                            // }
                            
                            // Minor tick - fills bottom portion (optional)
                            if showMinorTicks {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 1, height: 12)
                                    .padding(.bottom, 4)
                            }
                        }
                        .frame(width: geometry.size.width / duration, alignment: .leading) // Use full available width
                        //.border(.red, width: 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                //.border(.yellow, width: 1)
                .offset(x: 20)
                
                // // Pixel count markers (every 50 pixels)
                // HStack(spacing: 0) {
                //     ForEach(0..<Int(frameWidth / 50) + 1, id: \.self) { pixelIndex in
                //         let pixelPosition = pixelIndex * 50
                //         VStack(spacing: 0) {
                //             Text("\(pixelPosition)")
                //                 .font(.system(size: 8))
                //                 .foregroundColor(.red)
                //                 .frame(height: 12)
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