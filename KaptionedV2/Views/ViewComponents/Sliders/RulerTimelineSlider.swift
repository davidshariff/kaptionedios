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
    var frameWight: CGFloat = 65
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
            let sliderPositionX = proxy.size.width / 2 + frameWight / 2 + (disableOffset ? 0 : offset)
            ZStack{
                frameView()
                    .frame(width: frameWight, height: proxy.size.height - 5)
                    .position(x: sliderPositionX - actionWidth/2, y: sliderViewYCenter)
                HStack(spacing: 0) {
                    Capsule()
                        .fill(Color.white)
                        // width of the vertical line
                        .frame(width: 4, height: proxy.size.height)
                }
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 0)
                .opacity(disableOffset ? 0 : 1)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.6), lineWidth: 2)
            )
            
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                        isChange = true
                        
                        let translationWidth = gesture.translation.width
                        let newOffset = lastOffset + translationWidth
                        
                        offset = min(0, max(newOffset, -frameWight))
                        
                        let newValue = (bounds.upperBound - bounds.lowerBound) * (offset / frameWight) - bounds.lowerBound
                        
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
                    setOffset()
                }
            }
        }
    }
}

struct RulerTimelineSlider_Previews: PreviewProvider {
    @State static var currentTime = 0.0
    static var previews: some View {
        RulerTimelineSlider(bounds: 0...60, disableOffset: false, value: $currentTime, frameView: {
            RulerView(duration: 60, currentTime: currentTime)
        }, actionView: {EmptyView()}, onChange: {})
            .frame(height: 80)
    }
}

extension RulerTimelineSlider{
    
    private func setOffset(){
        if !isChange{
            offset = ((-value + bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * frameWight
        }
    }
}

struct RulerView: View {
    let duration: Double
    let currentTime: Double
    
    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(Color.gray.opacity(0.1))
            
            // Ruler ticks - static time scale
            HStack(spacing: 0) {
                ForEach(0..<Int(duration) + 1, id: \.self) { second in
                    VStack(spacing: 0) {
                        // Major tick (every second)
                        Rectangle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 1, height: 20)
                        
                        // Time label (every 5 seconds)
                        if second % 5 == 0 {
                            Text("\(second)")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                                .frame(height: 12)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 12)
                        }
                        
                        // Minor tick
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 8)
                    }
                    .frame(width: 1000 / duration) // Dynamic width based on video duration
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.blue.opacity(0.7), lineWidth: 2)
        )
    }
} 