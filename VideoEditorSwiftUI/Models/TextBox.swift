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


extension TextBox{
    static let texts: [TextBox] =
    
    [
    
        .init(text: "Test1", fontSize: 38, bgColor: .red, fontColor: .white, timeRange: 0...2),
        .init(text: "Test2", fontSize: 38, bgColor: .secondary, fontColor: .white, timeRange: 2...6),
        .init(text: "Test3", fontSize: 38, bgColor: .black, fontColor: .red, timeRange: 3...6),
        .init(text: "Test4", fontSize: 38, bgColor: .black, fontColor: .blue, timeRange: 5...6),
        .init(text: "Test5", fontSize: 38, bgColor: .black, fontColor: .white, timeRange: 1...6),
    ]
    
    static let simple = TextBox(text: "Test", fontSize: 38, bgColor: .black, fontColor: .white, timeRange: 1...3)
}
