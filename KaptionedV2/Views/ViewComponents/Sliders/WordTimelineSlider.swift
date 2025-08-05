import SwiftUI

// Z-Index enum for consistent layering
enum TimelineZIndex {
    static let nonSelectedTextBox: Double = 1
    static let selectedTextBox: Double = 25
    static let dragHandles: Double = 50
    static let tooltip: Double = 75
    static let selectedTextBoxContainer: Double = 100
}

//  Main Word Timeline Slider
struct WordTimelineSlider<T: View, A: View>: View {

    // Bindings
    @Binding var value: Double
    @Binding var selectedTextBox: TextBox?

    // State
    @State private var selectedTextBoxId: UUID?

    // Configuration
    var bounds: ClosedRange<Double>
    var disableOffset: Bool
    var offset: Binding<CGFloat>
    var actualTimelineWidth: Binding<CGFloat>?
    var rulerStartInParentX: Binding<CGFloat>?
    var externalDragOffset: Binding<CGFloat>?
    var externalZoomOffset: Binding<CGFloat>?

    // Constants
    let textBoxes: [TextBox]
    let duration: Double

    // Views & Actions
    @ViewBuilder var backgroundView: () -> T
    @ViewBuilder var actionView: () -> A
    let onChange: () -> Void
    let onSeek: (Double) -> Void
    let onTextBoxUpdate: ((TextBox) -> Void)?
    
    // Initializer
    init(
        value: Binding<Double>,
        selectedTextBox: Binding<TextBox?>,
        bounds: ClosedRange<Double>,
        disableOffset: Bool,
        textBoxes: [TextBox],
        duration: Double,
        offset: Binding<CGFloat>,
        actualTimelineWidth: Binding<CGFloat>? = nil,
        rulerStartInParentX: Binding<CGFloat>? = nil,
        externalDragOffset: Binding<CGFloat>? = nil,
        externalZoomOffset: Binding<CGFloat>? = nil,
        @ViewBuilder backgroundView: @escaping () -> T,
        @ViewBuilder actionView: @escaping () -> A,
        onChange: @escaping () -> Void,
        onSeek: @escaping (Double) -> Void,
        onTextBoxUpdate: ((TextBox) -> Void)? = nil
    ) {
        self._value = value
        self._selectedTextBox = selectedTextBox
        self.bounds = bounds
        self.disableOffset = disableOffset
        self.textBoxes = textBoxes
        self.duration = duration
        self.offset = offset
        self.actualTimelineWidth = actualTimelineWidth
        self.rulerStartInParentX = rulerStartInParentX
        self.externalDragOffset = externalDragOffset
        self.externalZoomOffset = externalZoomOffset
        self.backgroundView = backgroundView
        self.actionView = actionView
        self.onChange = onChange
        self.onSeek = onSeek
        self.onTextBoxUpdate = onTextBoxUpdate
    }
    
    private func createTextBoxView(_ textBox: TextBox) -> TimelineTextBox {
        let timelineWidth = actualTimelineWidth?.wrappedValue ?? 0
        return TimelineTextBox(
            textBox: textBox,
            timelineWidth: timelineWidth,
            duration: duration,
            offset: offset,
            externalDragOffset: externalDragOffset,
            externalZoomOffset: externalZoomOffset,
            isSelected: selectedTextBox?.id == textBox.id,
            onTap: {
                selectedTextBox = textBox
            },
            onSeek: onSeek,
            bounds: bounds,
            isChange: false,
            onTextBoxUpdate: onTextBoxUpdate
        )
    }
    
    private var textBoxViews: some View {
        ForEach(textBoxes, id: \.id) { (textBox: TextBox) in
            createTextBoxView(textBox)
                .zIndex(selectedTextBox?.id == textBox.id ? TimelineZIndex.selectedTextBoxContainer : TimelineZIndex.nonSelectedTextBox)
        }
    }
    
    var body: some View {
        ZStack {

            backgroundView()
                .onTapGesture {
                    // Deselect when tapping the background
                    if selectedTextBox != nil {
                        selectedTextBox = nil
                        print("🔄 Text box deselected - background tap")
                    }
                }

            textBoxViews
            .offset(x: rulerStartInParentX?.wrappedValue ?? 0)
            .allowsHitTesting(true)

        }
        .onAppear {
            let rulerStartValue = rulerStartInParentX?.wrappedValue ?? 0
            print("📏 WordTimelineSlider - rulerStartInParentX: \(rulerStartValue)")
            print("📏 WordTimelineSlider - textBoxes count: \(textBoxes.count)")
        }
        .onChange(of: rulerStartInParentX?.wrappedValue) { newValue in
            let rulerStartValue = newValue ?? 0
            print("📏 WordTimelineSlider - rulerStartInParentX changed to: \(rulerStartValue)")
        }
    }
    
}

