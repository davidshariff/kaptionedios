import SwiftUI

struct RulerView: View {

    // Bindings
    @Binding var value: Double
    
    // State
    @State private var lastOffset: CGFloat = 0
    @State private var isChange: Bool = false
    @State private var offset: CGFloat = 0
    @State private var isExternalDrag: Bool = false
    @State private var externalDragStartOffset: CGFloat = 0
    
    // Zoom state
    @State private var zoomLevel: CGFloat = 1.0
    @State private var lastZoomLevel: CGFloat = 1.0
    @State private var isZooming: Bool = false
    
    // Configuration
    var bounds: ClosedRange<Double>
    var disableOffset: Bool
    var actualTimelineWidth: Binding<CGFloat>?
    var rulerStartInParentX: Binding<CGFloat>?
    var exposedOffset: Binding<CGFloat>?
    var externalDragOffset: Binding<CGFloat>?
    var externalZoomOffset: Binding<CGFloat>?
    
    // Constants
    let duration: Double
    let currentTime: Double
    let showMinorTicks: Bool
    let showPlayhead: Bool
    let showMajorTicks: Bool
    let showTimelabel: Bool
    let tickHeight: CGFloat
    let customPixelsPerSecond: CGFloat
    
    // Zoom constraints
    let minZoomLevel: CGFloat = 1.0
    let maxZoomLevel: CGFloat = 5.0
    
    // Actions
    let onChange: () -> Void
    
    // Set constants values on init
    init(
        value: Binding<Double>,
        bounds: ClosedRange<Double>,
        disableOffset: Bool = false,
        duration: Double, 
        currentTime: Double, 
        showMinorTicks: Bool = false,
        showPlayhead: Bool = false,
        showMajorTicks: Bool = true,
        showTimelabel: Bool = true,
        tickHeight: CGFloat = 20,
        customPixelsPerSecond: CGFloat = 0,
        actualTimelineWidth: Binding<CGFloat>? = nil,
        rulerStartInParentX: Binding<CGFloat>? = nil,
        exposedOffset: Binding<CGFloat>? = nil,
        externalDragOffset: Binding<CGFloat>? = nil,
        externalZoomOffset: Binding<CGFloat>? = nil,
        onChange: @escaping () -> Void = {}
    ) {
        self._value = value
        self.bounds = bounds
        self.disableOffset = disableOffset
        self.duration = duration
        self.currentTime = currentTime
        self.showMinorTicks = showMinorTicks
        self.showPlayhead = showPlayhead
        self.showMajorTicks = showMajorTicks
        self.showTimelabel = showTimelabel
        self.tickHeight = tickHeight
        self.customPixelsPerSecond = customPixelsPerSecond
        self.actualTimelineWidth = actualTimelineWidth
        self.rulerStartInParentX = rulerStartInParentX
        self.exposedOffset = exposedOffset
        self.externalDragOffset = externalDragOffset
        self.externalZoomOffset = externalZoomOffset
        self.onChange = onChange
    }
    
