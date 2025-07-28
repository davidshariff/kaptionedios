//
//  NewTimelineSlider.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 19.04.2023.
//

import SwiftUI

struct TimelineSlider<T: View, A: View>: View {
    @State private var lastOffset: CGFloat = 0
    var bounds: ClosedRange<Double>
    var disableOffset: Bool
    @Binding var value: Double
    @State var isChange: Bool = false
    @State var offset: CGFloat = 0
    @State var gestureW: CGFloat = 0
    var frameWidth: CGFloat = 65
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
                HStack(spacing: 0) {
                    PlayheadView(height: proxy.size.height, width: 4)
                    actionView()
                        .frame(width: actionWidth)
                }
                .opacity(disableOffset ? 0 : 1)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 2)
            )
            
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

struct NewTimelineSlider_Previews: PreviewProvider {
    @State static var curretTime = 0.0
    static var previews: some View {
        TimelineSlider(bounds: 5...34, disableOffset: false, value: $curretTime, frameView: {
            Rectangle()
                .fill(Color.secondary)
        }, actionView: {EmptyView()}, onChange: {})
            .frame(height: 80)
    }
}

extension TimelineSlider{
    
    private func setOffset(){
        if !isChange{
            offset = ((-value + bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * frameWidth
        }
    }
}
