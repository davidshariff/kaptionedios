//
//  InteractiveVerticalScrubber.swift
//  VideoEditorSwiftUI
//
//  Created by Assistant on 2024.
//

import SwiftUI

struct InteractiveVerticalScrubberAbsolute: View {
    let textBoxes: [TextBox]
    let selectedTextBox: TextBox?
    let totalDuration: Double
    let timelineScale: CGFloat
    let currentTime: Double
    let onTimeChanged: (Double) -> Void

    var body: some View {
        ZStack(alignment: .top) {
            // Timeline track
            Rectangle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 16)
                .cornerRadius(8)
                .position(x: 24, y: (CGFloat(totalDuration) * timelineScale) / 2)
                .frame(height: CGFloat(totalDuration) * timelineScale)

            // Subtitle segments
            ForEach(textBoxes) { textBox in
                let startY = CGFloat(textBox.timeRange.lowerBound) * timelineScale
                let endY = CGFloat(textBox.timeRange.upperBound) * timelineScale
                let height = max(endY - startY, 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(selectedTextBox == textBox ? Color.blue : Color.orange.opacity(0.8))
                    .frame(width: selectedTextBox == textBox ? 16 : 12, height: height)
                    .position(x: 24, y: startY + height / 2)
                    .shadow(color: selectedTextBox == textBox ? Color.blue.opacity(0.5) : Color.orange.opacity(0.3), radius: 3)
            }

            // Interactive overlay for touch/drag
            Rectangle()
                .fill(Color.clear)
                .frame(width: 48, height: CGFloat(totalDuration) * timelineScale)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let y = value.location.y
                            let time = min(max(0, Double(y / timelineScale)), totalDuration)
                            onTimeChanged(time)
                        }
                )
        }
        .frame(width: 48, height: CGFloat(totalDuration) * timelineScale)
    }
}

struct InteractiveVerticalScrubberAbsolute_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveVerticalScrubberAbsolute(
            textBoxes: [
                TextBox(text: "Hello", timeRange: 0...3),
                TextBox(text: "World", timeRange: 5...8)
            ],
            selectedTextBox: nil,
            totalDuration: 10,
            timelineScale: 40,
            currentTime: 2.5,
            onTimeChanged: { time in
                print("Time changed to: \(time)")
            }
        )
        .frame(height: 300)
        .padding()
    }
} 