    private func createRulerTicks(pixelsPerSecond: CGFloat) -> some View {
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
                    
                    if showMinorTicks {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 12)
                    }
                }
                .frame(width: pixelsPerSecond, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .offset(x: offset)
    }
    
    private func createPlayhead(geometry: GeometryProxy) -> some View {
        Group {
            if showPlayhead {
                PlayheadView(height: geometry.size.height / 2)
                    .position(x: 0, y: (geometry.size.height / 2) / 2)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let basePixelsPerSecond = customPixelsPerSecond > 0 ? customPixelsPerSecond : (geometry.size.width / CGFloat(duration))
            let zoomedPixelsPerSecond = basePixelsPerSecond * zoomLevel
            let calculatedTimelineWidth = duration * zoomedPixelsPerSecond
            let rulerStartX = geometry.size.width / 2
            
            ZStack {
                createRulerTicks(pixelsPerSecond: zoomedPixelsPerSecond)
                createPlayhead(geometry: geometry)
            }
            // center the timeline in the parent view
            .offset(x: rulerStartX)
            .background(
                Rectangle()
                    .fill(Color.white.opacity(0.001))
            )
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                        isChange = true
                        let translation = gesture.translation.width
                        
                        // Scale the drag sensitivity based on zoom level
                        // Higher zoom = slower drag (more precise), Lower zoom = faster drag (less precise)
                        let zoomSensitivity = 1.0 / zoomLevel
                        let scaledTranslation = translation * zoomSensitivity
                        
                        let scaleFactor = calculatedTimelineWidth / geometry.size.width
                        let finalTranslation = scaledTranslation * scaleFactor
                        let newOffset = lastOffset + finalTranslation
                        offset = min(0, max(newOffset, -calculatedTimelineWidth))
                        
                        // Update the exposed offset binding if provided
                        if let exposedOffsetBinding = exposedOffset {
                            exposedOffsetBinding.wrappedValue = offset
                        }
                        
                        let range = bounds.upperBound - bounds.lowerBound
                        let normalizedOffset = offset / calculatedTimelineWidth
                        let newValue = range * normalizedOffset - bounds.lowerBound
                        value = abs(newValue)
                        onChange()
                    }
                    .onEnded { gesture in
                        isChange = false
                        lastOffset = offset
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        isZooming = true
                        let newZoomLevel = lastZoomLevel * scale
                        zoomLevel = min(maxZoomLevel, max(minZoomLevel, newZoomLevel))
                    }
                    .onEnded { scale in
                        isZooming = false
                        lastZoomLevel = zoomLevel
                        
                        // Adjust offset to keep the current time position centered
                        let oldTimelineWidth = duration * (basePixelsPerSecond * lastZoomLevel)
                        let newTimelineWidth = calculatedTimelineWidth
                        let scaleRatio = newTimelineWidth / oldTimelineWidth
                        
                        // Adjust offset to maintain relative position
                        offset = offset * scaleRatio
                        lastOffset = offset
                        
                        // Ensure offset stays within bounds
                        offset = min(0, max(offset, -calculatedTimelineWidth))
                        lastOffset = offset
                    }
            )
            .onChange(of: value) { _ in
                if !disableOffset {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if !isChange {
                            let progress = (value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
                            offset = -progress * calculatedTimelineWidth
                            
                            // Update the exposed offset binding if provided
                            if let exposedOffsetBinding = exposedOffset {
                                exposedOffsetBinding.wrappedValue = offset
                            }
                        }
                    }
                }
            }
            .onAppear {
                // Set initial offset based on current value
                let progress = (value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
                offset = -progress * calculatedTimelineWidth
                lastOffset = offset
                
                // Update the exposed offset binding if provided
                if let exposedOffsetBinding = exposedOffset {
                    exposedOffsetBinding.wrappedValue = offset
                }
                
                // Set the ruler start position when view appears
                if let rulerStartBinding = rulerStartInParentX {
                    let newValue = geometry.size.width / 2
                    rulerStartBinding.wrappedValue = newValue
                }
                
                // Check actualTimelineWidth binding
                if let actualTimelineWidthBinding = actualTimelineWidth {
                    let newTimelineWidth = calculatedTimelineWidth
                    actualTimelineWidthBinding.wrappedValue = newTimelineWidth
                }
            }
            .onChange(of: calculatedTimelineWidth) { _ in
                // Update the binding when calculatedTimelineWidth changes
                if let actualTimelineWidthBinding = actualTimelineWidth {
                    actualTimelineWidthBinding.wrappedValue = calculatedTimelineWidth
                }
            }
            .onChange(of: geometry.size.width) { _ in
                // Update the ruler start position when geometry changes
                if let rulerStartBinding = rulerStartInParentX {
                    let newValue = geometry.size.width / 2
                    rulerStartBinding.wrappedValue = newValue
                }
                
                // Also update actualTimelineWidth when geometry changes
                if let actualTimelineWidthBinding = actualTimelineWidth {
                    let newTimelineWidth = calculatedTimelineWidth
                    actualTimelineWidthBinding.wrappedValue = newTimelineWidth
                }
            }
            .onChange(of: externalDragOffset?.wrappedValue) { newExternalOffset in
                // Handle external drag offset from text boxes
                if let newOffset = newExternalOffset {
                    // If the external offset is 0 and we were in an external drag, update lastOffset and exit
                    if newOffset == 0 && isExternalDrag {
                        lastOffset = offset
                        isExternalDrag = false
                        return
                    }
                    
                    // If this is the start of an external drag, store the current offset
                    if !isExternalDrag && newOffset != 0 {
                        isExternalDrag = true
                        externalDragStartOffset = offset
                    }
                    
                    // Calculate the scale factor for the timeline
                    let scaleFactor = calculatedTimelineWidth / geometry.size.width
                    
                    // Scale the drag sensitivity based on zoom level
                    let zoomSensitivity = 1.0 / zoomLevel
                    let scaledTranslation = newOffset * zoomSensitivity * scaleFactor
                    
                    // Apply the external drag as a relative movement from the start position
                    let newRulerOffset = externalDragStartOffset + scaledTranslation
                    offset = min(0, max(newRulerOffset, -calculatedTimelineWidth))
                    
                    // Update the exposed offset binding
                    if let exposedOffsetBinding = exposedOffset {
                        exposedOffsetBinding.wrappedValue = offset
                    }
                    
                    // Update the value based on the new offset
                    let range = bounds.upperBound - bounds.lowerBound
                    let normalizedOffset = offset / calculatedTimelineWidth
                    let newValue = range * normalizedOffset - bounds.lowerBound
                    value = abs(newValue)
                    onChange()
                }
            }
            .onChange(of: externalZoomOffset?.wrappedValue) { newZoomOffset in
                // Handle external zoom offset from text boxes
                if let zoomSignal = newZoomOffset {
                    // Check if this is a zoom signal (should be positive now since we're using separate binding)
                    if zoomSignal > 0 {
                        // Extract the zoom level
                        let zoomLevel = zoomSignal / 1000.0 // Reverse the scaling from TimelineTextBox
                        let newZoomLevel = min(maxZoomLevel, max(minZoomLevel, zoomLevel))
                        
                        // Apply the zoom
                        self.zoomLevel = newZoomLevel
                        lastZoomLevel = newZoomLevel
                        
                        // Adjust offset to keep the current time position centered
                        let oldTimelineWidth = duration * (basePixelsPerSecond * lastZoomLevel)
                        let newTimelineWidth = calculatedTimelineWidth
                        let scaleRatio = newTimelineWidth / oldTimelineWidth
                        
                        // Adjust offset to maintain relative position
                        offset = offset * scaleRatio
                        lastOffset = offset
                        
                        // Ensure offset stays within bounds
                        offset = min(0, max(offset, -calculatedTimelineWidth))
                        lastOffset = offset
                    }
                }
            }
        }
        .border(.blue, width: 1)
    }
} 