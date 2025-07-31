//
//  TimelineSliderUtils.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 19.04.2023.
//

import SwiftUI

// Shared utility functions for timeline slider drag gesture logic
struct TimelineSliderUtils {
    
    static func handleDragChanged(
        gesture: DragGesture.Value,
        isChange: Binding<Bool>,
        lastOffset: Binding<CGFloat>,
        offset: Binding<CGFloat>,
        timelineWidth: CGFloat,
        bounds: ClosedRange<Double>,
        value: Binding<Double>,
        onChange: @escaping () -> Void
    ) {
        isChange.wrappedValue = true
        
        let translation = gesture.translation.width
        let newOffset = lastOffset.wrappedValue + translation
        offset.wrappedValue = min(0, max(newOffset, -timelineWidth))
        
        let range = bounds.upperBound - bounds.lowerBound
        let normalizedOffset = offset.wrappedValue / timelineWidth
        let newValue = range * normalizedOffset - bounds.lowerBound
        
        value.wrappedValue = abs(newValue)
        onChange()
    }
    
    static func handleDragEnded(
        gesture: DragGesture.Value,
        isChange: Binding<Bool>,
        lastOffset: Binding<CGFloat>,
        offset: Binding<CGFloat>
    ) {
        isChange.wrappedValue = false
        lastOffset.wrappedValue = offset.wrappedValue
    }
    
    static func setOffset(
        value: Double,
        offset: Binding<CGFloat>,
        isChange: Bool,
        bounds: ClosedRange<Double>,
        timelineWidth: CGFloat
    ) {
        if !isChange {
            let progress = (value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
            offset.wrappedValue = -progress * timelineWidth
        }
    }
} 