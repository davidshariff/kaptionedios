//
//  PlayheadView.swift
//  VideoEditorSwiftUI
//
//  Created by Assistant on 2024.
//

import SwiftUI

/// A reusable playhead component for timeline sliders
/// 
/// This view provides a consistent playhead appearance across all timeline sliders.
/// It can be customized with different widths, colors, and shadow properties.
/// 
/// ## Usage Examples:
/// 
/// ```swift
/// // Basic usage with default settings
/// PlayheadView(height: 60)
/// 
/// // Customized playhead
/// PlayheadView(
///     height: 80,
///     width: 3,
///     color: .red,
///     shadowRadius: 5,
///     shadowColor: .black.opacity(0.5)
/// )
/// ```
struct PlayheadView: View {
    let height: CGFloat
    let width: CGFloat
    let color: Color
    let shadowRadius: CGFloat
    let shadowColor: Color
    
    init(
        height: CGFloat,
        width: CGFloat = 2,
        color: Color = .white,
        shadowRadius: CGFloat = 3,
        shadowColor: Color = .black.opacity(0.3)
    ) {
        self.height = height
        self.width = width
        self.color = color
        self.shadowRadius = shadowRadius
        self.shadowColor = shadowColor
    }
    
    var body: some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: height)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 0)
    }
}

struct PlayheadView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Playhead Examples")
                .font(.headline)
                .foregroundColor(.white)
            
            // Default playhead
            PlayheadView(height: 60)
                .frame(height: 80)
                .background(Color.black)
            
            // Custom playhead
            PlayheadView(
                height: 80,
                width: 4,
                color: .red,
                shadowRadius: 5,
                shadowColor: .black.opacity(0.5)
            )
            .frame(height: 100)
            .background(Color.black)
            
            // Thin playhead
            PlayheadView(
                height: 40,
                width: 1,
                color: .yellow,
                shadowRadius: 2
            )
            .frame(height: 60)
            .background(Color.black)
        }
        .padding()
        .background(Color.gray)
    }
} 