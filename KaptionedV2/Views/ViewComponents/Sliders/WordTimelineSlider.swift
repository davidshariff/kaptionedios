import SwiftUI

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
        onSeek: @escaping (Double) -> Void
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
            isChange: false
        )
    }
    
    private var textBoxViews: some View {
        ForEach(textBoxes, id: \.id) { (textBox: TextBox) in
            createTextBoxView(textBox)
        }
    }
    
    var body: some View {
        ZStack {

            backgroundView()

            textBoxViews
            .border(.red, width: 1)
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
    let textBox: TextBox
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
    
    // Zoom state for pinch gesture
    @State private var zoomLevel: CGFloat = 1.0
    @State private var lastZoomLevel: CGFloat = 1.0
    @State private var isZooming: Bool = false
    @State private var isDragging: Bool = false
    @State private var gestureStartTime: Date = Date()
    
    // Zoom constraints
    let minZoomLevel: CGFloat = 1.0
    let maxZoomLevel: CGFloat = 5.0
    
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
                Text(textBox.text)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(width: boxWidth, height: 50, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.7))
                    )
                    .border(isSelected ? .white : .clear, width: 1)
                    .position(x: absoluteTextPosition, y: geometry.size.height / 2)
                    .opacity(0.9)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // This will be called for any drag, even very small ones
                                let distance = sqrt(value.translation.width * value.translation.width + value.translation.height * value.translation.height)
                                
                                // If this is a significant drag and we're not zooming, pass it to the RulerView immediately
                                if distance >= 5 && !isZooming {
                                    isDragging = true
                                    if let externalDragBinding = externalDragOffset {
                                        externalDragBinding.wrappedValue = value.translation.width
                                    }
                                }
                            }
                            .onEnded { value in
                                let dragDistance = sqrt(value.translation.width * value.translation.width + value.translation.height * value.translation.height)
                                
                                // If drag distance is very small and we're not zooming, treat as tap
                                if dragDistance < 5 && !isZooming {
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
                    .onAppear {
                        // Debug positioning
                        print("📝 TimelineTextBox - Text: '\(textBox.text)', Position: \(absoluteTextPosition), BoxWidth: \(boxWidth), WordPosition: \(wordPosition), Offset: \(offset.wrappedValue)")
                    }
            }
        }
    }
}