struct TimelineTextBox: View {
    @State var textBox: TextBox
    let timelineWidth: CGFloat
    let duration: Double
    let offset: Binding<CGFloat>
    let externalDragOffset: Binding<CGFloat>?
    let externalZoomOffset: Binding<CGFloat>?
    let isSelected: Bool
    let onTap: () -> Void
    let onSeek: (Double) -> Void
    let bounds: ClosedRange<Double>
    let isChange: Bool
    let onTextBoxUpdate: ((TextBox) -> Void)?
    
    // Zoom state for pinch gesture
    @State private var zoomLevel: CGFloat = 1.0
    @State private var lastZoomLevel: CGFloat = 1.0
    @State private var isZooming: Bool = false
    @State private var isDragging: Bool = false
    @State private var gestureStartTime: Date = Date()
    
    // Edge dragging state
    @State private var isDraggingLeftEdge: Bool = false
    @State private var isDraggingRightEdge: Bool = false
    @State private var isDraggingTextBox: Bool = false
    @State private var dragStartTime: Double = 0
    @State private var originalTimeRange: ClosedRange<Double> = 0...0
    @State private var currentDragTime: Double = 0
    @State private var showTimeTooltip: Bool = false
    
    // Zoom constraints
    let minZoomLevel: CGFloat = 1.0
    let maxZoomLevel: CGFloat = 5.0
    
    // Initializer
    init(
        textBox: TextBox,
        timelineWidth: CGFloat,
        duration: Double,
        offset: Binding<CGFloat>,
        externalDragOffset: Binding<CGFloat>?,
        externalZoomOffset: Binding<CGFloat>?,
        isSelected: Bool,
        onTap: @escaping () -> Void,
        onSeek: @escaping (Double) -> Void,
        bounds: ClosedRange<Double>,
        isChange: Bool,
        onTextBoxUpdate: ((TextBox) -> Void)?
    ) {
        self._textBox = State(initialValue: textBox)
        self.timelineWidth = timelineWidth
        self.duration = duration
        self.offset = offset
        self.externalDragOffset = externalDragOffset
        self.externalZoomOffset = externalZoomOffset
        self.isSelected = isSelected
        self.onTap = onTap
        self.onSeek = onSeek
        self.bounds = bounds
        self.isChange = isChange
        self.onTextBoxUpdate = onTextBoxUpdate
    }
    
