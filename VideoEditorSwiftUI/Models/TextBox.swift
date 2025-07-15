//
//  TextBox.swift
//  VideoEditorSwiftUI
//
//  Created by Bogdan Zykov on 28.04.2023.
//

import Foundation
import SwiftUI


struct TextBox: Identifiable{
    
    var id: UUID = UUID()
    var text: String = ""
    var fontSize: CGFloat = 20
    var lastFontSize: CGFloat = .zero
    var bgColor: Color = .white
    var fontColor: Color = .black
    var strokeColor: Color = .clear
    var strokeWidth: CGFloat = 0
    var timeRange: ClosedRange<Double> = 0...3
    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    var backgroundPadding: CGFloat = 8
    var cornerRadius: CGFloat = 0
    // Shadow properties
    var shadowColor: Color = .black
    var shadowRadius: CGFloat = 0
    var shadowX: CGFloat = 0
    var shadowY: CGFloat = 0
    var shadowOpacity: Double = 0.5
    
    init(text: String = "", fontSize: CGFloat = 20, lastFontSize: CGFloat = .zero, bgColor: Color = .white, fontColor: Color = .black, strokeColor: Color = .clear, strokeWidth: CGFloat = 0, timeRange: ClosedRange<Double> = 0...3, offset: CGSize = .zero, lastOffset: CGSize = .zero, backgroundPadding: CGFloat = 8, cornerRadius: CGFloat = 0, shadowColor: Color = .black, shadowRadius: CGFloat = 0, shadowX: CGFloat = 0, shadowY: CGFloat = 0, shadowOpacity: Double = 0.5) {
        self.text = text
        self.fontSize = fontSize
        self.lastFontSize = lastFontSize
        self.bgColor = bgColor
        self.fontColor = fontColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.timeRange = timeRange
        self.offset = offset
        self.lastOffset = lastOffset
        self.backgroundPadding = backgroundPadding
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowX = shadowX
        self.shadowY = shadowY
        self.shadowOpacity = shadowOpacity
    }
    
    
}

extension TextBox: Equatable{}

struct SubtitleStyle: Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var fontSize: CGFloat
    var bgColor: Color
    var fontColor: Color
    var strokeColor: Color
    var strokeWidth: CGFloat
    var backgroundPadding: CGFloat
    var cornerRadius: CGFloat
    var shadowColor: Color
    var shadowRadius: CGFloat
    var shadowX: CGFloat
    var shadowY: CGFloat
    var shadowOpacity: Double
    
    // Optionally, provide a method to apply this style to a TextBox
    func apply(to textBox: TextBox) -> TextBox {
        var box = textBox
        box.fontSize = fontSize
        box.bgColor = bgColor
        box.fontColor = fontColor
        box.strokeColor = strokeColor
        box.strokeWidth = strokeWidth
        box.backgroundPadding = backgroundPadding
        box.cornerRadius = cornerRadius
        box.shadowColor = shadowColor
        box.shadowRadius = shadowRadius
        box.shadowX = shadowX
        box.shadowY = shadowY
        box.shadowOpacity = shadowOpacity
        return box
    }

    static let allPresets: [SubtitleStyle] = [
        SubtitleStyle(name: "Classic Yellow", fontSize: 32, bgColor: .clear, fontColor: .yellow, strokeColor: .black, strokeWidth: 2, backgroundPadding: 8, cornerRadius: 8, shadowColor: .black, shadowRadius: 6, shadowX: 0, shadowY: 2, shadowOpacity: 0.7),
        SubtitleStyle(name: "Modern White", fontSize: 32, bgColor: .clear, fontColor: .white, strokeColor: .black, strokeWidth: 2, backgroundPadding: 8, cornerRadius: 8, shadowColor: .black, shadowRadius: 6, shadowX: 0, shadowY: 2, shadowOpacity: 0.7),
        SubtitleStyle(name: "Bold Black", fontSize: 32, bgColor: .clear, fontColor: .black, strokeColor: .white, strokeWidth: 2, backgroundPadding: 8, cornerRadius: 8, shadowColor: .white, shadowRadius: 6, shadowX: 0, shadowY: 2, shadowOpacity: 0.7),
        SubtitleStyle(name: "Shadowed", fontSize: 32, bgColor: .clear, fontColor: .white, strokeColor: .clear, strokeWidth: 0, backgroundPadding: 8, cornerRadius: 8, shadowColor: .black, shadowRadius: 8, shadowX: 2, shadowY: 2, shadowOpacity: 0.8),
        SubtitleStyle(name: "Large Font", fontSize: 40, bgColor: .clear, fontColor: .white, strokeColor: .black, strokeWidth: 2, backgroundPadding: 8, cornerRadius: 8, shadowColor: .black, shadowRadius: 6, shadowX: 0, shadowY: 2, shadowOpacity: 0.7),
        SubtitleStyle(name: "Outlined", fontSize: 32, bgColor: .clear, fontColor: .white, strokeColor: .black, strokeWidth: 4, backgroundPadding: 8, cornerRadius: 8, shadowColor: .clear, shadowRadius: 0, shadowX: 0, shadowY: 0, shadowOpacity: 0),
        SubtitleStyle(name: "Minimalist", fontSize: 28, bgColor: .clear, fontColor: .white, strokeColor: .clear, strokeWidth: 0, backgroundPadding: 4, cornerRadius: 4, shadowColor: .clear, shadowRadius: 0, shadowX: 0, shadowY: 0, shadowOpacity: 0),
        SubtitleStyle(name: "Comic Sans", fontSize: 32, bgColor: .clear, fontColor: .yellow, strokeColor: .blue, strokeWidth: 2, backgroundPadding: 8, cornerRadius: 8, shadowColor: .blue, shadowRadius: 6, shadowX: 2, shadowY: 2, shadowOpacity: 0.7),
        SubtitleStyle(name: "Elegant Serif", fontSize: 32, bgColor: .clear, fontColor: .white, strokeColor: .black, strokeWidth: 1, backgroundPadding: 8, cornerRadius: 8, shadowColor: .gray, shadowRadius: 4, shadowX: 1, shadowY: 1, shadowOpacity: 0.5),
        SubtitleStyle(name: "Retro", fontSize: 32, bgColor: .clear, fontColor: .orange, strokeColor: .brown, strokeWidth: 2, backgroundPadding: 8, cornerRadius: 8, shadowColor: .brown, shadowRadius: 6, shadowX: 2, shadowY: 2, shadowOpacity: 0.7)
    ]
}