    var body: some View {
        GeometryReader { geometry in
            let textBoxStart = textBox.timeRange.lowerBound
            let textBoxEnd = textBox.timeRange.upperBound
            let pixelsPerSecond = (timelineWidth / duration)
            let boxDuration = textBoxEnd - textBoxStart
            let boxWidth = boxDuration * pixelsPerSecond
            let wordPosition = textBoxStart * pixelsPerSecond
            
            // wordPosition is the position of the word within the timeline
            // offset is to move it as the slider moves
            // boxWidth/2 is to shift it left of center
            let absoluteTextPosition = (wordPosition - abs(offset.wrappedValue)) + boxWidth/2

            // TODO: fix this, especially if a lot of text boxes are present and performance is an issue
            // let isVisible = wordPosition > 0
            let isVisible = true
            
            if isVisible {
                ZStack {
                    // Time tooltip (shown during drag)
                    if showTimeTooltip {
                        VStack {
                            Text(String(format: "%.2fs", currentDragTime))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.black.opacity(0.8))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                        .position(x: absoluteTextPosition, y: geometry.size.height / 2 - 40)
                        .zIndex(TimelineZIndex.tooltip)
                    }
                    
                    // Main text box
                    Text(textBox.text)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .frame(width: boxWidth, height: 50, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    isSelected ? 
                                        AnyShapeStyle(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.6, green: 0.3, blue: 0.8, opacity: 0.9),  // Light purple
                                                    Color(red: 0.5, green: 0.2, blue: 0.7, opacity: 0.9)   // Darker purple
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        ) :
                                        AnyShapeStyle(Color.gray.opacity(0.7))
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                    isSelected ? 
                                        AnyShapeStyle(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.8),
                                                    Color.white.opacity(0.4)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        ) :
                                        AnyShapeStyle(Color.clear),
                                    lineWidth: 1.5
                                )
                        )
                        .position(x: absoluteTextPosition, y: geometry.size.height / 2)
                        .opacity(0.9)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .zIndex(isSelected ? TimelineZIndex.selectedTextBox : TimelineZIndex.nonSelectedTextBox)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    // This will be called for any drag, even very small ones
                                    let distance = sqrt(value.translation.width * value.translation.width + value.translation.height * value.translation.height)
                                    
                                    // If this is a significant drag and we're not zooming
                                    if distance >= 5 && !isZooming {
                                        if isSelected {
                                            // Handle text box timeline movement for selected text boxes
                                            if !isDraggingTextBox {
                                                isDraggingTextBox = true
                                                dragStartTime = textBox.timeRange.lowerBound
                                                originalTimeRange = textBox.timeRange
                                                showTimeTooltip = true
                                                print("🔄 Text box drag started - original start: \(dragStartTime)")
                                            }
                                            
                                            // Calculate new position based on drag
                                            let pixelsPerSecond = (timelineWidth / duration)
                                            let timeChange = value.translation.width / pixelsPerSecond
                                            let boxDuration = textBox.timeRange.upperBound - textBox.timeRange.lowerBound
                                            let newStartTime = max(0, dragStartTime + timeChange)
                                            let newEndTime = min(duration, newStartTime + boxDuration)
                                            
                                            // Update tooltip time
                                            currentDragTime = newStartTime
                                            
                                            print("🔄 Text box drag - new start time: \(newStartTime), new end time: \(newEndTime)")
                                            
                                            // Update the text box time range
                                            textBox.timeRange = newStartTime...newEndTime
                                            
                                        } else {
                                            // Handle timeline scrolling for non-selected text boxes
                                            isDragging = true
                                            if let externalDragBinding = externalDragOffset {
                                                externalDragBinding.wrappedValue = value.translation.width
                                            }
                                        }
                                    }
                                }
                                .onEnded { value in
                                    let dragDistance = sqrt(value.translation.width * value.translation.width + value.translation.height * value.translation.height)
                                    
                                    if isDraggingTextBox {
                                        // Text box drag ended
                                        isDraggingTextBox = false
                                        showTimeTooltip = false
                                        print("🔄 Text box drag ended")
                                        
                                        // Update the video player text boxes with the new time range
                                        onTextBoxUpdate?(textBox)
                                        print("🔄 Text box drag - calling onTextBoxUpdate with time range: \(textBox.timeRange)")
                                        
                                    } else if dragDistance < 5 && !isZooming {
                                        // Small drag - treat as tap
                                        onTap()
                                        onSeek(textBox.timeRange.lowerBound)
                                        // Update timeline position immediately
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            // Note: This will need to be updated when we integrate with the new RulerView drag logic
                                            // TimelineSliderUtils.setOffset(
                                            //     value: textBox.timeRange.lowerBound,
                                            //     offset: offset,
                                            //     isChange: isChange,
                                            //     bounds: bounds,
                                            //     timelineWidth: timelineWidth
                                            // )
                                        }
                                    } else if isDragging {
                                        // Timeline scroll ended
                                        // Pass the drag translation to the external drag offset
                                        if let externalDragBinding = externalDragOffset {
                                            externalDragBinding.wrappedValue = value.translation.width
                                        }
                                    }
                                    
                                    isDragging = false
                                    
                                    // Reset external drag offset after a short delay to let RulerView process the final position
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        if let externalDragBinding = externalDragOffset {
                                            externalDragBinding.wrappedValue = 0
                                        }
                                    }
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { scale in
                                    isZooming = true
                                    let newZoomLevel = lastZoomLevel * scale
                                    zoomLevel = min(maxZoomLevel, max(minZoomLevel, newZoomLevel))
                                    
                                    // Pass zoom information to RulerView through external zoom offset
                                    if let externalZoomBinding = externalZoomOffset {
                                        // Use a positive value for zoom level
                                        let zoomIndicator = zoomLevel * 1000 // Scale up for precision
                                        externalZoomBinding.wrappedValue = zoomIndicator
                                    }
                                }
                                .onEnded { scale in
                                    isZooming = false
                                    lastZoomLevel = zoomLevel
                                    
                                    // Reset the external drag offset after zoom ends
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        if let externalDragBinding = externalZoomOffset {
                                            externalDragBinding.wrappedValue = 0
                                        }
                                    }
                                }
                        )
                    
                    // Left edge handle (only show for selected text boxes)
                    if isSelected {
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.6, green: 0.3, blue: 0.8),  // Light purple
                                                Color(red: 0.5, green: 0.2, blue: 0.7)   // Darker purple
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                            )
                            .position(x: (absoluteTextPosition - boxWidth/2) + 2, y: geometry.size.height / 2 + 35)
                            .zIndex(TimelineZIndex.dragHandles)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        print("🔄 Left edge drag - translation: \(value.translation.width)")
                                        
                                        if !isDraggingLeftEdge {
                                            isDraggingLeftEdge = true
                                            dragStartTime = textBox.timeRange.lowerBound
                                            originalTimeRange = textBox.timeRange
                                            showTimeTooltip = true
                                            print("🔄 Left edge drag started - original start: \(dragStartTime)")
                                        }
                                        
                                        // Calculate new start time based on drag
                                        let pixelsPerSecond = (timelineWidth / duration)
                                        let timeChange = value.translation.width / pixelsPerSecond
                                        let newStartTime = max(0, dragStartTime + timeChange)
                                        
                                        // Ensure minimum duration (0.5 seconds)
                                        let minDuration: Double = 0.5
                                        let maxStartTime = textBox.timeRange.upperBound - minDuration
                                        let clampedStartTime = min(newStartTime, maxStartTime)
                                        
                                        // Update tooltip time
                                        currentDragTime = clampedStartTime
                                        
                                        print("🔄 Left edge drag - new start time: \(clampedStartTime), original: \(textBox.timeRange.lowerBound)")
                                        
                                        // Update the text box time range
                                        textBox.timeRange = clampedStartTime...textBox.timeRange.upperBound
                                        
                                        print("🔄 Left edge drag - updated time range: \(textBox.timeRange)")
                                    }
                                    .onEnded { value in
                                        isDraggingLeftEdge = false
                                        showTimeTooltip = false
                                        print("🔄 Left edge drag ended")
                                        
                                        // Update the video player text boxes with the new time range
                                        onTextBoxUpdate?(textBox)
                                        print("🔄 Left edge drag - calling onTextBoxUpdate with time range: \(textBox.timeRange)")
                                    }
                            )
                    }
                    
                    // Right edge handle (only show for selected text boxes)
                    if isSelected {
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.6, green: 0.3, blue: 0.8),  // Light purple
                                                Color(red: 0.5, green: 0.2, blue: 0.7)   // Darker purple
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                            )
                            .position(x: (absoluteTextPosition + boxWidth/2) - 2, y: geometry.size.height / 2 + 35)
                            .zIndex(TimelineZIndex.dragHandles)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        print("🔄 Right edge drag - translation: \(value.translation.width)")
                                        
                                        if !isDraggingRightEdge {
                                            isDraggingRightEdge = true
                                            dragStartTime = textBox.timeRange.upperBound
                                            originalTimeRange = textBox.timeRange
                                            showTimeTooltip = true
                                            print("🔄 Right edge drag started - original end: \(dragStartTime)")
                                        }
                                        
                                        // Calculate new end time based on drag
                                        let pixelsPerSecond = (timelineWidth / duration)
                                        let timeChange = value.translation.width / pixelsPerSecond
                                        let newEndTime = min(duration, dragStartTime + timeChange)
                                        
                                        // Ensure minimum duration (0.5 seconds)
                                        let minDuration: Double = 0.5
                                        let minEndTime = textBox.timeRange.lowerBound + minDuration
                                        let clampedEndTime = max(newEndTime, minEndTime)
                                        
                                        // Update tooltip time
                                        currentDragTime = clampedEndTime
                                        
                                        print("🔄 Right edge drag - new end time: \(clampedEndTime), original: \(textBox.timeRange.upperBound)")
                                        
                                        // Update the text box time range
                                        textBox.timeRange = textBox.timeRange.lowerBound...clampedEndTime
                                        
                                        print("🔄 Right edge drag - updated time range: \(textBox.timeRange)")
                                    }
                                    .onEnded { value in
                                        isDraggingRightEdge = false
                                        showTimeTooltip = false
                                        print("🔄 Right edge drag ended")
                                        
                                        // Update the video player text boxes with the new time range
                                        onTextBoxUpdate?(textBox)
                                        print("🔄 Right edge drag - calling onTextBoxUpdate with time range: \(textBox.timeRange)")
                                    }
                            )
                    }
                }
                .onAppear {
                    // Debug positioning
                    print("📝 TimelineTextBox - Text: '\(textBox.text)', Position: \(absoluteTextPosition), BoxWidth: \(boxWidth), WordPosition: \(wordPosition), Offset: \(offset.wrappedValue)")
                }
            }
        }
    }
}